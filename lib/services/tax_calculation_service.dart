import '../domain/models/custom_portfolio_models.dart';
import '../domain/models/user_tax_profile.dart';
import '../models/ibkr_data.dart';

/// Result of yearly tax calculation
class YearlyTaxReport {
  final List<TaxMatch> matches;
  final double estimatedTaxUah;
  final double taxRate;
  final List<String> warnings;

  YearlyTaxReport({
    required this.matches,
    required this.estimatedTaxUah,
    required this.taxRate,
    this.warnings = const [],
  });
}

/// Tax match for FIFO calculation
class TaxMatch {
  final String symbol;
  final DateTime sellDate;
  final double sellPrice;
  final double sellQuantity;
  final double buyPrice;
  final DateTime buyDate;
  final double profitLoss;
  final double taxAmount;

  TaxMatch({
    required this.symbol,
    required this.sellDate,
    required this.sellPrice,
    required this.sellQuantity,
    required this.buyPrice,
    required this.buyDate,
    required this.profitLoss,
    required this.taxAmount,
  });
}

/// Potential tax report for unrealized gains
class PotentialTaxReport {
  final double unrealizedProfitUah;
  final double estimatedTaxUah;
  final double taxRate;
  final List<dynamic> holdings;
  final List<String> warnings;

  PotentialTaxReport({
    required this.unrealizedProfitUah,
    required this.estimatedTaxUah,
    required this.taxRate,
    required this.holdings,
    this.warnings = const [],
  });
}

/// Service for calculating taxes on investment transactions
class TaxCalculationService {
  /// Calculate yearly tax report using FIFO method
  YearlyTaxReport calculateYearlyTaxReport({
    required List<IBKRTrade> trades,
    required int year,
    required UserTaxProfile taxProfile,
  }) {
    // Filter trades for the specified year
    final yearTrades = trades.where((trade) {
      final tradeDate = _parseTradeDate(trade.date);
      return tradeDate?.year == year;
    }).toList();

    // Separate buys and sells
    final buys = <IBKRTrade>[];
    final sells = <IBKRTrade>[];

    for (final trade in yearTrades) {
      final action = trade.action.toLowerCase();
      if (action.contains('buy') || action.contains('purchase')) {
        buys.add(trade);
      } else if (action.contains('sell') || action.contains('sale')) {
        sells.add(trade);
      }
    }

    // Apply FIFO matching
    final matches = <TaxMatch>[];
    final buyQueue = <IBKRTrade>[...buys];

    for (final sell in sells) {
      var remainingQuantity = sell.quantity;
      final sellPrice = sell.price;
      final sellDate = _parseTradeDate(sell.date) ?? DateTime.now();

      while (remainingQuantity > 0 && buyQueue.isNotEmpty) {
        final buy = buyQueue.first;
        final buyPrice = buy.price;
        final buyDate = _parseTradeDate(buy.date) ?? DateTime.now();

        final matchedQuantity = remainingQuantity < buy.quantity
            ? remainingQuantity
            : buy.quantity;

        final profitLoss = (sellPrice - buyPrice) * matchedQuantity;
        final taxRate = _getTaxRate(taxProfile);
        final taxAmount = profitLoss > 0 ? profitLoss * taxRate : 0.0;

        matches.add(TaxMatch(
          symbol: sell.symbol,
          sellDate: sellDate,
          sellPrice: sellPrice,
          sellQuantity: matchedQuantity,
          buyPrice: buyPrice,
          buyDate: buyDate,
          profitLoss: profitLoss,
          taxAmount: taxAmount,
        ));

        remainingQuantity -= matchedQuantity;
        if (matchedQuantity >= buy.quantity) {
          buyQueue.removeAt(0);
        } else {
          // Partial match - create new trade with reduced quantity
          final updatedBuy = IBKRTrade.fromMap({
            'date': buy.date,
            'symbol': buy.symbol,
            'action': buy.action,
            'quantity': buy.quantity - matchedQuantity,
            'price': buy.price,
            'cost': buy.cost * (1 - matchedQuantity / buy.quantity),
            'commission': buy.commission,
          });
          buyQueue[0] = updatedBuy;
        }
      }
    }

    final totalTax = matches.fold<double>(
      0.0,
      (sum, match) => sum + match.taxAmount,
    );

    return YearlyTaxReport(
      matches: matches,
      estimatedTaxUah: totalTax,
      taxRate: _getTaxRate(taxProfile),
      warnings: [],
    );
  }

  double _getTaxRate(UserTaxProfile profile) {
    switch (profile.profile) {
      case TaxProfile.military:
        return 0.05; // 5% for military
      case TaxProfile.fop3:
        return 0.05; // 5% for FOP group 3
      case TaxProfile.civilian:
      default:
        return 0.18; // 18% for civilians
    }
  }

  DateTime? _parseTradeDate(String dateStr) {
    try {
      // Try ISO format first
      if (dateStr.contains('T') || dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      // Try MM/DD/YYYY or DD/MM/YYYY
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
