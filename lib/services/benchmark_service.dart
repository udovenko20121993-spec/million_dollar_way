import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/benchmark_data.dart';
import '../models/ibkr_data.dart';

/// Сервіс для порівняння портфеля з S&P 500
class BenchmarkService {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BenchmarkService({required this.userId});

  // Історичні річні дохідності S&P 500 (реальні дані)
  static const Map<int, double> sp500AnnualReturns = {
    2024: 23.31,   // До кінця року (приблизно)
    2023: 24.23,
    2022: -19.44,
    2021: 26.89,
    2020: 16.26,
    2019: 28.88,
    2018: -6.24,
    2017: 19.42,
    2016: 9.54,
    2015: -0.73,
    2014: 11.39,
    2013: 29.60,
    2012: 13.41,
    2011: 0.00,
    2010: 12.78,
  };

  // Місячні дохідності S&P 500 за 2024 рік
  static const Map<int, double> sp500MonthlyReturns2024 = {
    1: 1.59,    // Січень
    2: 5.17,    // Лютий
    3: 3.10,    // Березень
    4: -4.16,   // Квітень
    5: 4.80,    // Травень
    6: 3.47,    // Червень
    7: 1.13,    // Липень
    8: 2.28,    // Серпень
    9: 2.02,    // Вересень
    10: -0.99,  // Жовтень
    11: 5.73,   // Листопад
    12: -2.50,  // Грудень (приблизно)
  };

  // Поточна ціна S&P 500 (приблизна)
  static const double currentSP500Price = 5880.0;

  /// Розрахувати порівняння портфеля з S&P 500
  Future<BenchmarkComparison?> calculateComparison() async {
    try {
      // Отримуємо останній звіт користувача
      final reportsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('reports')
          .orderBy('lastSyncTime', descending: true)
          .limit(1)
          .get();

      if (reportsSnapshot.docs.isEmpty) return null;

      final report = IBKRReport.fromFirestore(reportsSnapshot.docs.first);

      // Знаходимо першу угоду (початок інвестування)
      if (report.trades.isEmpty) return null;

      final sortedTrades = List<IBKRTrade>.from(report.trades)
        ..sort((a, b) => a.date.compareTo(b.date));

      final firstTradeDate = _parseDate(sortedTrades.first.date);
      final now = DateTime.now();

      // Розраховуємо дохідність портфеля
      final totalDeposits = report.totalDeposits;
      final currentValue = report.lastBalance;
      final portfolioReturn = totalDeposits > 0
          ? ((currentValue - totalDeposits) / totalDeposits) * 100
          : 0.0;

      // Розраховуємо дохідність S&P 500 за той самий період
      final sp500Return = _calculateSP500Return(firstTradeDate, now);
      
      // Що було б якщо вкласти ті ж гроші в S&P 500
      final sp500Value = totalDeposits * (1 + sp500Return / 100);

      // Альфа = різниця в дохідності
      final alpha = portfolioReturn - sp500Return;

      // Генеруємо історію для графіка
      final portfolioHistory = _generatePortfolioHistory(report, sortedTrades);
      final benchmarkHistory = _generateBenchmarkHistory(
        firstTradeDate,
        now,
        totalDeposits,
      );

      return BenchmarkComparison(
        portfolioReturn: portfolioReturn,
        benchmarkReturn: sp500Return,
        alpha: alpha,
        portfolioValue: currentValue,
        benchmarkValue: sp500Value,
        startDate: firstTradeDate,
        endDate: now,
        portfolioHistory: portfolioHistory,
        benchmarkHistory: benchmarkHistory,
      );
    } catch (e) {
      print('Error calculating benchmark comparison: $e');
      return null;
    }
  }

