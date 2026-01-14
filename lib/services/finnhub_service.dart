import 'package:http/http.dart' as http;
import 'dart:convert';
import 'finnhub_real_service.dart';

/// Service wrapper for Finnhub API
class FinnhubService {
  final FinnhubRealService _realService = FinnhubRealService();

  /// Get quotes for multiple tickers
  Future<Map<String, Map<String, dynamic>>> getQuotes(
    List<String> tickers,
  ) async {
    try {
      final prices = await _realService.getRealTimePrices(tickers);
      final quotes = <String, Map<String, dynamic>>{};
      
      for (final ticker in tickers) {
        final price = prices[ticker.toUpperCase()] ?? 0.0;
        quotes[ticker] = {
          'c': price, // current price
          'pc': price, // previous close (using current as fallback)
          'h': price, // high (using current as fallback)
          'l': price, // low (using current as fallback)
          'o': price, // open (using current as fallback)
        };
      }
      
      return quotes;
    } catch (e) {
      return {};
    }
  }

  /// Get real-time prices
  Future<Map<String, double>> getRealTimePrices(List<String> symbols) {
    return _realService.getRealTimePrices(symbols);
  }
}
