/// Модель для порівняння портфеля з бенчмарками (S&P 500)

class BenchmarkComparison {
  final double portfolioReturn;      // Дохідність портфеля (%)
  final double benchmarkReturn;      // Дохідність S&P 500 (%)
  final double alpha;                // Альфа (різниця в дохідності)
  final double portfolioValue;       // Поточна вартість портфеля
  final double benchmarkValue;       // Що було б якщо інвестувати в S&P 500
  final DateTime startDate;          // Початок періоду
  final DateTime endDate;            // Кінець періоду
  final List<PerformancePoint> portfolioHistory;
  final List<PerformancePoint> benchmarkHistory;

  BenchmarkComparison({
    required this.portfolioReturn,
    required this.benchmarkReturn,
    required this.alpha,
    required this.portfolioValue,
    required this.benchmarkValue,
    required this.startDate,
    required this.endDate,
    required this.portfolioHistory,
    required this.benchmarkHistory,
  });

  /// Чи перемагає портфель бенчмарк
  bool get isOutperforming => portfolioReturn > benchmarkReturn;

  /// Різниця у вартості
  double get valueDifference => portfolioValue - benchmarkValue;
}

/// Точка на графіку ефективності
class PerformancePoint {
  final DateTime date;
  final double value;           // Абсолютна вартість
  final double returnPercent;   // Дохідність від початку (%)

  PerformancePoint({
    required this.date,
    required this.value,
    required this.returnPercent,
  });
}

/// Історичні дані S&P 500
class SP500Data {
  final DateTime date;
  final double price;
  final double dailyReturn;
  final double ytdReturn;       // Year-to-date return

  SP500Data({
    required this.date,
    required this.price,
    required this.dailyReturn,
    required this.ytdReturn,
  });
}

/// Статистика порівняння за різні періоди
class PeriodComparison {
  final String period;          // "1M", "3M", "6M", "YTD", "1Y", "ALL"
  final double portfolioReturn;
  final double benchmarkReturn;
  final double alpha;

  PeriodComparison({
    required this.period,
    required this.portfolioReturn,
    required this.benchmarkReturn,
    required this.alpha,
  });

  bool get isOutperforming => portfolioReturn > benchmarkReturn;
}
