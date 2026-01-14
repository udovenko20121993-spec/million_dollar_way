import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/import_preview.dart';

class ImportPreviewService {
  
  /// Створити попередній перегляд файлу без збереження
  Future<ImportPreview> createPreview(
    PlatformFile file, {
    String? userId,
    String? reportId,
  }) async {
    try {
      // 1. Читання файлу
      String xmlContent;
      if (file.bytes != null) {
        xmlContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        xmlContent = await File(file.path!).readAsString();
      } else {
        return ImportPreview.error(file.name, 'Файл пустий');
      }

      // 2. Очищення XML
      xmlContent = _cleanXml(xmlContent);

      // 3. Парсинг
      final document = XmlDocument.parse(xmlContent);
      final flexStatement = document.findAllElements('FlexStatement').firstOrNull;

      if (flexStatement == null) {
        return ImportPreview.error(file.name, 'Невірний формат (немає FlexStatement)');
      }

      // 4. Отримання існуючих даних для перевірки дублікатів
      Set<String> existingTradeKeys = {};
      Set<String> existingDividendKeys = {};
      
      if (userId != null && reportId != null) {
        final existingData = await _getExistingData(userId, reportId);
        existingTradeKeys = existingData['tradeKeys'] as Set<String>;
        existingDividendKeys = existingData['dividendKeys'] as Set<String>;
      }

      // 5. Парсинг даних
      final result = _parseStatement(flexStatement, existingTradeKeys, existingDividendKeys);

      // 6. Отримання періоду
      DateTime? periodStart;
      DateTime? periodEnd;
      String accountId = '';

      final accountInfo = flexStatement.findAllElements('AccountInformation').firstOrNull;
      if (accountInfo != null) {
        accountId = accountInfo.getAttribute('accountId') ?? '';
      }

      // Шукаємо період з Statement
      final fromDate = flexStatement.getAttribute('fromDate');
      final toDate = flexStatement.getAttribute('toDate');
      
      if (fromDate != null) periodStart = _parseDate(fromDate);
      if (toDate != null) periodEnd = _parseDate(toDate);

      return ImportPreview(
        fileName: file.name,
        periodStart: periodStart,
        periodEnd: periodEnd,
        accountId: accountId,
        balance: result['balance'] as double,
        cashBalance: result['cashBalance'] as double,
        totalDividends: result['totalDividends'] as double,
        totalDeposits: result['totalDeposits'] as double,
        totalWithdrawals: result['totalWithdrawals'] as double,
        totalCommissions: result['totalCommissions'] as double,
        tradesCount: (result['trades'] as List).length,
        dividendsCount: (result['dividends'] as List).length,
        assetsCount: (result['assets'] as List).length,
        cashTransactionsCount: (result['cashTransactions'] as List).length,
        duplicateTradesCount: result['duplicateTrades'] as int,
        duplicateDividendsCount: result['duplicateDividends'] as int,
        newTradesCount: result['newTrades'] as int,
        newDividendsCount: result['newDividends'] as int,
        trades: result['trades'] as List<Map<String, dynamic>>,
        dividends: result['dividends'] as List<Map<String, dynamic>>,
        assets: result['assets'] as List<Map<String, dynamic>>,
        cashTransactions: result['cashTransactions'] as List<Map<String, dynamic>>,
        isValid: true,
      );
    } catch (e) {
      return ImportPreview.error(file.name, 'Помилка парсингу: $e');
    }
  }

