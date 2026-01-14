import 'package:xml/xml.dart';

/// Parser for IBKR trade nodes
class IBKRRarser {
  /// Parse a trade node from IBKR XML
  TradeParseResult? parseTradeNode(XmlElement trade) {
    try {
      final priceStr = trade.getAttribute('price') ?? '0';
      final priceCurrency = trade.getAttribute('currency') ?? 'USD';
      final price = double.tryParse(priceStr) ?? 0.0;

      final commissionStr = trade.getAttribute('ibCommission') ?? '0';
      final commissionCurrency = trade.getAttribute('ibCommissionCurrency') ??
          trade.getAttribute('currency') ??
          'USD';
      final commission = double.tryParse(commissionStr) ?? 0.0;

      return TradeParseResult(
        price: CurrencyAmount(amount: price, currency: priceCurrency),
        commission: CurrencyAmount(amount: commission, currency: commissionCurrency),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Result of parsing a trade node
class TradeParseResult {
  final CurrencyAmount price;
  final CurrencyAmount commission;

  TradeParseResult({
    required this.price,
    required this.commission,
  });
}

/// Currency amount with currency code
class CurrencyAmount {
  final double amount;
  final String currency;

  CurrencyAmount({
    required this.amount,
    required this.currency,
  });
}
