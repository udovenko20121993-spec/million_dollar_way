import 'dart:math';
import '../domain/models/midas_models.dart';

class MidasCalculationService {
  static const double commissionMultiplier = 0.99; // 1% commission rule
  static const double taxRate = 0.23; // 23% tax (PIT + Military - Law 4015-IX)
  static const int weeksPerYear = 52;
  static const double targetMillion = 1000000.0;
  static const double weeklyTargetPerStock =
      1.0; // $1 per week per stock (Excel L32)
  static const int totalStocks = 51; // Total number of stocks in portfolio

  const MidasCalculationService();

  /// Розрахунок девіацій для всіх акцій з реальними даними
  List<DCARecommendation> calculateAllDeviations({
    required List<StockPosition> positions,
    required DateTime startDate,
    required double weeklyTarget,
  }) {
    final recommendations = <DCARecommendation>[];
    final weeksSinceStart = DateTime.now().difference(startDate).inDays / 7.0;

    for (final position in positions) {
      // Розрахунок цільової вартості за Excel L32 формулою
      final targetValue = weeksSinceStart * weeklyTargetPerStock;

      // Поточна ринкова вартість (кількість * поточна ціна)
      final currentValue = position.currentMarketValue;

      // Розрахунок девіації
      final deviation = targetValue - currentValue;
      final deviationPercentage = targetValue > 0
          ? (deviation / targetValue) * 100
          : 0.0;

      // Визначення дії
      String action;
      if (deviation > 0.99) {
        action = 'Покупать';
      } else if (deviation < -0.99) {
        action = 'Продавать';
      } else {
        action = 'Держать';
      }

      // Розрахунок рекомендованої суми для покупки
      double recommendedAmount = 0.0;
      if (action == 'Покупать') {
        recommendedAmount = deviation;
      } else if (action == 'Продавать') {
        recommendedAmount = deviation.abs();
      }

      recommendations.add(
        DCARecommendation(
          symbol: position.symbol,
          action: action,
          amount: recommendedAmount,
          targetValue: targetValue,
          currentValue: currentValue,
          deviation: deviation,
          deviationPercentage: deviationPercentage,
          priority: deviation.abs(), // Пріоритет за розміром девіації
          reason: _generateReason(action, deviation, weeksSinceStart),
          isCashAdjusted: false,
          adjustedAmount: recommendedAmount,
        ),
      );
    }

    // Сортування за пріоритетом (найбільша девіація перша)
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    return recommendations;
  }

  /// Генерація пояснення для рекомендації
  String _generateReason(
    String action,
    double deviation,
    double weeksSinceStart,
  ) {
    switch (action) {
      case 'Покупать':
        return 'Позиція відстає від плану на ${weeksSinceStart.toInt()} тижнів. Рекомендовано докупити для досягнення цілі.';
      case 'Продавать':
        return 'Позиція перевиконує план. Рекомендовано частково зафіксувати прибуток.';
      default:
        return 'Позиція відповідає цільовим показникам.';
    }
  }

  /// Smart Cash Management - Priority Allocation Algorithm
  CashAllocationResult priorityCashAllocation({
    required List<DCARecommendation> allRecommendations,
    required double availableCash,
  }) {
    // Фільтруємо тільки ті, що потребують купівлі
    final purchaseRecommendations = allRecommendations
        .where((rec) => rec.action == "Покупать")
        .toList();

    if (purchaseRecommendations.isEmpty) {
      return CashAllocationResult(
        totalIdealBuy: 0.0,
        availableCash: availableCash,
        cashShortage: 0.0,
        adjustedRecommendations: [],
        topRankedSymbols: [],
        allocationMessage: "Немає акцій для покупки",
      );
    }

    // Сортуємо за девіацією за спаданням (найбільший розрив першим)
    purchaseRecommendations.sort((a, b) => b.deviation.compareTo(a.deviation));

    // Розраховуємо загальну потребу
    final totalIdealBuy = purchaseRecommendations.fold(
      0.0,
      (sum, rec) => sum + rec.amount,
    );

    // Якщо грошей достатньо - повертаємо всі рекомендації
    if (totalIdealBuy <= availableCash) {
      return CashAllocationResult(
        totalIdealBuy: totalIdealBuy,
        availableCash: availableCash,
        cashShortage: 0.0,
        adjustedRecommendations: purchaseRecommendations,
        topRankedSymbols: purchaseRecommendations
            .map((rec) => rec.symbol)
            .toList(),
        allocationMessage: "Достатньо коштів для ідеального розподілу",
      );
    }

    // Розподіляємо кошти пріоритетно
    final adjustedRecommendations = <DCARecommendation>[];
    double remainingCash = availableCash;
    final topSymbols = <String>[];

    for (final recommendation in purchaseRecommendations) {
      if (remainingCash <= 0) break;

      final adjustedAmount = recommendation.amount > remainingCash
          ? remainingCash
          : recommendation.amount;

      adjustedRecommendations.add(
        recommendation.copyWith(
          adjustedAmount: adjustedAmount,
          isCashAdjusted: true,
        ),
      );

      topSymbols.add(recommendation.symbol);
      remainingCash -= adjustedAmount;
    }

    // Формуємо повідомлення
    final topSymbol = purchaseRecommendations.first.symbol;
    final topDeviation = purchaseRecommendations.first.deviation;
    final allocationMessage =
        "На твої ${formatCurrency(availableCash)} я рекомендую купити ${topSymbols.length} акції, щоб закрити найбільші розриви в плані. Спочатку $topSymbol на ${formatCurrency(purchaseRecommendations.first.adjustedAmount)}.";

    return CashAllocationResult(
      totalIdealBuy: totalIdealBuy,
      availableCash: availableCash,
      cashShortage: totalIdealBuy - availableCash,
      adjustedRecommendations: adjustedRecommendations,
      topRankedSymbols: topSymbols,
      allocationMessage: allocationMessage,
    );
  }

