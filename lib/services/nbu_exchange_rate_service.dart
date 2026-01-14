import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for fetching NBU (National Bank of Ukraine) exchange rates
class NbuExchangeRateService {
  static const String _baseUrl = 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange';

  /// Result of NBU rate fetch
  class NbuRateResult {
    final double rate;
    final DateTime date;
    final String currency;

    NbuRateResult({
      required this.rate,
      required this.date,
      required this.currency,
    });
  }

  /// Try to get exchange rate to UAH for a given currency and date
  Future<NbuRateResult?> tryGetRateToUah(
    String currency,
    DateTime date,
  ) async {
    try {
      // Format date as YYYYMMDD
      final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      
      // For USD, EUR, and other common currencies
      final currencyCode = _getCurrencyCode(currency);
      
      final url = Uri.parse('$_baseUrl?valcode=$currencyCode&date=$dateStr&json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final rateData = data.first;
          final rate = (rateData['rate'] as num?)?.toDouble() ?? 0.0;
          
          return NbuRateResult(
            rate: rate,
            date: date,
            currency: currency,
          );
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert currency symbol to NBU currency code
  String _getCurrencyCode(String currency) {
    final upper = currency.toUpperCase();
    switch (upper) {
      case 'USD':
        return 'USD';
      case 'EUR':
        return 'EUR';
      case 'GBP':
        return 'GBP';
      case 'PLN':
        return 'PLN';
      default:
        return upper;
    }
  }
}
