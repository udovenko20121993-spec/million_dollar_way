import 'dart:math' as math;

import 'package:million_dollar_way/core/constants/app_constants.dart';

import '../data/remote/firestore_service.dart';
import '../domain/models/custom_portfolio_models.dart';
import '../domain/models/ibkr_data.dart';
import 'tax_profile_service.dart';
import 'univer_service.dart';

class InvestmentLogicService {
  final FirestoreService _firestoreService;
  final TaxProfileService _taxProfileService;
  final UniverService _univerService;

  InvestmentLogicService({
    FirestoreService? firestoreService,
    TaxProfileService? taxProfileService,
    UniverService? univerService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _taxProfileService = taxProfileService ?? TaxProfileService.instance,
       _univerService = univerService ?? UniverService();

  Future<InvestmentSnapshot?> processIbkrData(String userId) async {
    print('InvestmentLogicService: processing IBKR data for $userId');
    final report = await _firestoreService.getLatestReport(userId);
    if (report == null) {
      print('InvestmentLogicService: no report found for $userId');
      return null;
    }
    print(
      'InvestmentLogicService: report ${report.id} loaded. Positions=${report.positions.length}',
    );

    final accountInfo = report.accountInfo ?? _fallbackAccountInfo(report);
    print(
      'InvestmentLogicService: using account ${accountInfo.accountNumber} (${accountInfo.baseCurrency})',
    );

    final processedTransactions = _deriveProcessedTransactions(
      report.trades,
      report.cashTransactions,
    );
    final processedDividends = _deriveProcessedDividends(report.dividends);
    print(
      'InvestmentLogicService: processed ${processedTransactions.length} transactions, ${processedDividends.length} dividends',
    );

    final univerAssets = await _loadUniverAssets(userId);

    final summary = _calculateAccountSummary(
      accountInfo,
      processedTransactions,
      processedDividends,
      report.positions,
      univerAssets,
    );
    print(
      'InvestmentLogicService: summary currentBalance=${summary.currentBalance}, totalInvested=${summary.totalInvested}, totalPnL=${summary.totalProfitLoss}',
    );

    final strategyMode = _taxProfileService.getInvestmentStrategyMode();
    final firstTradeDate = _resolveFirstTradeDate(
      processedTransactions,
      accountInfo.openedDate,
    );

    final portfolioAssets = _calculatePortfolioAssets(
      positions: report.positions,
      accountSummary: summary,
      firstTradeDate: firstTradeDate,
      weeklyTargetAmount: summary.weeklyTargetAmount,
      strategyMode: strategyMode,
      dividends: processedDividends,
    );

    return InvestmentSnapshot(
      accountSummary: summary,
      transactions: processedTransactions,
      dividends: processedDividends,
      assets: portfolioAssets,
      univerAssets: univerAssets,
    );
  }

  Future<List<UniverAsset>> _loadUniverAssets(String userId) async {
    try {
      final assets = await _univerService.getUniverAssets(userId);
      print(
        'InvestmentLogicService: loaded ${assets.length} Univer assets for $userId',
      );
      return assets;
    } catch (e) {
      print('InvestmentLogicService: failed to load Univer assets: $e');
      return [];
    }
  }

  IBKRAccountInfo _fallbackAccountInfo(IBKRReport report) {
    return IBKRAccountInfo(
      accountNumber: report.id,
      baseCurrency: 'USD',
      openedDate: report.uploadDate,
    );
  }

  List<ProcessedTransaction> _deriveProcessedTransactions(
    List<IBKRTrade> trades,
    List<IBKRCashTransaction> cashTransactions,
  ) {
    final transactions = <ProcessedTransaction>[];

    for (final trade in trades) {
      final parsedDate = trade.date;
      final action = trade.action.toUpperCase();
      final isBuy = action == 'BUY' || action == 'BOT';

      transactions.add(
        ProcessedTransaction(
          operationType: isBuy ? 'Покупка' : 'Продажа',
          assetSymbol: trade.symbol,
          date: parsedDate,
          quantity: trade.quantity,
          price: trade.price,
          commission: trade.commission,
          totalAmount: trade.cost,
          profitLossOnTrade: 0.0,
        ),
      );
    }

    for (final tx in cashTransactions) {
      final type = tx.type.toLowerCase();
      final description = tx.description.toLowerCase();
      String operationType = 'Кеш';

      if (type.contains('deposit') || type.contains('transfer')) {
        operationType = 'Подарок';
      } else if (type.contains('withdrawal')) {
        operationType = 'Виведення';
      } else if (description.contains('commission') || type.contains('fee')) {
        operationType = 'Комиссия';
      }

      transactions.add(
        ProcessedTransaction(
          operationType: operationType,
          assetSymbol: tx.currency,
          date: tx.date,
          totalAmount: tx.amount,
          notes: tx.description,
        ),
      );
    }

    return transactions;
  }

  List<ProcessedDividend> _deriveProcessedDividends(
    List<IBKRDividend> dividends,
  ) {
    return dividends
        .map(
          (div) => ProcessedDividend(
            assetSymbol: div.symbol,
            date: div.date,
            grossAmount: div.grossAmount,
            taxWithheld: div.withholdingTax,
          ),
        )
        .toList();
  }

  AccountSummary _calculateAccountSummary(
    IBKRAccountInfo info,
    List<ProcessedTransaction> transactions,
    List<ProcessedDividend> dividends,
    List<IBKRPosition> positions,
    List<UniverAsset> univerAssets,
  ) {
    final summary = AccountSummary(
      accountNumber: info.accountNumber,
      baseCurrency: info.baseCurrency,
      openedDate: info.openedDate,
    );

    summary.currentBalance = positions.fold<double>(
      0,
      (sum, pos) => sum + pos.marketValue,
    );
    print(
      'InvestmentLogicService:_calculateAccountSummary: currentBalance = ${summary.currentBalance}',
    );

    summary.totalInvested = positions.fold<double>(
      0,
      (sum, pos) => sum + (pos.quantity * pos.averageCost),
    );
    print(
      'InvestmentLogicService:_calculateAccountSummary: totalInvested (positions) = ${summary.totalInvested}',
    );

    final commissionImpact = transactions
        .where((tx) => tx.operationType == 'Комиссия')
        .fold<double>(0, (sum, tx) => sum + tx.totalAmount.abs());
    summary.totalInvested += commissionImpact;
    print(
      'InvestmentLogicService:_calculateAccountSummary: commissionImpact=$commissionImpact, totalInvested=${summary.totalInvested}',
    );

    final univerCurrentBalance = univerAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentMarketValue,
    );
    final univerInvested = univerAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.initialInvestment,
    );
    summary.currentBalance += univerCurrentBalance;
    summary.totalInvested += univerInvested;
    print(
      'InvestmentLogicService:_calculateAccountSummary: univerAssets currentBalanceContribution=$univerCurrentBalance, invested=$univerInvested',
    );

    summary.totalProfitLoss = summary.currentBalance - summary.totalInvested;
    print(
      'InvestmentLogicService:_calculateAccountSummary: totalProfitLoss=${summary.totalProfitLoss}',
    );

    final firstTradeDate = _resolveFirstTradeDate(
      transactions,
      info.openedDate,
    );
    final daysInvested = math.max(
      1,
      DateTime.now().difference(firstTradeDate).inDays,
    );

    if (summary.totalInvested > 0) {
      final growthFactor =
          1 + (summary.totalProfitLoss / summary.totalInvested);
      if (growthFactor > 0) {
        summary.totalYieldPercentage =
            (math.pow(growthFactor, 365.25 / daysInvested) - 1) * 100;
      }
    }

    final cutoffDate = DateTime.now().subtract(const Duration(days: 365));
    double netDividendsLastYear = dividends
        .where((div) => div.date.isAfter(cutoffDate))
        .fold<double>(0, (sum, div) => sum + div.netAmount);

    final univerPassiveIncome = univerAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.totalDividendsPaid,
    );
    summary.totalPassiveIncome = netDividendsLastYear + univerPassiveIncome;

