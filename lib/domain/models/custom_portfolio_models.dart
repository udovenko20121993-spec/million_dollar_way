/// Агрегована інформація про рахунок Олександра
class AccountSummary {
  final String accountNumber;
  final String baseCurrency;
  final DateTime openedDate;
  double totalInvested;
  double currentBalance;
  double totalProfitLoss;
  double totalYieldPercentage;
  double annualPassiveIncomePercentage;
  double weeklyTargetAmount;
  double totalPassiveIncome;

  AccountSummary({
    required this.accountNumber,
    required this.baseCurrency,
    required this.openedDate,
    this.totalInvested = 0.0,
    this.currentBalance = 0.0,
    this.totalProfitLoss = 0.0,
    this.totalYieldPercentage = 0.0,
    this.annualPassiveIncomePercentage = 0.0,
    this.weeklyTargetAmount = 0.0,
    this.totalPassiveIncome = 0.0,
  });
}

/// Збагачена транзакція з урахуванням комісій та нотаток
class ProcessedTransaction {
  final String operationType;
  final String assetSymbol;
  final DateTime date;
  final double quantity;
  final double price;
  final double commission;
  final double totalAmount;
  final double profitLossOnTrade;
  final String notes;

  const ProcessedTransaction({
    required this.operationType,
    required this.assetSymbol,
    required this.date,
    this.quantity = 0.0,
    this.price = 0.0,
    this.commission = 0.0,
    required this.totalAmount,
    this.profitLossOnTrade = 0.0,
    this.notes = '',
  });
}

/// Нарахування дивідендів з податковою інформацією
class ProcessedDividend {
  final String assetSymbol;
  final DateTime date;
  final double grossAmount;
  final double taxWithheld;
  late final double netAmount;

  ProcessedDividend({
    required this.assetSymbol,
    required this.date,
    required this.grossAmount,
    required this.taxWithheld,
  }) {
    netAmount = grossAmount - taxWithheld;
  }
}

/// Модель однієї позиції в портфелі (одна з 50 акцій)
class PortfolioAsset {
  final String symbol;
  double currentQuantity;
  double averageCost;
  double investedAmount;
  double marketValue;
  double unrealizedPnl;
  double dailyChangePercent;
  double totalProfitLossPercent;
  double portfolioShare;
  String recommendedAction;
  double actionQuantity;
  double dividendYield;

  PortfolioAsset({
    required this.symbol,
    this.currentQuantity = 0.0,
    this.averageCost = 0.0,
    this.investedAmount = 0.0,
    this.marketValue = 0.0,
    this.unrealizedPnl = 0.0,
    this.dailyChangePercent = 0.0,
    this.totalProfitLossPercent = 0.0,
    this.portfolioShare = 0.0,
    this.recommendedAction = '',
    this.actionQuantity = 0.0,
    this.dividendYield = 0.0,
  });
}

class InvestmentSnapshot {
  final AccountSummary accountSummary;
  final List<ProcessedTransaction> transactions;
  final List<ProcessedDividend> dividends;
  final List<PortfolioAsset> assets;
  final List<UniverAsset> univerAssets;

  const InvestmentSnapshot({
    required this.accountSummary,
    required this.transactions,
    required this.dividends,
    required this.assets,
    this.univerAssets = const [],
  });
}

enum UniverAssetType { ovdp, stock, other }

class UniverAsset {
  final String id;
  final String name;
  final String symbol;
  final UniverAssetType type;
  double initialInvestment;
  DateTime purchaseDate;
  DateTime? maturityDate;
  double nominalValue;
  double couponRate;
  double currentMarketValue;
  double accruedInterest;
  double totalDividendsPaid;
  bool belongsToDaughter;

  UniverAsset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.initialInvestment,
    required this.purchaseDate,
    this.maturityDate,
    this.nominalValue = 0.0,
    this.couponRate = 0.0,
    required this.currentMarketValue,
    this.accruedInterest = 0.0,
    this.totalDividendsPaid = 0.0,
    this.belongsToDaughter = false,
  });

  factory UniverAsset.fromFirestore(Map<String, dynamic> data) {
    return UniverAsset(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      symbol: data['symbol']?.toString() ?? '',
      type: _parseType(data['type']),
      initialInvestment: (data['initialInvestment'] as num?)?.toDouble() ?? 0.0,
      purchaseDate:
          DateTime.tryParse(data['purchaseDate']?.toString() ?? '') ??
          DateTime.now(),
      maturityDate: data['maturityDate'] != null
          ? DateTime.tryParse(data['maturityDate'].toString())
          : null,
      nominalValue: (data['nominalValue'] as num?)?.toDouble() ?? 0.0,
      couponRate: (data['couponRate'] as num?)?.toDouble() ?? 0.0,
      currentMarketValue:
          (data['currentMarketValue'] as num?)?.toDouble() ?? 0.0,
      accruedInterest: (data['accruedInterest'] as num?)?.toDouble() ?? 0.0,
      totalDividendsPaid:
          (data['totalDividendsPaid'] as num?)?.toDouble() ?? 0.0,
      belongsToDaughter: data['belongsToDaughter'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'type': type.name,
      'initialInvestment': initialInvestment,
      'purchaseDate': purchaseDate.toIso8601String(),
      'maturityDate': maturityDate?.toIso8601String(),
      'nominalValue': nominalValue,
      'couponRate': couponRate,
      'currentMarketValue': currentMarketValue,
      'accruedInterest': accruedInterest,
      'totalDividendsPaid': totalDividendsPaid,
      'belongsToDaughter': belongsToDaughter,
    };
  }

  static UniverAssetType _parseType(dynamic raw) {
    final value = raw?.toString().toLowerCase();
    switch (value) {
      case 'ovdp':
      case 'ovdd':
      case 'ovdp_bond':
        return UniverAssetType.ovdp;
      case 'stock':
        return UniverAssetType.stock;
      default:
        return UniverAssetType.other;
    }
  }
}
