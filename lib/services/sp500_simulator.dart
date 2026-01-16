import 'dart:collection';
import 'dart:math';

import 'package:million_dollar_way/models/ibkr_data.dart';
import 'package:million_dollar_way/services/sp500_service.dart';

class Sp500SimulationResult {
  final double sp500ValueNow;
  final double netInvested;

  const Sp500SimulationResult({
    required this.sp500ValueNow,
    required this.netInvested,
  });
}

class Sp500Simulator {
  final Sp500Service _service;

  Sp500Simulator(this._service);

  /// Simulates "invest the same trade cash-flows into S&P500".
  ///
  /// BUY: invest (price * |qty| + commission)
  /// SELL: withdraw (price * |qty| - commission)
  ///
  /// Returns current hypothetical value based on latest available S&P500 close.
  Sp500SimulationResult simulate({
    required List<IBKRTrade> trades,
    required SplayTreeMap<DateTime, double> sp500DailyClose,
  }) {
    if (trades.isEmpty || sp500DailyClose.isEmpty) {
      return const Sp500SimulationResult(sp500ValueNow: 0, netInvested: 0);
    }

    final sorted = List<IBKRTrade>.from(trades);
    sorted.sort((a, b) => _parseIbkrDate(a.date).compareTo(_parseIbkrDate(b.date)));

    double shares = 0;
    double netInvested = 0;

    for (final trade in sorted) {
      final action = trade.action.toUpperCase();
      final date = _parseIbkrDate(trade.date);
      final spClose = _service.closeOnOrBefore(sp500DailyClose, date);
      if (spClose == null || spClose <= 0) continue;

      final gross = trade.price * trade.quantity.abs();
      final commission = trade.commission;

      if (action.contains('BUY')) {
        final invest = max(0, gross + commission);
        netInvested += invest;
        shares += invest / spClose;
      } else if (action.contains('SELL')) {
        final withdraw = max(0, gross - commission);
        netInvested -= withdraw;
        // Can't withdraw more than current position value.
        final maxWithdrawShares = shares;
        final withdrawShares = min(maxWithdrawShares, withdraw / spClose);
        shares -= withdrawShares;
      }
    }

    final latestClose = sp500DailyClose[sp500DailyClose.lastKey()]!;
    final valueNow = shares * latestClose;

    return Sp500SimulationResult(
      sp500ValueNow: valueNow,
      netInvested: netInvested,
    );
  }

  static DateTime _parseIbkrDate(String dateStr) {
    // IBKR: 20250121 or 20250121;153020
    final clean = dateStr.contains(';') ? dateStr.split(';').first : dateStr;
    if (clean.length == 8) {
      final yyyy = clean.substring(0, 4);
      final mm = clean.substring(4, 6);
      final dd = clean.substring(6, 8);
      final parsed = DateTime.tryParse('$yyyy-$mm-$dd');
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    final fallback = DateTime.tryParse(clean);
    if (fallback != null) return DateTime(fallback.year, fallback.month, fallback.day);
    return DateTime.now();
  }
}

