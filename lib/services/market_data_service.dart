import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:million_dollar_way/core/api_keys.dart';

class MarketDataService {
  static MarketDataService? _instance;
  static MarketDataService get instance => _instance ??= MarketDataService._();

  MarketDataService._();

  // Кеш для зберігання цін
  final Map<String, double> _priceCache = {};
  final Map<String, DateTime> _lastUpdate = {};
  final Map<String, double> _dailyChangeCache =
      {}; // Новий кеш для щоденної зміни

  // Кешовані ціни для демо-режиму (без API викликів)
  static const Map<String, double> _demoPrices = {
    'AAPL': 190.0,
    'TSLA': 240.0,
    'MSFT': 380.0,
    'GOOGL': 140.0,
    'AMZN': 155.0,
    'NVDA': 480.0,
    'META': 350.0,
    'BRK.B': 370.0,
    'JNJ': 160.0,
    'V': 260.0,
    'JPM': 155.0,
    'UNH': 480.0,
    'PG': 155.0,
    'MA': 380.0,
    'HD': 340.0,
    'CVX': 115.0,
    'LLY': 580.0,
    'PEP': 170.0,
    'COST': 540.0,
    'ABBV': 140.0,
    'TMO': 580.0,
    'AVGO': 850.0,
    'WMT': 165.0,
    'MCD': 280.0,
    'DHR': 270.0,
    'VZ': 40.0,
    'ADBE': 580.0,
    'CRM': 240.0,
    'NFLX': 470.0,
    'KO': 60.0,
    'NKE': 120.0,
    'ABT': 105.0,
    'ORCL': 115.0,
    'ACN': 320.0,
    'XOM': 110.0,
    'NEE': 85.0,
    'LIN': 230.0,
    'TXN': 165.0,
    'UNP': 250.0,
    'BAC': 35.0,
    'WFC': 45.0,
    'PM': 105.0,
    'AMGN': 280.0,
    'HON': 200.0,
    'UPS': 150.0,
    'CAT': 280.0,
    'GE': 140.0,
    'SCHW': 70.0,
    'RTX': 120.0,
    'INTC': 45.0,
    'QCOM': 160.0,
    'LMT': 460.0,
    'BA': 210.0,
    'AMD': 120.0,
    'PLD': 120.0,
    'GS': 380.0,
  };

  // Кешовані щоденні зміни для демо-режиму
  static const Map<String, double> _demoDailyChanges = {
    'AAPL': 2.3,
    'TSLA': -1.8,
    'MSFT': 1.2,
    'GOOGL': 0.8,
    'AMZN': 3.1,
    'NVDA': 4.5,
    'META': -2.1,
    'BRK.B': 0.5,
    'JNJ': -0.3,
    'V': 1.8,
    'JPM': 2.7,
    'UNH': -1.2,
    'PG': 0.9,
    'MA': 1.5,
    'HD': 2.2,
    'CVX': -3.4,
    'LLY': 3.8,
    'PEP': -0.7,
    'COST': 1.1,
    'ABBV': -1.5,
    'TMO': 2.9,
    'AVGO': 5.2,
    'WMT': 0.3,
    'MCD': 1.7,
    'DHR': -0.8,
    'VZ': -2.3,
    'ADBE': 3.6,
    'CRM': -1.9,
    'NFLX': 2.4,
    'KO': -0.5,
    'NKE': 1.3,
    'ABT': 0.6,
    'ORCL': -1.1,
    'ACN': 2.0,
    'XOM': -2.8,
    'NEE': 0.4,
    'LIN': 1.6,
    'TXN': -0.9,
    'UNP': 1.4,
    'BAC': -1.7,
    'WFC': 0.2,
    'PM': -0.4,
    'AMGN': 2.1,
    'HON': -1.3,
    'UPS': 0.8,
    'CAT': 3.3,
    'GE': -2.5,
    'SCHW': -1.6,
    'RTX': 1.9,
    'INTC': -3.1,
    'QCOM': 2.7,
    'LMT': 0.7,
    'BA': -2.2,
    'AMD': 4.1,
    'PLD': -0.6,
    'GS': 1.8,
  };

  // Кеш для контролю швидкості запитів
  DateTime? _lastRequestTime;
  int _requestCount = 0;

  /// Ініціалізація сервісу (без автоматичного завантаження)
  Future<void> init() async {
    try {
      print('MarketDataService initialized - ready for lazy loading');
      // НЕ завантажуємо всі 51 символ автоматично
      // Завантаження відбувається тільки за запитом
    } catch (e) {
      print('Error initializing MarketDataService: $e');
    }
  }

  /// Отримання демо-ціни (без API виклику)
  double getDemoPrice(String symbol) {
    return _demoPrices[symbol] ?? 100.0; // Default $100 if not found
  }

  /// Отримання демо-щоденної зміни (без API виклику)
  double getDemoDailyChange(String symbol) {
    return _demoDailyChanges[symbol] ?? 0.0; // Default 0% if not found
  }