  /// Розрахунок CAGR (Compound Annual Growth Rate)
  double calculateCAGR({
    required double initialInvestment,
    required double currentValue,
    required int daysInMarket,
  }) {
    if (daysInMarket <= 0 || initialInvestment <= 0) return 0.0;

    final years = daysInMarket / 365.25;
    final totalReturn = currentValue / initialInvestment;

    return pow(totalReturn, 1.0 / years) - 1.0;
  }

  /// Розрахунок зваженої алокації для акції
  double calculateWeightedAllocation({
    required double stockValue,
    required double totalPortfolioValue,
  }) {
    if (totalPortfolioValue <= 0) return 0.0;
    return stockValue / totalPortfolioValue;
  }

  /// Розрахунок метрик портфоліо
  PortfolioMetrics calculatePortfolioMetrics({
    required List<StockPosition> positions,
    required DateTime startDate,
    required double weeklyTarget,
    required int activeInvestors,
  }) {
    final totalValue = positions.fold(
      0.0,
      (sum, pos) => sum + pos.currentMarketValue,
    );
    final totalCost = positions.fold(0.0, (sum, pos) => sum + pos.totalCost);
    final totalProfit = totalValue - totalCost;
    final profitPercent = totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0;

    final currentDate = DateTime.now();
    final daysInMarket = currentDate.difference(startDate).inDays;

    // Розрахунок CAGR
    final cagr = calculateCAGR(
      initialInvestment: totalCost,
      currentValue: totalValue,
      daysInMarket: daysInMarket,
    );

    // Тижневий цільовий внесок
    final weeklyTargetPerInvestor = weeklyTarget * activeInvestors;

    // Загальна зважена алокація
    final weightedAllocation = positions.isEmpty
        ? 0.0
        : positions
                  .map(
                    (pos) => calculateWeightedAllocation(
                      stockValue: pos.currentMarketValue,
                      totalPortfolioValue: totalValue,
                    ),
                  )
                  .reduce((a, b) => a + b) /
              positions.length;

    return PortfolioMetrics(
      totalValue: totalValue,
      totalCost: totalCost,
      totalProfit: totalProfit,
      profitPercent: profitPercent,
      cagr: cagr,
      daysInMarket: daysInMarket,
      weeklyTarget: weeklyTargetPerInvestor,
      weightedAllocation: weightedAllocation,
      startDate: startDate,
      positions: positions,
    );
  }

  /// Розрахунок чистого прибутку після комісій та податків
  double calculateNetProfit({
    required double grossProfit,
    bool applyCommission = true,
    bool applyTax = true,
  }) {
    double netProfit = grossProfit;

    if (applyCommission) {
      netProfit *= commissionMultiplier;
    }

    if (applyTax && netProfit > 0) {
      netProfit *= (1 - taxRate);
    }

    return netProfit;
  }

  /// Проєкція багатства на 180 місяців
  WealthProjection calculateWealthProjection({
    required double currentValue,
    required double cagr,
    int maxMonths = 180,
  }) {
    final monthlyRate = pow(1 + cagr, 1.0 / 12) - 1.0;
    final projections = <MonthlyProjection>[];

    double projectedValue = currentValue;
    int monthsToMillion = -1;

    for (int month = 1; month <= maxMonths; month++) {
      projectedValue *= (1 + monthlyRate);

      projections.add(
        MonthlyProjection(
          month: month,
          projectedValue: projectedValue,
          monthlyReturn: projectedValue * monthlyRate,
        ),
      );

      if (monthsToMillion == -1 && projectedValue >= targetMillion) {
        monthsToMillion = month;
      }
    }

    return WealthProjection(
      currentValue: currentValue,
      cagr: cagr,
      monthsToMillion: monthsToMillion,
      projectedValue: projectedValue,
      monthlyProjections: projections,
    );
  }

