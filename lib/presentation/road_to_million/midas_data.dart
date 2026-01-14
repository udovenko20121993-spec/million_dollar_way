import 'dart:math' as math;
import '../../models/stock_data.dart';

// --- СПИСОК ТІКЕРІВ (з нової бази даних) ---
final List<String> tickersList = getAllTickers();

// --- ТИПИ СОРТУВАННЯ ---
enum SortType { profitDesc, profitAsc, nameAsc, valueDesc }

// --- ДОПОМІЖНІ ФУНКЦІЇ ---

/// Форматування грошей (1000 -> 1 000)
String formatMoney(double value) {
  return value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
}

/// Отримання повної назви компанії
String getStockName(String ticker) {
  final stock = getStockInfo(ticker);
  return stock?.name ?? '$ticker Corp';
}

/// Профіль акції (ціна та ріст) - тепер з реальними даними!
Map<String, double> getStockProfile(String ticker) {
  final stock = getStockInfo(ticker);
  
  if (stock != null) {
    return {
      'price': stock.price,
      'growth': stock.historicalGrowth,
      'dividend': stock.dividendYield,
      'volatility': stock.volatility,
    };
  }
  
  // Fallback для невідомих тікерів
  return {
    'price': 50.0,
    'growth': 0.10,
    'dividend': 0.0,
    'volatility': 1.0,
  };
}

/// Отримати детальну інформацію про акцію
StockInfo? getStockDetails(String ticker) => getStockInfo(ticker);

/// Генерація історії цін для графіку (покращена версія)
List<Map<String, dynamic>> generateHistory(
  double currentPrice,
  int yearsTotal, {
  double? growthRate,
}) {
  List<Map<String, dynamic>> data = [];
  
  // Використовуємо реальний історичний ріст або 15% за замовчуванням
  final annualGrowth = growthRate ?? 0.15;
  
  // Генеруємо точки для графіку
  int step = (yearsTotal / 5).ceil();
  if (step < 1) step = 1;

  for (int i = 0; i < 6; i++) {
    int year = DateTime.now().year - (i * step);
    
    // Розраховуємо історичну ціну з урахуванням волатильності
    double historicalPrice = currentPrice / math.pow(1 + annualGrowth, i * step);
    
    // Додаємо невелику випадковість для реалістичності
    final randomFactor = 0.95 + (math.Random().nextDouble() * 0.1);
    historicalPrice *= randomFactor;

    data.add({
      'year': year,
      'price': historicalPrice,
    });
  }
  
  return data.reversed.toList();
}

/// Розрахунок вартості позиції в минулому
double calculateHistoricalValue({
  required double weeklyInvestment,
  required int years,
  required double currentPrice,
  required double growthRate,
  bool useBot = false,
}) {
  int totalMonths = years * 12;
  
  // Бонус від бота (краща точка входу)
  double botBonus = useBot ? 0.05 : 0.0;
  double effectiveGrowth = growthRate + botBonus;
  
  // Розраховуємо середню ціну входу
  // (враховуємо що купували протягом всього періоду)
  double growthFactor = math.pow(1 + effectiveGrowth, years * 0.7).toDouble();
  double avgPrice = currentPrice / growthFactor;
  
  // Загальна інвестиція
  double totalInvested = (weeklyInvestment * 52 / 12) * totalMonths;
  
  // Кількість акцій
  double qty = totalInvested / avgPrice;
  
  // Поточна вартість
  return qty * currentPrice;
}

/// Отримати топ акцій за ростом
List<String> getTopGrowthTickers(int limit) {
  return getTopGrowthStocks(limit).map((s) => s.symbol).toList();
}

/// Отримати дивідендні акції
List<String> getDividendTickers({double minYield = 0.02}) {
  return getDividendStocks(minYield: minYield).map((s) => s.symbol).toList();
}

/// Отримати акції по сектору
List<String> getTickersBySector(String sector) {
  return getStocksBySector(sector).map((s) => s.symbol).toList();
}

/// Середня дохідність портфеля
double getPortfolioAverageGrowth() => getAverageGrowth();

/// Форматування відсотків
String formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1)}%';
}

/// Форматування ціни
String formatPrice(double value) {
  if (value >= 1000) {
    return '\$${(value / 1000).toStringAsFixed(1)}K';
  }
  return '\$${value.toStringAsFixed(2)}';
}

/// Отримати іконку сектора
String getSectorEmoji(String sector) {
  switch (sector) {
    case MarketSector.technology:
      return '💻';
    case MarketSector.financial:
      return '🏦';
    case MarketSector.healthcare:
      return '🏥';
    case MarketSector.consumer:
      return '🛒';
    case MarketSector.energy:
      return '⛽';
    case MarketSector.industrial:
      return '🏭';
    case MarketSector.communication:
      return '📡';
    case MarketSector.materials:
      return '🔧';
    default:
      return '📊';
  }
}