  /// Отримання поточної ціни для одного символу (Lazy Loading)
  Future<double?> getCurrentPrice(String symbol) async {
    // Спочатку перевіряємо демо-ціни
    if (_demoPrices.containsKey(symbol)) {
      return getDemoPrice(symbol);
    }

    // Перевіряємо кеш (оновлюємо не частіше ніж раз на 30 секунд)
    if (_priceCache.containsKey(symbol) &&
        _lastUpdate.containsKey(symbol) &&
        DateTime.now().difference(_lastUpdate[symbol]!).inSeconds < 30) {
      return _priceCache[symbol];
    }

    // Контроль швидкості запитів
    await _respectRateLimit();

    try {
      final url = Uri.parse(
        '${ApiKeys.finnhubBaseUrl}/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'MillionDollarWay/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final currentPrice = (data['c'] as num?)?.toDouble();
        final dailyChange = (data['dp'] as num?)
            ?.toDouble(); // dp field - daily percentage change

        if (currentPrice != null && currentPrice > 0) {
          _priceCache[symbol] = currentPrice;
          _lastUpdate[symbol] = DateTime.now();

          // Зберігаємо щоденну зміну
          if (dailyChange != null) {
            _dailyChangeCache[symbol] = dailyChange;
          }

          return currentPrice;
        }
      } else if (response.statusCode == 429) {
        print('Rate limit exceeded for $symbol');
        await Future.delayed(const Duration(seconds: 60));
        return null;
      }
    } catch (e) {
      print('Error fetching price for $symbol: $e');
      return null;
    }

    return null;
  }

  /// Отримання щоденної зміни для символу
  double getDailyChange(String symbol) {
    // Спочатку перевіряємо демо-дані
    if (_demoDailyChanges.containsKey(symbol)) {
      return getDemoDailyChange(symbol);
    }

    // Повертаємо з кешу
    return _dailyChangeCache[symbol] ?? 0.0;
  }

  /// Отримання всіх 51 символів для дайджесту
  Future<Map<String, double>> getAllDailyChanges() async {
    final Map<String, double> allChanges = {};

    // Використовуємо демо-дані для швидкості
    for (final symbol in _demoDailyChanges.keys) {
      allChanges[symbol] = getDailyChange(symbol);
    }

    return allChanges;
  }

  /// Отримання цін для всіх 51 символів з batching
  Future<Map<String, double>> getAllCurrentPrices() async {
    final prices = <String, double>{};
    final futures = <Future<void>>[];

    print('Fetching prices for ${ApiKeys.targetSymbols.length} symbols...');

    // Створюємо batch запити з затримкою
    for (final symbol in ApiKeys.targetSymbols) {
      futures.add(_fetchPriceWithDelay(symbol, prices));

      // Додаємо невелику затримку між запитами
      if (futures.length >= 5) {
        await Future.wait(futures);
        futures.clear();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // Завершуємо останні запити
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    print('Successfully fetched ${prices.length} prices');
    return prices;
  }

  /// Допоміжний метод для отримання ціни з затримкою
  Future<void> _fetchPriceWithDelay(
    String symbol,
    Map<String, double> prices,
  ) async {
    await _respectRateLimit();

    final price = await getCurrentPrice(symbol);
    if (price != null) {
      prices[symbol] = price;
    }
  }

  /// Контроль швидкості запитів
  Future<void> _respectRateLimit() async {
    final now = DateTime.now();

    if (_lastRequestTime == null) {
      _lastRequestTime = now;
      _requestCount = 1;
      return;
    }

    final timeSinceLastRequest = now.difference(_lastRequestTime!);

    // Якщо пройшла хвилина, скидаємо лічильник
    if (timeSinceLastRequest.inMinutes >= 1) {
      _lastRequestTime = now;
      _requestCount = 1;
      return;
    }

    // Якщо досягли ліміту, чекаємо
    if (_requestCount >= ApiKeys.maxRequestsPerMinute) {
      final waitTime = 60 - timeSinceLastRequest.inSeconds;
      if (waitTime > 0) {
        print('Rate limit reached, waiting $waitTime seconds...');
        await Future.delayed(Duration(seconds: waitTime));
      }
      _lastRequestTime = DateTime.now();
      _requestCount = 1;
    } else {
      // Невелика затримка між запитами
      await Future.delayed(
        const Duration(milliseconds: ApiKeys.requestDelayMs),
      );
      _requestCount++;
    }
  }

  /// Отримання статистики портфоліо
  Map<String, dynamic> getPortfolioStats() {
    return {
      'totalSymbols': _priceCache.length,
      'lastUpdate': _lastUpdate.isNotEmpty
          ? _lastUpdate.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
      'oldestUpdate': _lastUpdate.isNotEmpty
          ? _lastUpdate.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'requestCount': _requestCount,
    };
  }

  /// Перевірка чи дані свіжі
  bool isDataFresh() {
    if (_lastUpdate.isEmpty) return false;

    final oldestUpdate = _lastUpdate.values.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );
    return DateTime.now().difference(oldestUpdate).inMinutes < 5;
  }

  /// Очищення кешу
  void clearCache() {
    _priceCache.clear();
    _lastUpdate.clear();
    _requestCount = 0;
    _lastRequestTime = null;
  }

  /// Форматування ціни для відображення
  static String formatPrice(double price) {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(0)}';
    } else if (price >= 100) {
      return '\$${price.toStringAsFixed(1)}';
    } else {
      return '\$${price.toStringAsFixed(2)}';
    }
  }

  /// Форматування відсотка зміни
  static String formatPercentage(double percentage) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(2)}%';
  }
}
