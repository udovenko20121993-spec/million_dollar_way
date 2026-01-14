import 'dart:io';
import 'package:xml/xml.dart';
import '../domain/models/midas_models.dart';

class IBKRDataImporter {
  static const List<String> targetSymbols = [
    'AAPL',
    'GOOGL',
    'MSFT',
    'AMZN',
    'TSLA',
    'META',
    'NVDA',
    'JPM',
    'JNJ',
    'V',
    'PG',
    'UNH',
    'HD',
    'MA',
    'DIS',
    'PYPL',
    'ADBE',
    'CRM',
    'NFLX',
    'INTC',
    'CSCO',
    'CMCSA',
    'PEP',
    'COST',
    'TMUS',
    'AVGO',
    'TXN',
    'NKE',
    'ABT',
    'CRM',
    'XOM',
    'CVX',
    'BA',
    'WMT',
    'KO',
    'MRK',
    'T',
    'MDT',
    'IBM',
    'GS',
    'CAT',
    'RTX',
    'HON',
    'UNP',
    'UPS',
    'LOW',
    'TGT',
    'SBUX',
    'MCD',
    'HD',
    'ORCL',
  ];

  /// Парсинг IBKR XML файлу для отримання реальних даних портфоліо
  static Future<List<StockPosition>> parseIBKRXML(String xmlFilePath) async {
    try {
      final file = File(xmlFilePath);
      if (!(await file.exists())) {
        throw Exception('XML файл не знайдено: $xmlFilePath');
      }

      final xmlContent = await file.readAsString();
      final document = XmlDocument.parse(xmlContent);

      final positions = <StockPosition>[];

      // Знаходимо всі акції в XML
      final trades = document.findAllElements('Trade');

      for (final trade in trades) {
        final symbol = trade.getElement('symbol')?.innerText ?? '';
        final quantity =
            double.tryParse(trade.getElement('quantity')?.innerText ?? '0') ??
            0;
        final price =
            double.tryParse(trade.getElement('price')?.innerText ?? '0') ?? 0;
        final tradeType = trade.getElement('buy/sell')?.innerText ?? '';

        // Беремо тільки наші цільові символи
        if (targetSymbols.contains(symbol) && quantity > 0) {
          // Знаходимо існуючу позицію або створюємо нову
          final existingIndex = positions.indexWhere((p) => p.symbol == symbol);

          if (existingIndex >= 0) {
            // Оновлюємо існуючу позицію
            final existing = positions[existingIndex];
            final newQuantity = tradeType == 'BUY'
                ? existing.quantity + quantity
                : existing.quantity - quantity;

            if (newQuantity > 0) {
              positions[existingIndex] = StockPosition(
                symbol: symbol,
                quantity: newQuantity,
                averagePrice: _calculateAveragePrice(
                  existing,
                  quantity,
                  price,
                  tradeType,
                ),
                transactions: [
                  ...existing.transactions,
                  _createTransaction(symbol, quantity, price, tradeType),
                ],
              );
            }
          } else {
            // Створюємо нову позицію
            positions.add(
              StockPosition(
                symbol: symbol,
                quantity: quantity,
                averagePrice: price,
                transactions: [
                  _createTransaction(symbol, quantity, price, tradeType),
                ],
              ),
            );
          }
        }
      }

      return positions;
    } catch (e) {
      throw Exception('Помилка парсингу IBKR XML: $e');
    }
  }

  /// Розрахунок середньої ціни для позиції
  static double _calculateAveragePrice(
    StockPosition existing,
    double newQuantity,
    double newPrice,
    String tradeType,
  ) {
    if (tradeType == 'SELL') {
      return existing.averagePrice; // При продажу середня ціна не змінюється
    }

    final totalCost =
        (existing.quantity * existing.averagePrice) + (newQuantity * newPrice);
    final totalQuantity = existing.quantity + newQuantity;
    return totalCost / totalQuantity;
  }

  /// Створення транзакції
  static StockTransaction _createTransaction(
    String symbol,
    double quantity,
    double price,
    String tradeType,
  ) {
    return StockTransaction(
      symbol: symbol,
      date: DateTime.now(), // В реальному додатку беремо з XML
      quantity: quantity,
      price: price,
      type: tradeType == 'BUY' ? TransactionType.buy : TransactionType.sell,
    );
  }

  /// Отримання даних з IBKR API (альтернативний метод)
  static Future<List<StockPosition>> fetchFromIBKRAPI(String apiKey) async {
    try {
      // Симуляція API виклику - в реальному додатку тут буде HTTP запит
      await Future.delayed(const Duration(seconds: 2));

      // Повертаємо пустий список, поки немає реального API
      return [];
    } catch (e) {
      throw Exception('Помилка отримання даних з IBKR API: $e');
    }
  }

  /// Валідація XML файлу
  static Future<bool> validateXMLFile(String xmlFilePath) async {
    try {
      final file = File(xmlFilePath);
      if (!(await file.exists())) return false;

      final content = await file.readAsString();
      final document = XmlDocument.parse(content);

      // Перевіряємо наявність необхідних елементів
      return document.findAllElements('Trade').isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
