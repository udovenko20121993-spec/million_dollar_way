import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_data.dart';

/// Сервіс для отримання та кешування цін акцій
class StockPriceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Кеш в пам'яті
  static final Map<String, StockInfo> _memoryCache = {};
  static DateTime? _lastFetch;
  
  // Час життя кешу (4 години)
  static const Duration _cacheDuration = Duration(hours: 4);

  /// Отримати всі ціни (з кешу або бази)
  Future<Map<String, StockInfo>> getAllPrices() async {
    // 1. Перевіряємо memory cache
    if (_memoryCache.isNotEmpty && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _cacheDuration) {
        return Map.from(_memoryCache);
      }
    }

    // 2. Пробуємо з Firestore
    try {
      final doc = await _db.collection('market_data').doc('stocks').get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();
        
        // Якщо дані свіжі (менше 4 годин)
        if (lastUpdated != null && 
            DateTime.now().difference(lastUpdated) < _cacheDuration) {
          final prices = data['prices'] as Map<String, dynamic>? ?? {};
          
          _memoryCache.clear();
          for (var entry in prices.entries) {
            final baseStock = stockDatabase[entry.key];
            if (baseStock != null) {
              _memoryCache[entry.key] = baseStock.copyWith(
                price: (entry.value as num).toDouble(),
                lastUpdated: lastUpdated,
              );
            }
          }
          
          _lastFetch = DateTime.now();
          return Map.from(_memoryCache);
        }
      }
    } catch (e) {
      print('Error loading from Firestore: $e');
    }

    // 3. Повертаємо захардкоджені дані
    _memoryCache.clear();
    _memoryCache.addAll(stockDatabase);
    _lastFetch = DateTime.now();
    
    return Map.from(_memoryCache);
  }

  /// Отримати ціну однієї акції
  Future<StockInfo?> getStockPrice(String symbol) async {
    final allPrices = await getAllPrices();
    return allPrices[symbol];
  }

  /// Оновити ціни з API (викликається вручну або по розкладу)
  Future<bool> refreshPricesFromAPI() async {
    try {
      // Використовуємо безкоштовний Yahoo Finance API через RapidAPI
      // Або альтернативу - Finnhub, Alpha Vantage
      
      final symbols = stockDatabase.keys.toList();
      final Map<String, double> newPrices = {};

      // Розбиваємо на батчі по 10 символів
      for (int i = 0; i < symbols.length; i += 10) {
        final batch = symbols.skip(i).take(10).toList();
        final prices = await _fetchBatchPrices(batch);
        newPrices.addAll(prices);
        
        // Пауза між запитами щоб не перевищити ліміт
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (newPrices.isNotEmpty) {
        // Зберігаємо в Firestore
        await _savePricesToFirestore(newPrices);
        
        // Оновлюємо memory cache
        for (var entry in newPrices.entries) {
          final baseStock = stockDatabase[entry.key];
          if (baseStock != null) {
            _memoryCache[entry.key] = baseStock.copyWith(
              price: entry.value,
              lastUpdated: DateTime.now(),
            );
          }
        }
        
        _lastFetch = DateTime.now();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error refreshing prices: $e');
      return false;
    }
  }

  /// Отримати ціни для батчу символів
  Future<Map<String, double>> _fetchBatchPrices(List<String> symbols) async {
    final Map<String, double> prices = {};
    
    try {
      // Варіант 1: Yahoo Finance (через проксі)
      // Це безкоштовний спосіб, але може бути нестабільним
      
      final symbolsStr = symbols.join(',');
      final url = Uri.parse(
        'https://query1.finance.yahoo.com/v7/finance/quote?symbols=$symbolsStr'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0',
      }).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['quoteResponse']?['result'] as List? ?? [];
        
        for (var quote in results) {
          final symbol = quote['symbol'] as String?;
          final price = quote['regularMarketPrice'] as num?;
          
          if (symbol != null && price != null) {
            prices[symbol] = price.toDouble();
          }
        }
      }
    } catch (e) {
      print('Error fetching batch prices: $e');
      
      // Fallback: повертаємо захардкоджені ціни
      for (var symbol in symbols) {
        final stock = stockDatabase[symbol];
        if (stock != null) {
          prices[symbol] = stock.price;
        }
      }
    }
    
    return prices;
  }

  /// Зберегти ціни в Firestore
  Future<void> _savePricesToFirestore(Map<String, double> prices) async {
    await _db.collection('market_data').doc('stocks').set({
      'prices': prices,
      'lastUpdated': FieldValue.serverTimestamp(),
      'source': 'yahoo_finance',
    }, SetOptions(merge: true));
  }

  /// Отримати час останнього оновлення
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final doc = await _db.collection('market_data').doc('stocks').get();
      if (doc.exists) {
        return (doc.data()?['lastUpdated'] as Timestamp?)?.toDate();
      }
    } catch (e) {
      print('Error getting last update time: $e');
    }
    return null;
  }

  /// Очистити кеш
  void clearCache() {
    _memoryCache.clear();
    _lastFetch = null;
  }

  /// Отримати статистику по секторах
  Future<Map<String, SectorStats>> getSectorStats() async {
    final prices = await getAllPrices();
    final Map<String, SectorStats> stats = {};

    for (var stock in prices.values) {
      if (!stats.containsKey(stock.sector)) {
        stats[stock.sector] = SectorStats(
          sector: stock.sector,
          stockCount: 0,
          totalValue: 0,
          avgGrowth: 0,
          avgDividend: 0,
        );
      }
      
      final current = stats[stock.sector]!;
      stats[stock.sector] = SectorStats(
        sector: stock.sector,
        stockCount: current.stockCount + 1,
        totalValue: current.totalValue + stock.price,
        avgGrowth: current.avgGrowth + stock.historicalGrowth,
        avgDividend: current.avgDividend + stock.dividendYield,
      );
    }

    // Обчислюємо середні значення
    for (var key in stats.keys) {
      final s = stats[key]!;
      if (s.stockCount > 0) {
        stats[key] = SectorStats(
          sector: s.sector,
          stockCount: s.stockCount,
          totalValue: s.totalValue,
          avgGrowth: s.avgGrowth / s.stockCount,
          avgDividend: s.avgDividend / s.stockCount,
        );
      }
    }

    return stats;
  }
}

/// Статистика по сектору
class SectorStats {
  final String sector;
  final int stockCount;
  final double totalValue;
  final double avgGrowth;
  final double avgDividend;

  SectorStats({
    required this.sector,
    required this.stockCount,
    required this.totalValue,
    required this.avgGrowth,
    required this.avgDividend,
  });
}