  /// Excel G4/M4 Analytics & Portfolio Hub
  PortfolioAnalytics calculatePortfolioAnalytics({
    required List<StockPosition> positions,
    required DateTime startDate,
    required double availableCash,
  }) {
    final currentDate = DateTime.now();
    final daysInMarket = currentDate.difference(startDate).inDays;

    // Загальна вартість портфоліо
    final totalStockValue = positions.fold(
      0.0,
      (sum, pos) => sum + pos.currentMarketValue,
    );
    final totalPortfolioValue = totalStockValue + availableCash;
    final totalCost = positions.fold(0.0, (sum, pos) => sum + pos.totalCost);

    // Прибуток та відсоток
    final totalProfit = totalStockValue - totalCost;
    final profitPercent = totalCost > 0 ? (totalProfit / totalCost) * 100 : 0.0;

    // Excel G4: CAGR Calculator
    final cagr = calculateCAGR(
      initialInvestment: totalCost,
      currentValue: totalStockValue,
      daysInMarket: daysInMarket,
    );

    // Excel M31: Weighting для кожної акції
    final stockWeightings = <String, double>{};
    for (final position in positions) {
      final weighting = totalPortfolioValue > 0
          ? (position.currentMarketValue / totalPortfolioValue) * 100
          : 0.0;
      stockWeightings[position.symbol] = weighting;
    }

    // Податки та комісії
    final netProfitAfterTax = calculateNetProfit(grossProfit: totalProfit);
    final effectiveCommission = totalProfit * (1 - commissionMultiplier);

    return PortfolioAnalytics(
      totalPortfolioValue: totalPortfolioValue,
      totalStockValue: totalStockValue,
      availableCash: availableCash,
      totalCost: totalCost,
      totalProfit: totalProfit,
      netProfitAfterTax: netProfitAfterTax,
      profitPercent: profitPercent,
      cagr: cagr,
      daysInMarket: daysInMarket,
      stockWeightings: stockWeightings,
      effectiveCommission: effectiveCommission,
    );
  }

  /// Розрахунок здоров'я портфоліо (0-100%)
  PortfolioHealth calculatePortfolioHealth({
    required List<DCARecommendation> recommendations,
  }) {
    if (recommendations.isEmpty) {
      return PortfolioHealth(
        overallPercentage: 0.0,
        totalStocks: 0,
        onTrackStocks: 0,
        laggingStocks: 0,
        overperformingStocks: 0,
      );
    }

    int onTrack = 0;
    int lagging = 0;
    int overperforming = 0;

    for (final recommendation in recommendations) {
      final progress = recommendation.targetValue > 0
          ? (recommendation.currentValue / recommendation.targetValue) * 100
          : 0.0;

      if (progress >= 95 && progress <= 105) {
        onTrack++;
      } else if (progress < 95) {
        lagging++;
      } else {
        overperforming++;
      }
    }

    final overallPercentage = recommendations.isNotEmpty
        ? (onTrack / recommendations.length) * 100
        : 0.0;

    return PortfolioHealth(
      overallPercentage: overallPercentage,
      totalStocks: recommendations.length,
      onTrackStocks: onTrack,
      laggingStocks: lagging,
      overperformingStocks: overperforming,
    );
  }

  /// Розрахунок цільових значень для всіх позицій
  Map<String, double> calculateAllTargetValues({
    required List<StockPosition> positions,
    required DateTime startDate,
  }) {
    final weeksSinceStart = DateTime.now().difference(startDate).inDays / 7.0;
    final targets = <String, double>{};

    for (final position in positions) {
      targets[position.symbol] = weeksSinceStart * weeklyTargetPerStock;
    }

    return targets;
  }

  /// Отримання всіх рекомендацій для 51 акції
  List<DCARecommendation> getAllRecommendations({
    required List<StockPosition> positions,
    required DateTime startDate,
    required double weeklyTarget,
    required int totalStocks,
  }) {
    return calculateAllDeviations(
      positions: positions,
      startDate: startDate,
      weeklyTarget: weeklyTarget,
    );
  }

  /// Cash-Aware Resource Allocation Algorithm (зберігаємо для сумісності)
  CashAllocationResult optimizeCashAllocation({
    required List<DCARecommendation> recommendations,
    required double availableCash,
  }) {
    return priorityCashAllocation(
      allRecommendations: recommendations,
      availableCash: availableCash,
    );
  }

  /// Форматування суми грошей
  String formatCurrency(double amount, {String currency = '\$'}) {
    if (amount >= 1000000) {
      return '$currency${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$currency${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$currency${amount.toStringAsFixed(2)}';
    }
  }

  /// Форматування відсотків
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(2)}%';
  }
}