    if (summary.currentBalance > 0) {
      summary.annualPassiveIncomePercentage =
          (summary.totalPassiveIncome / summary.currentBalance) * 100;
    }
    print(
      'InvestmentLogicService:_calculateAccountSummary: netDividendsLastYear=$netDividendsLastYear, univerPassiveIncome=$univerPassiveIncome, annualPassiveIncome%=${summary.annualPassiveIncomePercentage}',
    );

    summary.weeklyTargetAmount =
        summary.totalInvested /
        AppConstants.weeklyTargetDivisor.clamp(1.0, double.infinity);
    print(
      'InvestmentLogicService:_calculateAccountSummary: weeklyTargetAmount=${summary.weeklyTargetAmount}',
    );

    return summary;
  }

  List<PortfolioAsset> _calculatePortfolioAssets({
    required List<IBKRPosition> positions,
    required AccountSummary accountSummary,
    required DateTime firstTradeDate,
    required double weeklyTargetAmount,
    required String strategyMode,
    required List<ProcessedDividend> dividends,
  }) {
    final assets = <PortfolioAsset>[];
    final dividendsBySymbol = <String, double>{};

    for (final div in dividends) {
      dividendsBySymbol.update(
        div.assetSymbol.toUpperCase(),
        (value) => value + div.netAmount,
        ifAbsent: () => div.netAmount,
      );
    }

    for (final position in positions) {
      final asset = PortfolioAsset(symbol: position.symbol);
      asset.currentQuantity = position.quantity;
      asset.averageCost = position.averageCost;
      asset.marketValue = position.marketValue;
      asset.unrealizedPnl = position.unrealizedPnl;
      asset.investedAmount = position.quantity * position.averageCost;

      final pricePerShare = asset.currentQuantity.abs() > 0
          ? asset.marketValue / asset.currentQuantity
          : asset.averageCost;

      if (asset.investedAmount > 0) {
        asset.totalProfitLossPercent =
            (asset.unrealizedPnl / asset.investedAmount) * 100;
      }

      if (accountSummary.currentBalance > 0) {
        asset.portfolioShare =
            asset.marketValue / accountSummary.currentBalance;
      }

      final dividendsForSymbol =
          dividendsBySymbol[asset.symbol.toUpperCase()] ?? 0.0;
      if (asset.marketValue > 0) {
        asset.dividendYield = (dividendsForSymbol / asset.marketValue) * 100;
      }

      final recommendation = _calculateRecommendationForAsset(
        asset: asset,
        accountSummary: accountSummary,
        firstTradeDate: firstTradeDate,
        weeklyTargetAmount: weeklyTargetAmount,
        strategyMode: strategyMode,
        pricePerShare: pricePerShare,
      );

      asset.recommendedAction = recommendation.action;
      asset.actionQuantity = recommendation.quantity;

      assets.add(asset);
    }

    return assets;
  }

  _RecommendationResult _calculateRecommendationForAsset({
    required PortfolioAsset asset,
    required AccountSummary accountSummary,
    required DateTime firstTradeDate,
    required double weeklyTargetAmount,
    required String strategyMode,
    required double pricePerShare,
  }) {
    if (pricePerShare <= 0) {
      return const _RecommendationResult('Нейтрально', 0.0);
    }

    const totalAssets = AppConstants.totalNumberOfCoreAssets;
    const threshold = AppConstants.recommendationThreshold;

    final daysSinceFirstTrade = DateTime.now()
        .difference(firstTradeDate)
        .inDays;
    final weeksSinceFirstTrade = (daysSinceFirstTrade / 7).round();

    final targetInvestedPerAsset =
        (weeksSinceFirstTrade * weeklyTargetAmount) / totalAssets;
    final delta = asset.marketValue - targetInvestedPerAsset;

    String action = 'Нейтрально';
    double quantity = 0.0;

    if (strategyMode == 'Ребаланс') {
      final targetMarketValue =
          accountSummary.currentBalance / totalAssets.clamp(1, totalAssets);
      final rebalanceDelta = asset.marketValue - targetMarketValue;

      if (rebalanceDelta < -threshold) {
        action = 'Купити';
        quantity = (rebalanceDelta.abs() / pricePerShare).floorToDouble();
      } else if (rebalanceDelta > threshold) {
        action = 'Продати';
        quantity = (rebalanceDelta / pricePerShare).floorToDouble();
      }

      return _RecommendationResult(action, math.max(0, quantity));
    }

    if (asset.totalProfitLossPercent < 0 && delta < -threshold) {
      action = 'Купити';
      quantity = (delta.abs() / pricePerShare).floorToDouble();
    } else if (asset.totalProfitLossPercent >= 0 && delta > threshold) {
      action = 'Нейтрально';
      quantity = 0.0;
    }

    return _RecommendationResult(action, math.max(0, quantity));
  }

  DateTime _resolveFirstTradeDate(
    List<ProcessedTransaction> transactions,
    DateTime fallback,
  ) {
    final tradeDates = transactions
        .where(
          (tx) =>
              tx.operationType == 'Покупка' || tx.operationType == 'Продажа',
        )
        .map((tx) => tx.date)
        .toList();

    if (tradeDates.isEmpty) {
      return fallback;
    }

    tradeDates.sort();
    return tradeDates.first;
  }
}

class _RecommendationResult {
  final String action;
  final double quantity;

  const _RecommendationResult(this.action, this.quantity);
}
