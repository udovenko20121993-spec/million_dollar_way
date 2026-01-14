import 'package:flutter/foundation.dart';
import '../domain/models/midas_models.dart';
import 'ibkr_data_importer.dart';
import 'finnhub_service.dart';

class RealPortfolioService {
  static RealPortfolioService? _instance;
  static RealPortfolioService get instance =>
      _instance ??= RealPortfolioService._();

  RealPortfolioService._();

  List<StockPosition> _realPositions = [];
  Map<String, double> _currentPrices = {};
  DateTime? _lastDataUpdate;
  DateTime? _lastPriceUpdate;
  String? _dataSource;
  bool _isLoading = false;

  // Getters
  List<StockPosition> get realPositions => List.unmodifiable(_realPositions);
  Map<String, double> get currentPrices => Map.unmodifiable(_currentPrices);
  DateTime? get lastDataUpdate => _lastDataUpdate;
  DateTime? get lastPriceUpdate => _lastPriceUpdate;
  String? get dataSource => _dataSource;
  bool get isLoading => _isLoading;
  bool get hasRealData => _realPositions.isNotEmpty;

  /// Завантаження даних з IBKR XML файлу
  Future<bool> loadFromIBKRXML(String xmlFilePath) async {
    try {
      _isLoading = true;

      if (kDebugMode) print('Loading IBKR XML from: $xmlFilePath');

      final positions = await IBKRDataImporter.parseIBKRXML(xmlFilePath);

      _realPositions = positions;
      _lastDataUpdate = DateTime.now();
      _dataSource =
          'IBKR XML від ${_lastDataUpdate!.day}.${_lastDataUpdate!.month}.${_lastDataUpdate!.year}';

      // Автоматично завантажуємо ціни для реальних позицій
      if (positions.isNotEmpty) {
        await updatePrices();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) print('Error loading IBKR XML: $e');
      return false;
    }
  }

  /// Оновлення цін для всіх позицій
  Future<void> updatePrices() async {
    try {
      if (_realPositions.isEmpty) return;

      final symbols = _realPositions.map((p) => p.symbol).toList();
      final finnhubService = FinnhubService();

      final prices = await finnhubService.getAllCurrentPrices();

      _currentPrices = prices;
      _lastPriceUpdate = DateTime.now();

      if (kDebugMode) print('Updated prices for ${prices.length} symbols');
    } catch (e) {
      if (kDebugMode) print('Error updating prices: $e');
    }
  }

  /// Розрахунок поточної вартості портфоліо
  double calculatePortfolioValue() {
    if (_realPositions.isEmpty || _currentPrices.isEmpty) return 0.0;

    double totalValue = 0.0;

    for (final position in _realPositions) {
      final currentPrice = _currentPrices[position.symbol];
      if (currentPrice != null) {
        totalValue += position.quantity * currentPrice;
      }
    }

    return totalValue;
  }

  /// Розрахунок загальної вартості придбання
  double calculateTotalCost() {
    return _realPositions.fold(
      0.0,
      (sum, position) => sum + (position.quantity * position.averagePrice),
    );
  }

  /// Розрахунок загального прибутку/збитку
  double calculateTotalPnL() {
    return calculatePortfolioValue() - calculateTotalCost();
  }

  /// Розрахунок прибутку/збитку у %
  double calculateTotalPnLPercent() {
    final totalCost = calculateTotalCost();
    if (totalCost == 0) return 0.0;
    return (calculateTotalPnL() / totalCost) * 100;
  }

  /// Отримання позиції за символом
  StockPosition? getPosition(String symbol) {
    try {
      return _realPositions.firstWhere((p) => p.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  /// Отримання поточної ціни для символу
  double? getCurrentPrice(String symbol) {
    return _currentPrices[symbol];
  }

  /// Перевірка чи є живі дані для символу
  bool hasLiveDataForSymbol(String symbol) {
    return _currentPrices.containsKey(symbol) &&
        _lastPriceUpdate != null &&
        DateTime.now().difference(_lastPriceUpdate!).inMinutes < 10;
  }

  /// Перевірка чи є живі дані для всього портфоліо
  bool get hasLiveData =>
      _currentPrices.isNotEmpty &&
      _lastPriceUpdate != null &&
      DateTime.now().difference(_lastPriceUpdate!).inMinutes < 10;

  /// Очищення всіх даних
  void clearData() {
    _realPositions.clear();
    _currentPrices.clear();
    _lastDataUpdate = null;
    _lastPriceUpdate = null;
    _dataSource = null;
  }

  /// Отримання статистики портфоліо
  Map<String, dynamic> getPortfolioStats() {
    final portfolioValue = calculatePortfolioValue();
    final totalCost = calculateTotalCost();
    final totalPnL = calculateTotalPnL();
    final totalPnLPercent = calculateTotalPnLPercent();

    return {
      'portfolioValue': portfolioValue,
      'totalCost': totalCost,
      'totalPnL': totalPnL,
      'totalPnLPercent': totalPnLPercent,
      'positionsCount': _realPositions.length,
      'hasLiveData': _currentPrices.isNotEmpty,
      'lastUpdate': _lastPriceUpdate,
      'dataSource': _dataSource,
    };
  }

  /// Форматування суми для відображення
  String formatAmount(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  /// Отримання статусу даних
  String getDataStatus() {
    if (_isLoading) return 'Завантаження...';
    if (_realPositions.isEmpty) return 'Немає даних';
    if (_currentPrices.isEmpty) return 'Позиції завантажено, ціни оновлюються';
    if (_lastPriceUpdate != null &&
        DateTime.now().difference(_lastPriceUpdate!).inMinutes < 10) {
      return 'Живі дані';
    }
    return 'Дані застарілі';
  }

  /// Перевірка чи потрібно оновити ціни
  bool shouldUpdatePrices() {
    if (_lastPriceUpdate == null) return true;
    return DateTime.now().difference(_lastPriceUpdate!).inMinutes >= 5;
  }
}
