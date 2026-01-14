import 'dart:async';
import 'dart:math';
import 'package:million_dollar_way/services/ibkr_xml_parser.dart';

/// Модель позиції акції
class StockPosition {
  final String ticker;
  final int quantity;
  final double costBasis;
  final double currentPrice;
  final DateTime startDate;

  StockPosition({
    required this.ticker,
    required this.quantity,
    required this.costBasis,
    required this.currentPrice,
    required this.startDate,
  });

  double get currentValue => quantity * currentPrice;
  double get totalCost => costBasis * quantity;
  double get unrealizedPnL => currentValue - totalCost;
  double get unrealizedPnLPercent =>
      totalCost > 0 ? (unrealizedPnL / totalCost) * 100 : 0;

  /// Розрахунок L32 девіації
  double calculateL32Deviation() {
    final weeksSinceStart = DateTime.now().difference(startDate).inDays / 7.0;
    final targetValue = weeksSinceStart * MDWEngine.weeklyTargetPerStock;
    return targetValue - currentValue;
  }

  StockPosition copyWith({
    String? ticker,
    int? quantity,
    double? costBasis,
    double? currentPrice,
    DateTime? startDate,
  }) {
    return StockPosition(
      ticker: ticker ?? this.ticker,
      quantity: quantity ?? this.quantity,
      costBasis: costBasis ?? this.costBasis,
      currentPrice: currentPrice ?? this.currentPrice,
      startDate: startDate ?? this.startDate,
    );
  }
}

/// Допоміжні моделі
class StockDeviation {
  final String ticker;
  final double deviation;
  final StockPosition currentPosition;

  StockDeviation({
    required this.ticker,
    required this.deviation,
    required this.currentPosition,
  });
}

class StockAllocation {
  final String ticker;
  final double amount;
  final double deviation;
  final double estimatedShares;

  StockAllocation({
    required this.ticker,
    required this.amount,
    required this.deviation,
    required this.estimatedShares,
  });
}

class PortfolioStats {
  final double totalValue;
  final double totalCost;
  final double cashAmount;
  final double netCapital;
  final double totalPnL;
  final double totalPnLPercent;
  final int positivePositions;
  final int negativePositions;
  final int totalPositions;

  PortfolioStats({
    required this.totalValue,
    required this.totalCost,
    required this.cashAmount,
    required this.netCapital,
    required this.totalPnL,
    required this.totalPnLPercent,
    required this.positivePositions,
    required this.negativePositions,
    required this.totalPositions,
  });
}

class ProjectionPoint {
  final double year;
  final double value;

  const ProjectionPoint({required this.year, required this.value});
}

/// Основний двигун Million Dollar Way - реалізує L32 логіку та управління капіталом
class MDWEngine {
  static MDWEngine? _instance;
  static MDWEngine get instance => _instance ??= MDWEngine._();

  MDWEngine._();

  /// Константи L32 стратегії
  static const double weeklyTargetPerStock = 1.0; // $1 на тиждень на акцію
  static const int totalStocks = 51;
  static const double totalWeeklyTarget =
      weeklyTargetPerStock * totalStocks; // $51 на тиждень
  static const double annualCAGR = 0.145; // 14.5% річних
  static const double commissionThreshold = 100.0; // Поріг для комісії

  /// Розрахунок майбутньої вартості (аннуїтетна формула)
  double calculateFutureValue(
    double monthlyInvestment,
    int years,
    double annualRate,
  ) {
    final monthlyRate = annualRate / 12;
    final months = years * 12;

    // FV = P * ((1 + r)^n - 1) / r
    return monthlyInvestment * (pow(1 + monthlyRate, months) - 1) / monthlyRate;
  }

  List<ProjectionPoint> calculateProjectionSeries({
    required double initialCapital,
    required double monthlyContribution,
    required double expectedAnnualReturn,
    required int projectionYears,
  }) {
    final points = <ProjectionPoint>[];
    var value = max(0, initialCapital);
    final months = max(1, projectionYears * 12);
    final monthlyRate = expectedAnnualReturn <= 0
        ? 0.0
        : expectedAnnualReturn / 12;

    points.add(ProjectionPoint(year: 0, value: value.toDouble()));

    for (var month = 1; month <= months; month++) {
      value = (value + monthlyContribution).clamp(0, double.infinity);
      value = value * (1 + monthlyRate);

      if (month % 12 == 0 || month == months) {
        points.add(ProjectionPoint(year: month / 12, value: value.toDouble()));
      }
    }

    return points;
  }

