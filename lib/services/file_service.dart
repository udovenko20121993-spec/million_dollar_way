import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ibkr_parser.dart';
import 'nbu_exchange_rate_service.dart';

class FileService {
  Future<Map<String, dynamic>> parseAndMergeReport(
    String userId,
    String reportId,
    PlatformFile platformFile,
    String customName,
  ) async {
    try {
      String xmlContent;

      // 1. ЧИТАННЯ ФАЙЛУ
      if (platformFile.bytes != null) {
        xmlContent = utf8.decode(platformFile.bytes!);
      } else if (platformFile.path != null) {
        xmlContent = await File(platformFile.path!).readAsString();
      } else {
        throw "Помилка: файл пустий";
      }

      // 2. ОЧИЩЕННЯ XML
      if (xmlContent.isNotEmpty && xmlContent.codeUnitAt(0) == 0xFEFF) {
        xmlContent = xmlContent.substring(1);
      }
      xmlContent = xmlContent.replaceAll(RegExp(r'<\?xml.*?\?>'), '');
      xmlContent = xmlContent.replaceAll(
        RegExp(r' (xmlns|xsi)(:[\w-]+)?="[^"]*"'),
        '',
      );
      xmlContent = xmlContent.replaceAll(
        RegExp(r" (xmlns|xsi)(:[\w-]+)?='[^']*'"),
        '',
      );
      xmlContent = xmlContent.replaceAll(RegExp(r'<([\w-]+):'), '<');
      xmlContent = xmlContent.replaceAll(RegExp(r'</([\w-]+):'), '</');

      final document = XmlDocument.parse(xmlContent);
      final flexStatement = document
          .findAllElements('FlexStatement')
          .firstOrNull;

      if (flexStatement == null) {
        throw "Невірний формат XML (немає FlexStatement)";
      }

      // 3. ОТРИМАННЯ СТАРИХ ДАНИХ
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reports')
          .doc(reportId);
      final docSnapshot = await docRef.get();
      final currentData = docSnapshot.exists ? (docSnapshot.data() ?? {}) : {};

      List<Map<String, dynamic>> existingTrades =
          List<Map<String, dynamic>>.from(currentData['trades'] ?? []);
      List<Map<String, dynamic>> existingDividends =
          List<Map<String, dynamic>>.from(currentData['dividends'] ?? []);
      List<Map<String, dynamic>> existingCashTrans =
          List<Map<String, dynamic>>.from(
            currentData['cashTransactions'] ?? [],
          );

      // ЗМІНА 1: Читаємо як dynamic, щоб підтримувати і старі String, і нові Map
      List<dynamic> existingSources = List<dynamic>.from(
        currentData['sourceFiles'] ?? [],
      );

      // 4. ПАРСИНГ НОВИХ ДАНИХ
      List<Map<String, dynamic>> newTrades = [];
      List<Map<String, dynamic>> newDividends = [];
      List<Map<String, dynamic>> newCashTrans = [];

      // А) Грошові транзакції (ДЕПОЗИТИ З КОНВЕРТАЦІЄЮ)
      final allCashTransactions = flexStatement.findAllElements(
        'CashTransaction',
      );
      for (var tx in allCashTransactions) {
        String type = tx.getAttribute('type') ?? '';

        // 1. Беремо суму в оригінальній валюті
        double amountOriginal =
            double.tryParse(tx.getAttribute('amount') ?? "0") ?? 0;

        // 2. Шукаємо курс конвертації до USD (fxRateToBase)
        double fxRate =
            double.tryParse(tx.getAttribute('fxRateToBase') ?? "1") ?? 1;

        // 3. Конвертуємо в долари
        double amountUSD = amountOriginal * fxRate;

        String symbol = tx.getAttribute('symbol') ?? '';
        String date = tx.getAttribute('dateTime') ?? '';
        String desc = tx.getAttribute('description') ?? '';
        String transId = tx.getAttribute('transactionID') ?? '';
        String currency = tx.getAttribute('currency') ?? 'USD';

        final typeLower = type.toLowerCase();
        final descLower = desc.toLowerCase();
        final isDividendCashTx =
            type.startsWith('Dividend') || type == 'PaymentInLieuOfDividends';
        final isWithholdingTax =
            typeLower.contains('withholding') ||
            descLower.contains('withholding') ||
            (typeLower.contains('tax') &&
                (descLower.contains('dividend') ||
                    descLower.contains('withholding')));

        Map<String, dynamic> rawTx = {
          'date': date,
          'type': type,
          'amount': amountUSD, // Зберігаємо в USD
          'originalAmount': amountOriginal,
          'currency': currency,
          'symbol': symbol,
          'description': desc,
          'transactionID': transId,
        };

        // Логіка фільтрації: Депозити, Виведення, Трансфери
        bool isExternalFlow =
            type.startsWith('Deposit') ||
            type.startsWith('Withdrawal') ||
            (type.contains('Transfer') && !desc.contains('Internal')) ||
            (type == 'Cash' && amountUSD.abs() > 0.01);

        if (isExternalFlow) {
          newCashTrans.add(rawTx);
        } else if (isDividendCashTx || isWithholdingTax) {
          newDividends.add({
            'date': date,
            'symbol': symbol.isEmpty ? 'DIV' : symbol,
            'amount': amountUSD,
            'description': desc.isEmpty
                ? (isWithholdingTax ? 'Withholding Tax' : 'Dividend')
                : desc,
          });
        }
      }

      // Б) Дивіденди (Accruals)
      final allAccruals = flexStatement.findAllElements(
        'ChangeInDividendAccrual',
      );
      for (var div in allAccruals) {
        if (div.getAttribute('payDate') != null) {
          double amount =
              double.tryParse(
                div.getAttribute('grossAmount') ??
                    div.getAttribute('netAmount') ??
                    "0",
              ) ??
              0;
          if (amount != 0) {
            newDividends.add({
              'date': div.getAttribute('payDate') ?? '',
              'symbol': div.getAttribute('symbol') ?? 'DIV',
              'amount': amount,
              'description':
                  div.getAttribute('description') ?? 'Dividend Accrual',
            });
          }
        }
      }

      // В) Угоди (Trades) + КОМІСІЇ
      final tradeParser = IBKRRarser();
      final nbuService = NbuExchangeRateService();
      final baseCurrency =
          flexStatement.getAttribute('baseCurrency') ??
          flexStatement.getAttribute('currency') ??
          'USD';
      final allTrades = flexStatement.findAllElements('Trade');

      print('Початок розрахунку (NBU rates + trades)');

      String rateKey(String currency, DateTime date) {
        final d = DateTime(date.year, date.month, date.day);
        return '${currency.toUpperCase()}_${d.toIso8601String()}';
      }

      final rateCache = <String, NbuRateResult?>{};
      final pendingRequests = <Future<void>>[];
      var totalPlanned = 0;
      var completed = 0;

      Future<void> prefetchRate(String currency, DateTime date) async {
        final key = rateKey(currency, date);
        if (rateCache.containsKey(key)) return;
        totalPlanned += 1;
        try {
          final r = await nbuService.tryGetRateToUah(
            currency: currency,
            date: date,
          );
          rateCache[key] = r;
        } catch (e) {
          rateCache[key] = null;
        } finally {
          completed += 1;
          if (completed == totalPlanned || completed % 25 == 0) {
            // Progress logging removed for production
          }
        }
      }

      DateTime? parseTradeDate(String tradeDateStr) {
        if (tradeDateStr.isEmpty) return null;
        return DateTime.tryParse(tradeDateStr) ??
            DateTime.tryParse(tradeDateStr.split(' ').first);
      }

      final tradeInfos = <Map<String, dynamic>>[];

      for (var trade in allTrades) {
        if (trade.getAttribute('assetCategory') == 'Total' ||
            trade.getAttribute('symbol') == null) {
          continue;
        }

        final parsed = tradeParser.parseTradeNode(trade);

        final tradeDateStr = trade.getAttribute('dateTime') ?? '';
        final tradeDate = parseTradeDate(tradeDateStr);

        double comm =
            double.tryParse(trade.getAttribute('ibCommission') ?? "0") ?? 0;

        final priceCurrency =
            parsed?.price.currency ?? trade.getAttribute('currency') ?? 'USD';
        final commissionCurrency =
            parsed?.commission.currency ??
            trade.getAttribute('ibCommissionCurrency') ??
            trade.getAttribute('currency') ??
            'USD';

        final fxRateToBase = double.tryParse(
          trade.getAttribute('fxRateToBase') ?? '',
        );

        tradeInfos.add({
          'trade': trade,
          'parsed': parsed,
          'tradeDateStr': tradeDateStr,
          'tradeDate': tradeDate,
          'comm': comm,
          'priceCurrency': priceCurrency,
          'commissionCurrency': commissionCurrency,
          'fxRateToBase': fxRateToBase,
        });

        if (tradeDate != null) {
          pendingRequests.add(prefetchRate(priceCurrency, tradeDate));
          pendingRequests.add(prefetchRate(commissionCurrency, tradeDate));
          if (fxRateToBase != null && fxRateToBase != 0) {
            pendingRequests.add(prefetchRate(baseCurrency, tradeDate));
          }
        }
      }

      try {
        await Future.wait(pendingRequests);
      } catch (e) {
        rethrow;
      }

      for (final info in tradeInfos) {
        final trade = info['trade'] as XmlElement;
        final tradeDateStr = info['tradeDateStr'] as String;
        final tradeDate = info['tradeDate'] as DateTime?;
        final comm = info['comm'] as double;
        final priceCurrency = info['priceCurrency'] as String;
        final commissionCurrency = info['commissionCurrency'] as String;
        final fxRateToBase = info['fxRateToBase'] as double?;

        NbuRateResult? priceRate;
        NbuRateResult? commissionRate;
        if (tradeDate != null) {
          priceRate = rateCache[rateKey(priceCurrency, tradeDate)];
          commissionRate = rateCache[rateKey(commissionCurrency, tradeDate)];

          if (priceRate == null && fxRateToBase != null && fxRateToBase != 0) {
            final baseRate = rateCache[rateKey(baseCurrency, tradeDate)];
            if (baseRate != null) {
              final computed = baseRate.rateToUah * fxRateToBase;
              priceRate = NbuRateResult(
                requestedCurrency: priceCurrency,
                nbuCurrency: baseCurrency,
                requestedDate: DateTime(
                  tradeDate.year,
                  tradeDate.month,
                  tradeDate.day,
                ),
                rateDate: baseRate.rateDate,
                rateToUah: computed,
              );
            } else {
              print(
                'NBU rate warning: cannot compute cross-rate for $priceCurrency because base currency $baseCurrency rate is unavailable',
              );
            }
          }

          if (commissionRate == null &&
              commissionCurrency == priceCurrency &&
              priceRate != null) {
            commissionRate = priceRate;
          }
        } else {
          print(
            "NBU rate warning: cannot parse trade date \"$tradeDateStr\" for ${trade.getAttribute('symbol')}",
          );
        }

        final priceValue =
            double.tryParse(trade.getAttribute('tradePrice') ?? "0") ?? 0;

        final double? priceUah = priceRate != null
            ? nbuService.roundUah(priceValue * priceRate.rateToUah)
            : null;
        final double? commissionUah = commissionRate != null
            ? nbuService.roundUah(comm * commissionRate.rateToUah)
            : null;

        newTrades.add({
          'date': trade.getAttribute('dateTime') ?? '',
          'symbol': trade.getAttribute('symbol') ?? '',
          'action': trade.getAttribute('buySell') ?? '',
          'quantity':
              double.tryParse(trade.getAttribute('quantity') ?? "0") ?? 0,
          'price': priceValue,
          'priceCurrency': priceCurrency,
          'priceRateToUah': priceRate?.rateToUah,
          'priceRateDate': priceRate?.rateDate.toIso8601String(),
          'priceUah': priceUah,
          'cost': double.tryParse(trade.getAttribute('cost') ?? "0") ?? 0,
          'commission': comm,
          'commissionCurrency': commissionCurrency,
          'commissionRateToUah': commissionRate?.rateToUah,
          'commissionRateDate': commissionRate?.rateDate.toIso8601String(),
          'commissionUah': commissionUah,
        });
      }

      print('Розрахунок FIFO завершено');

      nbuService.dispose();

      // Г) Баланс (NAV)
      double newNetValue = 0;
      final navElements = flexStatement.findAllElements(
        'EquitySummaryByReportDateInBase',
      );
      for (var nav in navElements) {
        String? val = nav.getAttribute('total') ?? nav.getAttribute('cash');
        if (val != null) {
          double parsed = double.tryParse(val) ?? 0;
          if (parsed != 0) newNetValue = parsed;
        }
      }

      // Д) Кеш
      double newCashBalance = 0;
      final cashReports = flexStatement.findAllElements('CashReportCurrency');
      for (var el in cashReports) {
        String curr = el.getAttribute('currency') ?? '';
        if (curr == 'BASE') {
          newCashBalance =
              double.tryParse(
                el.getAttribute('endingSettled') ??
                    el.getAttribute('endingCash') ??
                    "0",
              ) ??
              0;
          break;
        }
      }
      if (newCashBalance == 0) {
        for (var el in cashReports) {
          if (el.getAttribute('currency') == 'USD') {
            newCashBalance =
                double.tryParse(
                  el.getAttribute('endingSettled') ??
                      el.getAttribute('endingCash') ??
                      "0",
                ) ??
                0;
            break;
          }
        }
      }

      // Е) Активи
      List<Map<String, dynamic>> newAssets = [];
      final allPositions = flexStatement.findAllElements('OpenPosition');
      for (var pos in allPositions) {
        if (pos.getAttribute('symbol') == null) continue;
        newAssets.add({
          'symbol': pos.getAttribute('symbol') ?? 'Unknown',
          'quantity': double.tryParse(pos.getAttribute('position') ?? "0") ?? 0,
          'value':
              double.tryParse(pos.getAttribute('positionValue') ?? "0") ?? 0,
          'change':
              double.tryParse(pos.getAttribute('unrealizedPnl') ?? "0") ?? 0,
          'name': pos.getAttribute('description') ?? '',
        });
      }

      // --- 5. ЗЛИТТЯ ---
      existingTrades.addAll(newTrades);
      final uniqueTrades = _removeDuplicates(
        existingTrades,
        (item) =>
            "${item['date']}_${item['symbol']}_${item['action']}_${item['quantity']}_${item['price']}_${item['priceCurrency']}_${item['commission']}_${item['commissionCurrency']}",
      );

      existingDividends.addAll(newDividends);
      final uniqueDividends = _removeDuplicates(
        existingDividends,
        (item) => "${item['date']}_${item['symbol']}_${item['amount']}",
      );

      existingCashTrans.addAll(newCashTrans);
      final uniqueCashTrans = _removeDuplicates(existingCashTrans, (item) {
        if (item['transactionID'] != null &&
            item['transactionID'].toString().isNotEmpty) {
          return item['transactionID'].toString();
        }
        return "${item['date']}_${item['type']}_${item['amount']}_${item['currency']}";
      });

      // --- 6. ПЕРЕРАХУНОК ---
      double totalDividends = uniqueDividends.fold(
        0,
        (sum, item) => sum + (item['amount'] as double),
      );

      double totalCommissions = uniqueTrades.fold(
        0,
        (sum, item) => sum + (item['commission'] as double? ?? 0),
      );

      double calculatedDeposits = 0;
      double calculatedWithdrawals = 0;

      for (var tx in uniqueCashTrans) {
        double amount = (tx['amount'] as num).toDouble();
        if (amount > 0) {
          calculatedDeposits += amount;
        } else if (amount < 0) {
          calculatedWithdrawals += amount;
        }
      }

      // ЗМІНА 2: Створюємо метадані файлу з детальною статистикою
      Map<String, dynamic> newFileEntry = {
        'name': customName,
        'uploadTime': DateTime.now().toIso8601String(),
        'status': 'success',
        'error': null,
        'stats': {
          'addedTrades': newTrades.length,
          'addedDividends': newDividends.length,
          'depositsAmount': calculatedDeposits,
          'withdrawalsAmount': calculatedWithdrawals,
          'dividendsAmount': totalDividends,
          'commissionsAmount': totalCommissions,
        },
      };
      // Додаємо новий файл в кінець списку
      existingSources.add(newFileEntry);

      // --- 7. ЗБЕРЕЖЕННЯ ---
      Map<String, dynamic> updateData = {
        'name': currentData['name'] ?? 'Мій звіт',
        'trades': uniqueTrades,
        'dividends': uniqueDividends,
        'cashTransactions': uniqueCashTrans,
        'totalDividends': totalDividends,
        'totalCommissions': totalCommissions,
        'totalDeposits': calculatedDeposits,
        'totalWithdrawals': calculatedWithdrawals,
        'sourceFiles':
            existingSources, // Зберігаємо оновлений список з об'єктами
        'lastSyncTime': FieldValue.serverTimestamp(),
        'isSyncRequired': false,
        'lastError': null,
      };

      if (newNetValue != 0) {
        updateData['lastBalance'] = newNetValue;
        updateData['value'] = newNetValue;
      }

      if (newAssets.isNotEmpty) {
        updateData['assets'] = newAssets;
        updateData['cashBalance'] = newCashBalance;
      } else if (newNetValue != 0 &&
          (currentData['assets'] == null ||
              (currentData['assets'] as List).isEmpty)) {
        updateData['cashBalance'] = newCashBalance;
      }

      await docRef.set(updateData, SetOptions(merge: true));

      return {
        'trades': uniqueTrades.length,
        'dividends': uniqueDividends.length,
        'deposits': calculatedDeposits,
        'withdrawals': calculatedWithdrawals,
        'cash': newCashBalance,
        'commissions': totalCommissions,
        'isDuplicate': false,
      };
    } catch (e) {
      rethrow;
    }
  }

  List<Map<String, dynamic>> _removeDuplicates(
    List<Map<String, dynamic>> list,
    String Function(Map<String, dynamic>) keyGenerator,
  ) {
    final seen = <String>{};
    return list.where((item) {
      final key = keyGenerator(item);
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}