  /// Отримати існуючі дані для перевірки дублікатів
  Future<Map<String, dynamic>> _getExistingData(String userId, String reportId) async {
    Set<String> tradeKeys = {};
    Set<String> dividendKeys = {};

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reports')
          .doc(reportId)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        
        // Ключі для угод
        final trades = data['trades'] as List? ?? [];
        for (var t in trades) {
          final key = "${t['date']}_${t['symbol']}_${t['action']}_${t['quantity']}_${t['price']}";
          tradeKeys.add(key);
        }

        // Ключі для дивідендів
        final dividends = data['dividends'] as List? ?? [];
        for (var d in dividends) {
          final key = "${d['date']}_${d['symbol']}_${d['amount']}";
          dividendKeys.add(key);
        }
      }
    } catch (e) {
      print('Error getting existing data: $e');
    }

    return {
      'tradeKeys': tradeKeys,
      'dividendKeys': dividendKeys,
    };
  }

  /// Парсинг FlexStatement
  Map<String, dynamic> _parseStatement(
    XmlElement statement,
    Set<String> existingTradeKeys,
    Set<String> existingDividendKeys,
  ) {
    List<Map<String, dynamic>> trades = [];
    List<Map<String, dynamic>> dividends = [];
    List<Map<String, dynamic>> assets = [];
    List<Map<String, dynamic>> cashTransactions = [];
    
    double totalDividends = 0;
    double totalDeposits = 0;
    double totalWithdrawals = 0;
    double totalCommissions = 0;
    
    int duplicateTrades = 0;
    int duplicateDividends = 0;
    int newTrades = 0;
    int newDividends = 0;

    // === УГОДИ ===
    for (var trade in statement.findAllElements('Trade')) {
      if (trade.getAttribute('assetCategory') == 'Total') continue;
      if (trade.getAttribute('symbol') == null) continue;

      double commission = (double.tryParse(trade.getAttribute('ibCommission') ?? "0") ?? 0).abs();
      totalCommissions += commission;

      final tradeData = {
        'date': trade.getAttribute('dateTime') ?? '',
        'symbol': trade.getAttribute('symbol') ?? '',
        'action': trade.getAttribute('buySell') ?? '',
        'quantity': double.tryParse(trade.getAttribute('quantity') ?? "0") ?? 0,
        'price': double.tryParse(trade.getAttribute('tradePrice') ?? "0") ?? 0,
        'cost': double.tryParse(trade.getAttribute('cost') ?? "0") ?? 0,
        'commission': commission,
      };

      final key = "${tradeData['date']}_${tradeData['symbol']}_${tradeData['action']}_${tradeData['quantity']}_${tradeData['price']}";
      
      if (existingTradeKeys.contains(key)) {
        duplicateTrades++;
      } else {
        newTrades++;
      }
      
      trades.add(tradeData);
    }

    // === ГРОШОВІ ТРАНЗАКЦІЇ ===
    for (var tx in statement.findAllElements('CashTransaction')) {
      String type = tx.getAttribute('type') ?? '';
      double amount = double.tryParse(tx.getAttribute('amount') ?? "0") ?? 0;
      double fxRate = double.tryParse(tx.getAttribute('fxRateToBase') ?? "1") ?? 1;
      double amountUSD = amount * fxRate;

      final txData = {
        'date': tx.getAttribute('dateTime') ?? '',
        'type': type,
        'amount': amountUSD,
        'originalAmount': amount,
        'currency': tx.getAttribute('currency') ?? 'USD',
        'symbol': tx.getAttribute('symbol') ?? '',
        'description': tx.getAttribute('description') ?? '',
      };

      // Депозити/Виведення
      if (type.startsWith('Deposit') || type.startsWith('Withdrawal') || 
          type.contains('Transfer') || (type == 'Cash' && amountUSD.abs() > 0.01)) {
        cashTransactions.add(txData);
        
        if (amountUSD > 0) {
          totalDeposits += amountUSD;
        } else {
          totalWithdrawals += amountUSD.abs();
        }
      }
      // Дивіденди
      else if (type.startsWith('Dividend') || type == 'PaymentInLieuOfDividends') {
        final divData = {
          'date': txData['date'],
          'symbol': (txData['symbol'] as String).isEmpty ? 'DIV' : txData['symbol'],
          'amount': amountUSD,
          'description': txData['description'],
        };
        
        final key = "${divData['date']}_${divData['symbol']}_${divData['amount']}";
        
        if (existingDividendKeys.contains(key)) {
          duplicateDividends++;
        } else {
          newDividends++;
        }
        
        dividends.add(divData);
        totalDividends += amountUSD;
      }
    }

    // === ДИВІДЕНДИ (Accruals) ===
    for (var div in statement.findAllElements('ChangeInDividendAccrual')) {
      if (div.getAttribute('payDate') == null) continue;
      
      double amount = double.tryParse(div.getAttribute('grossAmount') ?? 
                                       div.getAttribute('netAmount') ?? "0") ?? 0;
      if (amount == 0) continue;

      final divData = {
        'date': div.getAttribute('payDate') ?? '',
        'symbol': div.getAttribute('symbol') ?? 'DIV',
        'amount': amount,
        'description': div.getAttribute('description') ?? 'Dividend',
      };

      final key = "${divData['date']}_${divData['symbol']}_${divData['amount']}";
      
      if (existingDividendKeys.contains(key)) {
        duplicateDividends++;
      } else {
        newDividends++;
      }

      dividends.add(divData);
      totalDividends += amount;
    }

    // === БАЛАНС ===
    double balance = 0;
    for (var nav in statement.findAllElements('EquitySummaryByReportDateInBase')) {
      String? val = nav.getAttribute('total') ?? nav.getAttribute('cash');
      if (val != null) {
        double parsed = double.tryParse(val) ?? 0;
        if (parsed != 0) balance = parsed;
      }
    }

    // === КЕШ ===
    double cashBalance = 0;
    for (var el in statement.findAllElements('CashReportCurrency')) {
      String curr = el.getAttribute('currency') ?? '';
      if (curr == 'BASE' || curr == 'USD') {
        cashBalance = double.tryParse(el.getAttribute('endingSettled') ?? 
                                       el.getAttribute('endingCash') ?? "0") ?? 0;
        if (curr == 'BASE') break;
      }
    }

    // === АКТИВИ ===
    for (var pos in statement.findAllElements('OpenPosition')) {
      if (pos.getAttribute('symbol') == null) continue;
      
      assets.add({
        'symbol': pos.getAttribute('symbol') ?? 'Unknown',
        'quantity': double.tryParse(pos.getAttribute('position') ?? "0") ?? 0,
        'value': double.tryParse(pos.getAttribute('positionValue') ?? "0") ?? 0,
        'change': double.tryParse(pos.getAttribute('unrealizedPnl') ?? "0") ?? 0,
        'name': pos.getAttribute('description') ?? '',
      });
    }

    return {
      'trades': trades,
      'dividends': dividends,
      'assets': assets,
      'cashTransactions': cashTransactions,
      'balance': balance,
      'cashBalance': cashBalance,
      'totalDividends': totalDividends,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'totalCommissions': totalCommissions,
      'duplicateTrades': duplicateTrades,
      'duplicateDividends': duplicateDividends,
      'newTrades': newTrades,
      'newDividends': newDividends,
    };
  }

  /// Очищення XML від namespace та BOM
  String _cleanXml(String xml) {
    if (xml.isNotEmpty && xml.codeUnitAt(0) == 0xFEFF) {
      xml = xml.substring(1);
    }
    xml = xml.replaceAll(RegExp(r'<\?xml.*?\?>'), '');
    xml = xml.replaceAll(RegExp(r' (xmlns|xsi)(:[\w-]+)?="[^"]*"'), '');
    xml = xml.replaceAll(RegExp(r" (xmlns|xsi)(:[\w-]+)?='[^']*'"), '');
    xml = xml.replaceAll(RegExp(r'<([\w-]+):'), '<');
    xml = xml.replaceAll(RegExp(r'</([\w-]+):'), '</');
    return xml;
  }

  /// Парсинг дати IBKR
  DateTime? _parseDate(String dateStr) {
    try {
      // Формат: YYYYMMDD або YYYY-MM-DD
      if (dateStr.length == 8) {
        return DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
      } else if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
    } catch (_) {}
    return null;
  }
}