  int? estimateYearsToGoal({
    required double currentCapital,
    required double monthlyContribution,
    required double expectedAnnualReturn,
    required double goalValue,
  }) {
    if (goalValue <= currentCapital) return 0;
    if (monthlyContribution <= 0 && expectedAnnualReturn <= 0) return null;

    var value = currentCapital;
    final monthlyRate = expectedAnnualReturn <= 0
        ? 0.0
        : expectedAnnualReturn / 12;

    for (var month = 1; month <= 1200; month++) {
      value = (value + monthlyContribution) * (1 + monthlyRate);
      if (value >= goalValue) {
        return (month / 12).ceil();
      }
    }

    return null;
  }

  /// Розрахунок комісії
  double calculateCommission(double tradeValue, {bool useTiered = true}) {
    if (!useTiered || tradeValue <= commissionThreshold) {
      return 1.0; // Фіксована комісія
    }

    // Тієрова комісія (приклад)
    if (tradeValue <= 1000) return 1.0;
    if (tradeValue <= 10000) return 2.0;
    if (tradeValue <= 100000) return 5.0;
    return 10.0;
  }

  /// Розподіл капіталу за L32 логікою
  List<StockAllocation> distributeCash(
    List<StockPosition> positions,
    double availableCash,
  ) {
    // Розраховуємо девіації для всіх акцій
    final deviations = positions
        .map((pos) {
          return StockDeviation(
            ticker: pos.ticker,
            deviation: pos.calculateL32Deviation(),
            currentPosition: pos,
          );
        })
        .where((dev) => dev.deviation > 0)
        .toList(); // Тільки ті, що відстають

    // Сортуємо за девіацією (найбільші перші)
    deviations.sort((a, b) => b.deviation.compareTo(a.deviation));

    // Беремо топ 3-5 акцій
    final topDeviations = deviations.take(min(5, deviations.length)).toList();

    if (topDeviations.isEmpty) return [];

    // Розподіляємо кеш пропорційно до девіації
    final totalDeviation = topDeviations
        .map((d) => d.deviation)
        .reduce((a, b) => a + b);

    return topDeviations.map((dev) {
      final allocationRatio = dev.deviation / totalDeviation;
      final allocatedAmount = availableCash * allocationRatio;

      return StockAllocation(
        ticker: dev.ticker,
        amount: allocatedAmount,
        deviation: dev.deviation,
        estimatedShares: allocatedAmount / dev.currentPosition.currentPrice,
      );
    }).toList();
  }

  /// Оновлення позицій новими цінами
  List<StockPosition> updatePrices(
    List<StockPosition> positions,
    Map<String, double> newPrices,
  ) {
    return positions.map((pos) {
      final newPrice = newPrices[pos.ticker] ?? pos.currentPrice;
      return pos.copyWith(currentPrice: newPrice);
    }).toList();
  }

  /// Розрахунок загальної статистики портфоліо
  PortfolioStats calculatePortfolioStats(
    List<StockPosition> positions,
    double cashAmount,
  ) {
    final totalValue = positions.fold(
      0.0,
      (sum, pos) => sum + pos.currentValue,
    );
    final totalCost = positions.fold(0.0, (sum, pos) => sum + pos.totalCost);
    final totalPnL = totalValue - totalCost;
    final totalPnLPercent = totalCost > 0 ? (totalPnL / totalCost) * 100 : 0;

    final positivePositions = positions
        .where((p) => p.unrealizedPnL > 0)
        .length;
    final negativePositions = positions
        .where((p) => p.unrealizedPnL < 0)
        .length;

    return PortfolioStats(
      totalValue: totalValue,
      totalCost: totalCost,
      cashAmount: cashAmount,
      netCapital: totalValue + cashAmount,
      totalPnL: totalPnL,
      totalPnLPercent: totalPnLPercent.toDouble(),
      positivePositions: positivePositions,
      negativePositions: negativePositions,
      totalPositions: positions.length,
    );
  }

  /// Обробка позицій з IBKR парсера
  Future<void> processPositions(List<MDWStockPosition> positions) async {
    try {
      // Конвертуємо MDWStockPosition в наш формат StockPosition
      final stockPositions = positions.map((pos) {
        return StockPosition(
          ticker: pos.ticker,
          quantity: pos.quantity,
          costBasis: pos.costBasis,
          currentPrice: pos.currentPrice,
          startDate: pos.startDate,
        );
      }).toList();

      // Тут може бути логіка для обробки позицій
      print('Processed ${stockPositions.length} positions');

      // Розрахунок статистики портфоліо
      final stats = calculatePortfolioStats(stockPositions, 0.0);
      print('Portfolio value: \$${stats.totalValue.toStringAsFixed(2)}');
    } catch (e) {
      print('Error processing positions: $e');
    }
  }
}
