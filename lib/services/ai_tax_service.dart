import '../models/ibkr_data.dart';

/// Service for AI-powered tax calculations
class AiTaxService {
  /// Calculate Ukrainian taxes for IBKR reports
  static Future<Map<String, dynamic>> calculateUkrainianTaxes({
    required List<IBKRReport> reports,
    required String taxProfile,
    required double militaryTaxRate,
    required double pitRate,
  }) async {
    try {
      // Aggregate data from all reports
      double totalDividends = 0.0;
      double totalWithheld = 0.0;
      double totalCapitalGains = 0.0;
      double totalLosses = 0.0;

      for (final report in reports) {
        // Calculate dividends
        for (final dividend in report.dividends) {
          totalDividends += dividend.amount;
          totalWithheld += dividend.amount * 0.15; // Assume 15% withholding
        }

        // Calculate capital gains/losses from trades
        for (final trade in report.trades) {
          if (trade.action.toLowerCase().contains('sell')) {
            final profit = trade.cost - (trade.price * trade.quantity);
            if (profit > 0) {
              totalCapitalGains += profit;
            } else {
              totalLosses += profit.abs();
            }
          }
        }
      }

      // Calculate taxes
      final dividendTax = totalDividends * (pitRate + militaryTaxRate);
      final capitalGainsTax = totalCapitalGains * pitRate;
      final totalTax = dividendTax + capitalGainsTax - totalWithheld;

      return {
        'totalDividends': totalDividends,
        'totalWithheld': totalWithheld,
        'totalCapitalGains': totalCapitalGains,
        'totalLosses': totalLosses,
        'dividendTax': dividendTax,
        'capitalGainsTax': capitalGainsTax,
        'totalTax': totalTax,
        'taxProfile': taxProfile,
        'militaryTaxRate': militaryTaxRate,
        'pitRate': pitRate,
      };
    } catch (e) {
      throw Exception('Failed to calculate taxes: $e');
    }
  }
}
