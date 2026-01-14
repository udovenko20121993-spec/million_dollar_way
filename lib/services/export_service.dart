import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ibkr_data.dart';

/// Сервіс для експорту даних у різні формати
class ExportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Експорт угод у CSV для податкової
  Future<String> exportTradesToCsv(
    String userId,
    String reportId, {
    int? year,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .get();

    if (!doc.exists) throw 'Звіт не знайдено';

    final data = doc.data() ?? {};
    final trades = (data['trades'] as List? ?? [])
        .map((t) => IBKRTrade.fromMap(t as Map<String, dynamic>))
        .toList();

    // Фільтруємо по року якщо вказано
    List<IBKRTrade> filteredTrades = trades;
    if (year != null) {
      filteredTrades = trades.where((t) {
        final tradeYear = _extractYear(t.date);
        return tradeYear == year;
      }).toList();
    }

    // Сортуємо по даті
    filteredTrades.sort((a, b) => a.date.compareTo(b.date));

    // Створюємо CSV
    List<List<dynamic>> rows = [
      // Заголовки
      [
        'Дата',
        'Тікер',
        'Тип',
        'Кількість',
        'Ціна (USD)',
        'Сума (USD)',
        'Комісія (USD)',
        'Чиста сума (USD)',
      ],
    ];

    double totalBuy = 0;
    double totalSell = 0;
    double totalCommission = 0;

    for (var trade in filteredTrades) {
      final isBuy = trade.action.toUpperCase() == 'BUY';
      final total = trade.price * trade.quantity;
      final netAmount = isBuy ? -(total + trade.commission) : (total - trade.commission);

      if (isBuy) {
        totalBuy += total;
      } else {
        totalSell += total;
      }
      totalCommission += trade.commission;

      rows.add([
        _formatDate(trade.date),
        trade.symbol,
        isBuy ? 'Купівля' : 'Продаж',
        trade.quantity,
        trade.price.toStringAsFixed(4),
        total.toStringAsFixed(2),
        trade.commission.toStringAsFixed(2),
        netAmount.toStringAsFixed(2),
      ]);
    }

    // Підсумки
    rows.add([]);
    rows.add(['ПІДСУМКИ', '', '', '', '', '', '', '']);
    rows.add(['Загальна сума купівель:', '', '', '', '', totalBuy.toStringAsFixed(2), '', '']);
    rows.add(['Загальна сума продажів:', '', '', '', '', totalSell.toStringAsFixed(2), '', '']);
    rows.add(['Загальні комісії:', '', '', '', '', '', totalCommission.toStringAsFixed(2), '']);
    rows.add(['Чистий P&L (без комісій):', '', '', '', '', (totalSell - totalBuy).toStringAsFixed(2), '', '']);
    rows.add(['Чистий P&L (з комісіями):', '', '', '', '', '', '', (totalSell - totalBuy - totalCommission).toStringAsFixed(2)]);

    final csv = const ListToCsvConverter().convert(rows);
    final fileName = year != null ? 'trades_$year.csv' : 'trades_all.csv';
    
    return await _saveAndShareCsv(csv, fileName);
  }

  /// Експорт дивідендів у CSV для податкової
  Future<String> exportDividendsToCsv(
    String userId,
    String reportId, {
    int? year,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .get();

    if (!doc.exists) throw 'Звіт не знайдено';

    final data = doc.data() ?? {};
    final dividends = (data['dividends'] as List? ?? [])
        .map((d) => IBKRDividend.fromMap(d as Map<String, dynamic>))
        .toList();

    // Фільтруємо по року
    List<IBKRDividend> filteredDividends = dividends;
    if (year != null) {
      filteredDividends = dividends.where((d) {
        final divYear = _extractYear(d.date);
        return divYear == year;
      }).toList();
    }

    // Сортуємо по даті
    filteredDividends.sort((a, b) => a.date.compareTo(b.date));

    // Групуємо по тікеру для підсумків
    Map<String, double> bySymbol = {};

    List<List<dynamic>> rows = [
      ['Дата', 'Тікер', 'Сума (USD)', 'Опис'],
    ];

    double total = 0;

    for (var div in filteredDividends) {
      rows.add([
        _formatDate(div.date),
        div.symbol,
        div.amount.toStringAsFixed(2),
        div.description,
      ]);
      total += div.amount;
      bySymbol[div.symbol] = (bySymbol[div.symbol] ?? 0) + div.amount;
    }

    // Підсумки
    rows.add([]);
    rows.add(['ПІДСУМКИ ПО ТІКЕРАХ', '', '', '']);
    
    final sortedSymbols = bySymbol.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sortedSymbols) {
      rows.add([entry.key, '', entry.value.toStringAsFixed(2), '']);
    }

    rows.add([]);
    rows.add(['ЗАГАЛЬНА СУМА ДИВІДЕНДІВ:', '', total.toStringAsFixed(2), '']);

    // Розрахунок податків (Україна)
    final pdfo = total * 0.18;
    final military = total * 0.05;
    final totalTax = pdfo + military;
    final netDividends = total - totalTax;

    rows.add([]);
    rows.add(['ПОДАТКИ (Україна)', '', '', '']);
    rows.add(['ПДФО (18%):', '', pdfo.toStringAsFixed(2), '']);
    rows.add(['Військовий збір (5%):', '', military.toStringAsFixed(2), '']);
    rows.add(['Загальний податок (23%):', '', totalTax.toStringAsFixed(2), '']);
    rows.add(['Чистий дохід після податків:', '', netDividends.toStringAsFixed(2), '']);

    final csv = const ListToCsvConverter().convert(rows);
    final fileName = year != null ? 'dividends_$year.csv' : 'dividends_all.csv';
    
    return await _saveAndShareCsv(csv, fileName);
  }

  /// Експорт депозитів/виведень у CSV
  Future<String> exportCashFlowToCsv(
    String userId,
    String reportId, {
    int? year,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .get();

    if (!doc.exists) throw 'Звіт не знайдено';

    final data = doc.data() ?? {};
    final transactions = (data['cashTransactions'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    // Фільтруємо по року
    List<Map<String, dynamic>> filtered = transactions;
    if (year != null) {
      filtered = transactions.where((t) {
        final txYear = _extractYear(t['date']?.toString() ?? '');
        return txYear == year;
      }).toList();
    }

    // Сортуємо по даті
    filtered.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

    List<List<dynamic>> rows = [
      ['Дата', 'Тип', 'Сума (USD)', 'Валюта', 'Опис'],
    ];

    double totalDeposits = 0;
    double totalWithdrawals = 0;

    for (var tx in filtered) {
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      final type = tx['type']?.toString() ?? '';
      
      rows.add([
        _formatDate(tx['date']?.toString() ?? ''),
        type,
        amount.toStringAsFixed(2),
        tx['currency'] ?? 'USD',
        tx['description'] ?? '',
      ]);

      if (amount > 0) {
        totalDeposits += amount;
      } else {
        totalWithdrawals += amount.abs();
      }
    }

    rows.add([]);
    rows.add(['ПІДСУМКИ', '', '', '', '']);
    rows.add(['Загальні депозити:', '', totalDeposits.toStringAsFixed(2), '', '']);
    rows.add(['Загальні виведення:', '', totalWithdrawals.toStringAsFixed(2), '', '']);
    rows.add(['Чистий грошовий потік:', '', (totalDeposits - totalWithdrawals).toStringAsFixed(2), '', '']);

    final csv = const ListToCsvConverter().convert(rows);
    final fileName = year != null ? 'cashflow_$year.csv' : 'cashflow_all.csv';
    
    return await _saveAndShareCsv(csv, fileName);
  }

  /// Повний річний звіт для податкової
  Future<String> exportFullTaxReport(
    String userId,
    String reportId,
    int year,
  ) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .get();

    if (!doc.exists) throw 'Звіт не знайдено';

    final data = doc.data() ?? {};
    
    // Парсимо всі дані
    final trades = (data['trades'] as List? ?? [])
        .map((t) => IBKRTrade.fromMap(t as Map<String, dynamic>))
        .where((t) => _extractYear(t.date) == year)
        .toList();
    
    final dividends = (data['dividends'] as List? ?? [])
        .map((d) => IBKRDividend.fromMap(d as Map<String, dynamic>))
        .where((d) => _extractYear(d.date) == year)
        .toList();

    final cashTx = (data['cashTransactions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((t) => _extractYear(t['date']?.toString() ?? '') == year)
        .toList();

    // Рахуємо статистику
    double totalBuy = 0;
    double totalSell = 0;
    double totalCommission = 0;
    
    for (var t in trades) {
      final total = t.price * t.quantity;
      if (t.action.toUpperCase() == 'BUY') {
        totalBuy += total;
      } else {
        totalSell += total;
      }
      totalCommission += t.commission;
    }

    double totalDividends = dividends.fold(0.0, (sum, d) => sum + d.amount);
    
    double totalDeposits = 0;
    double totalWithdrawals = 0;
    for (var tx in cashTx) {
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      if (amount > 0) {
        totalDeposits += amount;
      } else {
        totalWithdrawals += amount.abs();
      }
    }

    // Податки
    final dividendTax = totalDividends * 0.23; // ПДФО 18% + ВЗ 5%
    final tradingPnL = totalSell - totalBuy - totalCommission;
    final tradingTax = tradingPnL > 0 ? tradingPnL * 0.23 : 0;

    List<List<dynamic>> rows = [
      ['═══════════════════════════════════════════════════════════'],
      ['РІЧНИЙ ПОДАТКОВИЙ ЗВІТ $year'],
      ['═══════════════════════════════════════════════════════════'],
      [],
      ['ТОРГІВЛЯ АКЦІЯМИ'],
      ['─────────────────────────────────────────────────────────────'],
      ['Кількість угод:', trades.length],
      ['Загальна сума купівель:', '\$${totalBuy.toStringAsFixed(2)}'],
      ['Загальна сума продажів:', '\$${totalSell.toStringAsFixed(2)}'],
      ['Комісії брокера:', '\$${totalCommission.toStringAsFixed(2)}'],
      ['Прибуток/Збиток:', '\$${tradingPnL.toStringAsFixed(2)}'],
      [],
      ['ДИВІДЕНДИ'],
      ['─────────────────────────────────────────────────────────────'],
      ['Кількість виплат:', dividends.length],
      ['Загальна сума:', '\$${totalDividends.toStringAsFixed(2)}'],
      [],
      ['ГРОШОВІ ПОТОКИ'],
      ['─────────────────────────────────────────────────────────────'],
      ['Депозити:', '\$${totalDeposits.toStringAsFixed(2)}'],
      ['Виведення:', '\$${totalWithdrawals.toStringAsFixed(2)}'],
      [],
      ['═══════════════════════════════════════════════════════════'],
      ['ПОДАТКИ (Україна - ПДФО 18% + ВЗ 5% = 23%)'],
      ['═══════════════════════════════════════════════════════════'],
      [],
      ['Податок на дивіденди:', '\$${dividendTax.toStringAsFixed(2)}'],
      ['Податок на торгівлю:', '\$${tradingTax.toStringAsFixed(2)}'],
      ['───────────────────────────────────────────'],
      ['ЗАГАЛЬНИЙ ПОДАТОК:', '\$${(dividendTax + tradingTax).toStringAsFixed(2)}'],
      [],
      ['Примітка: Якщо торгівля збиткова, податок = 0'],
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final fileName = 'tax_report_$year.csv';
    
    return await _saveAndShareCsv(csv, fileName);
  }

  /// Зберегти CSV та відкрити Share dialog
  Future<String> _saveAndShareCsv(String csvContent, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvContent);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: fileName,
    );
    
    return file.path;
  }

  /// Отримати рік з дати IBKR
  int? _extractYear(String dateStr) {
    try {
      if (dateStr.isEmpty) return null;
      
      // Формат: YYYYMMDD або YYYY-MM-DD або YYYYMMDD;HHMMSS
      String cleanDate = dateStr.split(';').first.split('T').first.replaceAll('-', '');
      
      if (cleanDate.length >= 4) {
        return int.parse(cleanDate.substring(0, 4));
      }
    } catch (_) {}
    return null;
  }

  /// Форматування дати для CSV
  String _formatDate(String rawDate) {
    try {
      String dateStr = rawDate.split(';').first.split('T').first.replaceAll('-', '');
      
      if (dateStr.length >= 8) {
        return '${dateStr.substring(6, 8)}.${dateStr.substring(4, 6)}.${dateStr.substring(0, 4)}';
      }
    } catch (_) {}
    return rawDate;
  }

  /// Отримати доступні роки з даних
  Future<List<int>> getAvailableYears(String userId, String reportId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .get();

    if (!doc.exists) return [];

    final data = doc.data() ?? {};
    final years = <int>{};

    // З угод
    final trades = data['trades'] as List? ?? [];
    for (var t in trades) {
      final year = _extractYear(t['date']?.toString() ?? '');
      if (year != null) years.add(year);
    }

    // З дивідендів
    final dividends = data['dividends'] as List? ?? [];
    for (var d in dividends) {
      final year = _extractYear(d['date']?.toString() ?? '');
      if (year != null) years.add(year);
    }

    final result = years.toList()..sort((a, b) => b.compareTo(a)); // Desc
    return result;
  }
}