  /// Отримати порівняння за різні періоди
  Future<List<PeriodComparison>> getPeriodComparisons() async {
    try {
      final reportsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('reports')
          .orderBy('lastSyncTime', descending: true)
          .limit(1)
          .get();

      if (reportsSnapshot.docs.isEmpty) return [];

      final report = IBKRReport.fromFirestore(reportsSnapshot.docs.first);
      final now = DateTime.now();

      final periods = <PeriodComparison>[];

      // YTD (з початку року)
      final ytdStart = DateTime(now.year, 1, 1);
      final ytdPortfolio = _calculatePortfolioReturnForPeriod(report, ytdStart, now);
      final ytdSP500 = _calculateSP500YTD(now);
      periods.add(PeriodComparison(
        period: 'YTD',
        portfolioReturn: ytdPortfolio,
        benchmarkReturn: ytdSP500,
        alpha: ytdPortfolio - ytdSP500,
      ));

      // 1 місяць
      final m1Start = now.subtract(const Duration(days: 30));
      final m1Portfolio = _calculatePortfolioReturnForPeriod(report, m1Start, now);
      final m1SP500 = _getMonthlyReturn(now.month);
      periods.add(PeriodComparison(
        period: '1M',
        portfolioReturn: m1Portfolio,
        benchmarkReturn: m1SP500,
        alpha: m1Portfolio - m1SP500,
      ));

      // 3 місяці
      final m3Start = DateTime(now.year, now.month - 3, now.day);
      final m3Portfolio = _calculatePortfolioReturnForPeriod(report, m3Start, now);
      final m3SP500 = _calculate3MonthSP500Return(now);
      periods.add(PeriodComparison(
        period: '3M',
        portfolioReturn: m3Portfolio,
        benchmarkReturn: m3SP500,
        alpha: m3Portfolio - m3SP500,
      ));

      // 1 рік
      final y1Start = DateTime(now.year - 1, now.month, now.day);
      final y1Portfolio = _calculatePortfolioReturnForPeriod(report, y1Start, now);
      final y1SP500 = sp500AnnualReturns[now.year - 1] ?? 10.0;
      periods.add(PeriodComparison(
        period: '1Y',
        portfolioReturn: y1Portfolio,
        benchmarkReturn: y1SP500,
        alpha: y1Portfolio - y1SP500,
      ));

      // Весь час
      final allTimeComparison = await calculateComparison();
      if (allTimeComparison != null) {
        periods.add(PeriodComparison(
          period: 'ALL',
          portfolioReturn: allTimeComparison.portfolioReturn,
          benchmarkReturn: allTimeComparison.benchmarkReturn,
          alpha: allTimeComparison.alpha,
        ));
      }

      return periods;
    } catch (e) {
      print('Error getting period comparisons: $e');
      return [];
    }
  }

  /// Розрахувати дохідність S&P 500 за період
  double _calculateSP500Return(DateTime start, DateTime end) {
    double totalReturn = 0;
    
    // Якщо в межах одного року
    if (start.year == end.year) {
      return _calculateSP500YTD(end) * (end.difference(start).inDays / 365);
    }

    // Рік початку (частковий)
    final daysInFirstYear = DateTime(start.year + 1, 1, 1).difference(start).inDays;
    final firstYearReturn = (sp500AnnualReturns[start.year] ?? 10.0) * 
        (daysInFirstYear / 365);
    totalReturn = firstYearReturn;

    // Повні роки між
    for (int year = start.year + 1; year < end.year; year++) {
      final yearReturn = sp500AnnualReturns[year] ?? 10.0;
      // Компаундінг
      totalReturn = totalReturn + yearReturn + (totalReturn * yearReturn / 100);
    }

    // Поточний рік (частковий)
    final ytdReturn = _calculateSP500YTD(end);
    totalReturn = totalReturn + ytdReturn + (totalReturn * ytdReturn / 100);

    return totalReturn;
  }

  /// Розрахувати YTD дохідність S&P 500
  double _calculateSP500YTD(DateTime date) {
    double ytd = 0;
    for (int month = 1; month <= date.month; month++) {
      final monthReturn = sp500MonthlyReturns2024[month] ?? 0;
      ytd = ytd + monthReturn + (ytd * monthReturn / 100);
    }
    return ytd;
  }

  /// Отримати місячну дохідність
  double _getMonthlyReturn(int month) {
    return sp500MonthlyReturns2024[month] ?? 0;
  }

  /// Розрахувати 3-місячну дохідність S&P 500
  double _calculate3MonthSP500Return(DateTime date) {
    double total = 0;
    for (int i = 0; i < 3; i++) {
      final month = date.month - i;
      if (month > 0) {
        final monthReturn = sp500MonthlyReturns2024[month] ?? 0;
        total = total + monthReturn + (total * monthReturn / 100);
      }
    }
    return total;
  }

  /// Розрахувати дохідність портфеля за період
  double _calculatePortfolioReturnForPeriod(
    IBKRReport report,
    DateTime start,
    DateTime end,
  ) {
    // Спрощений розрахунок на основі угод
    final tradesInPeriod = report.trades.where((t) {
      final date = _parseDate(t.date);
      return date.isAfter(start) && date.isBefore(end);
    }).toList();

    if (tradesInPeriod.isEmpty) {
      // Якщо немає угод в періоді, використовуємо загальну дохідність
      final totalDeposits = report.totalDeposits;
      if (totalDeposits <= 0) return 0;
      return ((report.lastBalance - totalDeposits) / totalDeposits) * 100;
    }

    // Розраховуємо на основі вартості акцій
    double startValue = 0;
    double invested = 0;
    
    for (final trade in tradesInPeriod) {
      if (trade.action.toUpperCase() == 'BUY') {
        invested += trade.cost.abs();
      }
    }

    if (invested <= 0) return 0;

    // Приблизна поточна вартість куплених акцій
    final currentValue = report.lastBalance;
    final periodDays = end.difference(start).inDays;
    final totalDays = end.difference(_getFirstTradeDate(report)).inDays;
    
    if (totalDays <= 0) return 0;
    
    // Пропорційна дохідність
    final totalReturn = ((currentValue - report.totalDeposits) / report.totalDeposits) * 100;
    return totalReturn * (periodDays / totalDays);
  }

