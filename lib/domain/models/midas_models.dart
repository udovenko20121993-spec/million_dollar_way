enum TransactionType { buy, sell }

class StockTransaction {
  final String symbol;
  final DateTime date;
  final double quantity;
  final double price;
  final TransactionType type;
  final double commission;

  StockTransaction({
    required this.symbol,
    required this.date,
    required this.quantity,
    required this.price,
    required this.type,
    this.commission = 0.0,
  });

  double get totalValue => quantity * price;
}

class StockPosition {
  final String symbol;
  double quantity;
  double averagePrice;
  final List<StockTransaction> transactions;

  StockPosition({
    required this.symbol,
    this.quantity = 0.0,
    this.averagePrice = 0.0,
    this.transactions = const [],
  });

  double get currentMarketValue => quantity * averagePrice;
  double get totalCost =>
      transactions.fold(0.0, (sum, tx) => sum + tx.totalValue);
  double get unrealizedPnL => currentMarketValue - totalCost;
  double get unrealizedPnLPercent =>
      totalCost > 0 ? (unrealizedPnL / totalCost) * 100 : 0.0;
}

class PortfolioMetrics {
  final double totalValue;
  final double totalCost;
  final double totalProfit;
  final double profitPercent;
  final double cagr;
  final int daysInMarket;
  final double weeklyTarget;
  final double weightedAllocation;
  final DateTime startDate;
  final List<StockPosition> positions;
  final double availableCash;

  PortfolioMetrics({
    required this.totalValue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitPercent,
    required this.cagr,
    required this.daysInMarket,
    required this.weeklyTarget,
    required this.weightedAllocation,
    required this.startDate,
    required this.positions,
    this.availableCash = 0.0,
  });
}

class DCARecommendation {
  final String symbol;
  final String action; // "Покупать" або "Продавать"
  final double amount;
  final double deviation;
  final double targetValue;
  final double currentValue;
  final double deviationPercentage;
  final double adjustedAmount; // Скорегована сума з урахуванням cash
  final bool isCashAdjusted;
  final double priority; // Пріоритет для сортування
  final String reason; // Пояснення рекомендації

  DCARecommendation({
    required this.symbol,
    required this.action,
    required this.amount,
    required this.deviation,
    required this.targetValue,
    required this.currentValue,
    this.deviationPercentage = 0.0,
    this.adjustedAmount = 0.0,
    this.isCashAdjusted = false,
    this.priority = 0.0,
    this.reason = '',
  });

  DCARecommendation copyWith({
    String? symbol,
    String? action,
    double? amount,
    double? deviation,
    double? targetValue,
    double? currentValue,
    double? deviationPercentage,
    double? adjustedAmount,
    bool? isCashAdjusted,
    double? priority,
    String? reason,
  }) {
    return DCARecommendation(
      symbol: symbol ?? this.symbol,
      action: action ?? this.action,
      amount: amount ?? this.amount,
      deviation: deviation ?? this.deviation,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      deviationPercentage: deviationPercentage ?? this.deviationPercentage,
      adjustedAmount: adjustedAmount ?? this.adjustedAmount,
      isCashAdjusted: isCashAdjusted ?? this.isCashAdjusted,
      priority: priority ?? this.priority,
      reason: reason ?? this.reason,
    );
  }
}

class CashAllocationResult {
  final double totalIdealBuy;
  final double availableCash;
  final double cashShortage;
  final List<DCARecommendation> adjustedRecommendations;
  final List<String> topRankedSymbols;
  final String allocationMessage;

  CashAllocationResult({
    required this.totalIdealBuy,
    required this.availableCash,
    required this.cashShortage,
    required this.adjustedRecommendations,
    required this.topRankedSymbols,
    required this.allocationMessage,
  });
}

class PortfolioAnalytics {
  final double totalPortfolioValue;
  final double totalStockValue;
  final double availableCash;
  final double totalCost;
  final double totalProfit;
  final double netProfitAfterTax;
  final double profitPercent;
  final double cagr;
  final int daysInMarket;
  final Map<String, double> stockWeightings;
  final double effectiveCommission;

  PortfolioAnalytics({
    required this.totalPortfolioValue,
    required this.totalStockValue,
    required this.availableCash,
    required this.totalCost,
    required this.totalProfit,
    required this.netProfitAfterTax,
    required this.profitPercent,
    required this.cagr,
    required this.daysInMarket,
    required this.stockWeightings,
    required this.effectiveCommission,
  });
}

class PortfolioHealth {
  final double overallPercentage;
  final int totalStocks;
  final int onTrackStocks;
  final int laggingStocks;
  final int overperformingStocks;

  PortfolioHealth({
    required this.overallPercentage,
    required this.totalStocks,
    required this.onTrackStocks,
    required this.laggingStocks,
    required this.overperformingStocks,
  });
}

class WealthProjection {
  final double currentValue;
  final double cagr;
  final int monthsToMillion;
  final double projectedValue;
  final List<MonthlyProjection> monthlyProjections;

  WealthProjection({
    required this.currentValue,
    required this.cagr,
    required this.monthsToMillion,
    required this.projectedValue,
    required this.monthlyProjections,
  });
}

class MonthlyProjection {
  final int month;
  final double projectedValue;
  final double monthlyReturn;

  MonthlyProjection({
    required this.month,
    required this.projectedValue,
    required this.monthlyReturn,
  });
}
