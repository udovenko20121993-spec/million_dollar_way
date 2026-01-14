import 'package:http/http.dart' as http;
import 'dart:convert';

class FinnhubRealService {
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  static const String _apiKey =
      'demo'; // Replace with real API key in production

  static Future<Map<String, double>> getRealTimePrices(
    List<String> symbols,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/quote?symbol=${symbols.join(',')}&token=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, double> prices = {};

        data.forEach((symbol, quoteData) {
          if (quoteData is Map<String, dynamic>) {
            final currentPrice = quoteData['c'] as double? ?? 0.0;
            prices[symbol.toUpperCase()] = currentPrice;
          }
        });

        return prices;
      } else {
        throw Exception('Failed to fetch prices: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data if API fails
      return _getMockPrices(symbols);
    }
  }

  static Future<double> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/forex/rates?pair=$fromCurrency$toCurrency&token=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['rate'] as double? ?? 39.5; // Default USD to UAH
      } else {
        throw Exception(
          'Failed to fetch exchange rate: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Return mock rate if API fails
      return 39.5; // Mock USD to UAH rate
    }
  }

  static Map<String, double> _getMockPrices(List<String> symbols) {
    return {
      'AAPL': 190.50,
      'TSLA': 245.80,
      'MSFT': 380.20,
      'GOOGL': 140.30,
      'NVDA': 485.60,
      'AMZN': 155.40,
      'META': 320.10,
    };
  }

  static Future<Map<String, double>> getCompanyProfile(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stock/profile2?symbol=$symbol&token=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'marketCap':
              (data['marketCapitalization'] as num?)?.toDouble() ?? 0.0,
          'price': (data['price'] as num?)?.toDouble() ?? 0.0,
          'volume': (data['volume24h'] as num?)?.toDouble() ?? 0.0,
        };
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data if API fails
      return _getMockProfile(symbol);
    }
  }

  static Map<String, double> _getMockProfile(String symbol) {
    return {
      'marketCap': 3000000000000.0, // 3T mock market cap
      'price': _getMockPrices([symbol])[symbol] ?? 100.0,
      'volume': 50000000.0, // 50M mock volume
    };
  }
}