  DateTime _getFirstTradeDate(IBKRReport report) {
    if (report.trades.isEmpty) return DateTime.now();
    final sorted = List<IBKRTrade>.from(report.trades)
      ..sort((a, b) => a.date.compareTo(b.date));
    return _parseDate(sorted.first.date);
  }

  /// Генерувати історію портфеля для графіка
  List<PerformancePoint> _generatePortfolioHistory(
    IBKRReport report,
    List<IBKRTrade> sortedTrades,
  ) {
    if (sortedTrades.isEmpty) return [];

    final points = <PerformancePoint>[];
    double runningValue = 0;
    double runningInvested = 0;

    // Групуємо угоди по місяцях
    final monthlyData = <String, Map<String, double>>{};
    
    for (final trade in sortedTrades) {
      final date = _parseDate(trade.date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      monthlyData[monthKey] ??= {'invested': 0, 'value': 0};
      
      if (trade.action.toUpperCase() == 'BUY') {
        monthlyData[monthKey]!['invested'] = 
            monthlyData[monthKey]!['invested']! + trade.cost.abs();
      }
    }

    // Конвертуємо в точки
    final sortedMonths = monthlyData.keys.toList()..sort();
    
    for (final monthKey in sortedMonths) {
      final parts = monthKey.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 15);
      
      runningInvested += monthlyData[monthKey]!['invested']!;
      
      // Приблизна вартість (з урахуванням середнього росту)
      final monthsFromStart = sortedMonths.indexOf(monthKey);
      final growthFactor = 1 + (0.10 * monthsFromStart / 12); // 10% річних
      runningValue = runningInvested * growthFactor;
      
      final returnPercent = runningInvested > 0
          ? ((runningValue - runningInvested) / runningInvested) * 100
          : 0.0;

      points.add(PerformancePoint(
        date: date,
        value: runningValue,
        returnPercent: returnPercent,
      ));
    }

    // Додаємо поточну точку
    points.add(PerformancePoint(
      date: DateTime.now(),
      value: report.lastBalance,
      returnPercent: report.totalDeposits > 0
          ? ((report.lastBalance - report.totalDeposits) / report.totalDeposits) * 100
          : 0,
    ));

    return points;
  }

  /// Генерувати історію S&P 500 для графіка
  List<PerformancePoint> _generateBenchmarkHistory(
    DateTime start,
    DateTime end,
    double initialInvestment,
  ) {
    final points = <PerformancePoint>[];
    var currentDate = DateTime(start.year, start.month, 1);
    double runningValue = initialInvestment;
    
    while (currentDate.isBefore(end)) {
      // Місячна дохідність S&P 500
      double monthlyReturn = 0.8; // ~10% річних / 12 місяців
      
      if (currentDate.year == 2024) {
        monthlyReturn = (sp500MonthlyReturns2024[currentDate.month] ?? 0.8);
      } else {
        final yearReturn = sp500AnnualReturns[currentDate.year] ?? 10.0;
        monthlyReturn = yearReturn / 12;
      }

      runningValue *= (1 + monthlyReturn / 100);
      
      final returnPercent = ((runningValue - initialInvestment) / initialInvestment) * 100;

      points.add(PerformancePoint(
        date: currentDate,
        value: runningValue,
        returnPercent: returnPercent,
      ));

      currentDate = DateTime(
        currentDate.month == 12 ? currentDate.year + 1 : currentDate.year,
        currentDate.month == 12 ? 1 : currentDate.month + 1,
        1,
      );
    }

    return points;
  }

  /// Парсинг дати з рядка
  DateTime _parseDate(String dateStr) {
    try {
      // Формати: "2024-01-15", "20240115", "15.01.2024"
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      } else if (dateStr.contains('.')) {
        final parts = dateStr.split('.');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } else if (dateStr.length == 8) {
        return DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Отримати назву періоду
  static String getPeriodName(String period) {
    switch (period) {
      case '1M': return '1 місяць';
      case '3M': return '3 місяці';
      case '6M': return '6 місяців';
      case 'YTD': return 'З початку року';
      case '1Y': return '1 рік';
      case 'ALL': return 'Весь час';
      default: return period;
    }
  }
}
