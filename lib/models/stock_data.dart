/// Повна інформація про акцію
class StockInfo {
  final String symbol;
  final String name;
  final String sector;
  final double price;              // Поточна ціна
  final double historicalGrowth;   // Історичний річний ріст (10 років)
  final double dividendYield;      // Дивідендна дохідність
  final double volatility;         // Волатильність (beta)
  final DateTime? lastUpdated;

  const StockInfo({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.price,
    required this.historicalGrowth,
    this.dividendYield = 0,
    this.volatility = 1.0,
    this.lastUpdated,
  });

  factory StockInfo.fromMap(Map<String, dynamic> map) {
    return StockInfo(
      symbol: map['symbol'] ?? '',
      name: map['name'] ?? '',
      sector: map['sector'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      historicalGrowth: (map['historicalGrowth'] ?? 0.10).toDouble(),
      dividendYield: (map['dividendYield'] ?? 0).toDouble(),
      volatility: (map['volatility'] ?? 1.0).toDouble(),
      lastUpdated: map['lastUpdated'] != null 
          ? DateTime.tryParse(map['lastUpdated']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'name': name,
      'sector': sector,
      'price': price,
      'historicalGrowth': historicalGrowth,
      'dividendYield': dividendYield,
      'volatility': volatility,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  StockInfo copyWith({double? price, DateTime? lastUpdated}) {
    return StockInfo(
      symbol: symbol,
      name: name,
      sector: sector,
      price: price ?? this.price,
      historicalGrowth: historicalGrowth,
      dividendYield: dividendYield,
      volatility: volatility,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Сектори ринку
class MarketSector {
  static const String technology = 'Technology';
  static const String financial = 'Financial';
  static const String healthcare = 'Healthcare';
  static const String consumer = 'Consumer';
  static const String energy = 'Energy';
  static const String industrial = 'Industrial';
  static const String communication = 'Communication';
  static const String materials = 'Materials';
}

/// База даних акцій з реальними цінами (Січень 2025)
/// Ціни приблизні, оновлюються через API
final Map<String, StockInfo> stockDatabase = {
  // === TECHNOLOGY (Технології) ===
  'AAPL': const StockInfo(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    sector: MarketSector.technology,
    price: 178.50,
    historicalGrowth: 0.22,    // ~22% річний ріст за 10 років
    dividendYield: 0.005,      // 0.5%
    volatility: 1.2,
  ),
  'NVDA': const StockInfo(
    symbol: 'NVDA',
    name: 'NVIDIA Corporation',
    sector: MarketSector.technology,
    price: 875.00,
    historicalGrowth: 0.45,    // AI бум!
    dividendYield: 0.0003,
    volatility: 1.8,
  ),
  'MSFT': const StockInfo(
    symbol: 'MSFT',
    name: 'Microsoft Corporation',
    sector: MarketSector.technology,
    price: 415.00,
    historicalGrowth: 0.25,
    dividendYield: 0.007,
    volatility: 1.1,
  ),
  'ADBE': const StockInfo(
    symbol: 'ADBE',
    name: 'Adobe Inc.',
    sector: MarketSector.technology,
    price: 485.00,
    historicalGrowth: 0.18,
    dividendYield: 0,
    volatility: 1.3,
  ),
  'AMZN': const StockInfo(
    symbol: 'AMZN',
    name: 'Amazon.com Inc.',
    sector: MarketSector.technology,
    price: 185.00,
    historicalGrowth: 0.24,
    dividendYield: 0,
    volatility: 1.3,
  ),
  'GOOGL': const StockInfo(
    symbol: 'GOOGL',
    name: 'Alphabet Inc.',
    sector: MarketSector.technology,
    price: 175.00,
    historicalGrowth: 0.20,
    dividendYield: 0,
    volatility: 1.2,
  ),
  'TSLA': const StockInfo(
    symbol: 'TSLA',
    name: 'Tesla Inc.',
    sector: MarketSector.technology,
    price: 248.00,
    historicalGrowth: 0.35,
    dividendYield: 0,
    volatility: 2.0,           // Дуже волатильна
  ),
  'META': const StockInfo(
    symbol: 'META',
    name: 'Meta Platforms Inc.',
    sector: MarketSector.technology,
    price: 585.00,
    historicalGrowth: 0.18,
    dividendYield: 0.004,
    volatility: 1.4,
  ),
  'CSCO': const StockInfo(
    symbol: 'CSCO',
    name: 'Cisco Systems Inc.',
    sector: MarketSector.technology,
    price: 58.00,
    historicalGrowth: 0.08,
    dividendYield: 0.026,
    volatility: 0.9,
  ),
  'AMAT': const StockInfo(
    symbol: 'AMAT',
    name: 'Applied Materials Inc.',
    sector: MarketSector.technology,
    price: 185.00,
    historicalGrowth: 0.22,
    dividendYield: 0.007,
    volatility: 1.5,
  ),
  'KLAC': const StockInfo(
    symbol: 'KLAC',
    name: 'KLA Corporation',
    sector: MarketSector.technology,
    price: 720.00,
    historicalGrowth: 0.25,
    dividendYield: 0.009,
    volatility: 1.4,
  ),
  'LRCX': const StockInfo(
    symbol: 'LRCX',
    name: 'Lam Research Corp.',
    sector: MarketSector.technology,
    price: 950.00,
    historicalGrowth: 0.23,
    dividendYield: 0.01,
    volatility: 1.5,
  ),

  // === FINANCIAL (Фінанси) ===
  'JPM': const StockInfo(
    symbol: 'JPM',
    name: 'JPMorgan Chase & Co.',
    sector: MarketSector.financial,
    price: 195.00,
    historicalGrowth: 0.12,
    dividendYield: 0.022,
    volatility: 1.1,
  ),
  'V': const StockInfo(
    symbol: 'V',
    name: 'Visa Inc.',
    sector: MarketSector.financial,
    price: 275.00,
    historicalGrowth: 0.16,
    dividendYield: 0.008,
    volatility: 1.0,
  ),
  'MA': const StockInfo(
    symbol: 'MA',
    name: 'Mastercard Inc.',
    sector: MarketSector.financial,
    price: 470.00,
    historicalGrowth: 0.17,
    dividendYield: 0.006,
    volatility: 1.0,
  ),
  'BAC': const StockInfo(
    symbol: 'BAC',
    name: 'Bank of America Corp.',
    sector: MarketSector.financial,
    price: 35.00,
    historicalGrowth: 0.08,
    dividendYield: 0.028,
    volatility: 1.3,
  ),
  'IBKR': const StockInfo(
    symbol: 'IBKR',
    name: 'Interactive Brokers',
    sector: MarketSector.financial,
    price: 165.00,
    historicalGrowth: 0.18,
    dividendYield: 0.006,
    volatility: 1.2,
  ),
  'ADP': const StockInfo(
    symbol: 'ADP',
    name: 'Automatic Data Processing',
    sector: MarketSector.financial,
    price: 285.00,
    historicalGrowth: 0.14,
    dividendYield: 0.02,
    volatility: 0.9,
  ),
  'AFL': const StockInfo(
    symbol: 'AFL',
    name: 'Aflac Inc.',
    sector: MarketSector.financial,
    price: 105.00,
    historicalGrowth: 0.10,
    dividendYield: 0.019,
    volatility: 0.9,
  ),
  'BRO': const StockInfo(
    symbol: 'BRO',
    name: 'Brown & Brown Inc.',
    sector: MarketSector.financial,
    price: 105.00,
    historicalGrowth: 0.15,
    dividendYield: 0.005,
    volatility: 0.8,
  ),
  'FICO': const StockInfo(
    symbol: 'FICO',
    name: 'Fair Isaac Corporation',
    sector: MarketSector.financial,
    price: 1850.00,
    historicalGrowth: 0.28,
    dividendYield: 0,
    volatility: 1.2,
  ),

  // === CONSUMER (Споживчий сектор) ===
  'KO': const StockInfo(
    symbol: 'KO',
    name: 'Coca-Cola Company',
    sector: MarketSector.consumer,
    price: 62.00,
    historicalGrowth: 0.07,
    dividendYield: 0.030,      // Дивідендний аристократ!
    volatility: 0.6,
  ),
  'PEP': const StockInfo(
    symbol: 'PEP',
    name: 'PepsiCo Inc.',
    sector: MarketSector.consumer,
    price: 168.00,
    historicalGrowth: 0.09,
    dividendYield: 0.027,
    volatility: 0.6,
  ),
  'MCD': const StockInfo(
    symbol: 'MCD',
    name: "McDonald's Corporation",
    sector: MarketSector.consumer,
    price: 295.00,
    historicalGrowth: 0.12,
    dividendYield: 0.022,
    volatility: 0.7,
  ),
  'WMT': const StockInfo(
    symbol: 'WMT',
    name: 'Walmart Inc.',
    sector: MarketSector.consumer,
    price: 165.00,
    historicalGrowth: 0.10,
    dividendYield: 0.014,
    volatility: 0.5,
  ),
  'COST': const StockInfo(
    symbol: 'COST',
    name: 'Costco Wholesale Corp.',
    sector: MarketSector.consumer,
    price: 905.00,
    historicalGrowth: 0.18,
    dividendYield: 0.005,
    volatility: 0.8,
  ),
  'PG': const StockInfo(
    symbol: 'PG',
    name: 'Procter & Gamble Co.',
    sector: MarketSector.consumer,
    price: 168.00,
    historicalGrowth: 0.08,
    dividendYield: 0.024,
    volatility: 0.5,
  ),
  'HD': const StockInfo(
    symbol: 'HD',
    name: 'Home Depot Inc.',
    sector: MarketSector.consumer,
    price: 390.00,
    historicalGrowth: 0.15,
    dividendYield: 0.023,
    volatility: 1.0,
  ),
  'LOW': const StockInfo(
    symbol: 'LOW',
    name: "Lowe's Companies Inc.",
    sector: MarketSector.consumer,
    price: 265.00,
    historicalGrowth: 0.14,
    dividendYield: 0.018,
    volatility: 1.1,
  ),
  'CHD': const StockInfo(
    symbol: 'CHD',
    name: 'Church & Dwight Co.',
    sector: MarketSector.consumer,
    price: 105.00,
    historicalGrowth: 0.12,
    dividendYield: 0.011,
    volatility: 0.6,
  ),
  'MNST': const StockInfo(
    symbol: 'MNST',
    name: 'Monster Beverage Corp.',
    sector: MarketSector.consumer,
    price: 52.00,
    historicalGrowth: 0.16,
    dividendYield: 0,
    volatility: 0.9,
  ),

  // === HEALTHCARE (Охорона здоров'я) ===
  'JNJ': const StockInfo(
    symbol: 'JNJ',
    name: 'Johnson & Johnson',
    sector: MarketSector.healthcare,
    price: 155.00,
    historicalGrowth: 0.07,
    dividendYield: 0.030,
    volatility: 0.6,
  ),
  'AMGN': const StockInfo(
    symbol: 'AMGN',
    name: 'Amgen Inc.',
    sector: MarketSector.healthcare,
    price: 285.00,
    historicalGrowth: 0.09,
    dividendYield: 0.032,
    volatility: 0.7,
  ),
  'GILD': const StockInfo(
    symbol: 'GILD',
    name: 'Gilead Sciences Inc.',
    sector: MarketSector.healthcare,
    price: 92.00,
    historicalGrowth: 0.05,
    dividendYield: 0.034,
    volatility: 0.8,
  ),
  'IDXX': const StockInfo(
    symbol: 'IDXX',
    name: 'IDEXX Laboratories',
    sector: MarketSector.healthcare,
    price: 435.00,
    historicalGrowth: 0.20,
    dividendYield: 0,
    volatility: 1.1,
  ),
  'ISRG': const StockInfo(
    symbol: 'ISRG',
    name: 'Intuitive Surgical Inc.',
    sector: MarketSector.healthcare,
    price: 485.00,
    historicalGrowth: 0.18,
    dividendYield: 0,
    volatility: 1.0,
  ),

  // === ENERGY (Енергетика) ===
  'XOM': const StockInfo(
    symbol: 'XOM',
    name: 'Exxon Mobil Corporation',
    sector: MarketSector.energy,
    price: 105.00,
    historicalGrowth: 0.06,
    dividendYield: 0.035,
    volatility: 1.0,
  ),
  'CVX': const StockInfo(
    symbol: 'CVX',
    name: 'Chevron Corporation',
    sector: MarketSector.energy,
    price: 145.00,
    historicalGrowth: 0.05,
    dividendYield: 0.042,
    volatility: 1.0,
  ),

  // === COMMUNICATION (Комунікації) ===
  'T': const StockInfo(
    symbol: 'T',
    name: 'AT&T Inc.',
    sector: MarketSector.communication,
    price: 22.50,
    historicalGrowth: 0.02,
    dividendYield: 0.050,      // Високі дивіденди!
    volatility: 0.8,
  ),
  'VZ': const StockInfo(
    symbol: 'VZ',
    name: 'Verizon Communications',
    sector: MarketSector.communication,
    price: 42.00,
    historicalGrowth: 0.03,
    dividendYield: 0.065,      // Дуже високі дивіденди
    volatility: 0.7,
  ),
  'CMCSA': const StockInfo(
    symbol: 'CMCSA',
    name: 'Comcast Corporation',
    sector: MarketSector.communication,
    price: 42.00,
    historicalGrowth: 0.08,
    dividendYield: 0.028,
    volatility: 0.9,
  ),

  // === INDUSTRIAL (Промисловість) ===
  'BA': const StockInfo(
    symbol: 'BA',
    name: 'Boeing Company',
    sector: MarketSector.industrial,
    price: 175.00,
    historicalGrowth: 0.04,    // Проблеми останніх років
    dividendYield: 0,
    volatility: 1.5,
  ),
  'BKNG': const StockInfo(
    symbol: 'BKNG',
    name: 'Booking Holdings Inc.',
    sector: MarketSector.industrial,
    price: 4250.00,
    historicalGrowth: 0.15,
    dividendYield: 0,
    volatility: 1.2,
  ),
  'AXON': const StockInfo(
    symbol: 'AXON',
    name: 'Axon Enterprise Inc.',
    sector: MarketSector.industrial,
    price: 585.00,
    historicalGrowth: 0.35,
    dividendYield: 0,
    volatility: 1.4,
  ),
  'APH': const StockInfo(
    symbol: 'APH',
    name: 'Amphenol Corporation',
    sector: MarketSector.industrial,
    price: 70.00,
    historicalGrowth: 0.16,
    dividendYield: 0.009,
    volatility: 1.0,
  ),
  'CPRT': const StockInfo(
    symbol: 'CPRT',
    name: 'Copart Inc.',
    sector: MarketSector.industrial,
    price: 55.00,
    historicalGrowth: 0.20,
    dividendYield: 0,
    volatility: 1.0,
  ),
  'CTAS': const StockInfo(
    symbol: 'CTAS',
    name: 'Cintas Corporation',
    sector: MarketSector.industrial,
    price: 195.00,
    historicalGrowth: 0.17,
    dividendYield: 0.008,
    volatility: 0.9,
  ),
  'EXPD': const StockInfo(
    symbol: 'EXPD',
    name: 'Expeditors International',
    sector: MarketSector.industrial,
    price: 120.00,
    historicalGrowth: 0.10,
    dividendYield: 0.012,
    volatility: 0.9,
  ),
  'FAST': const StockInfo(
    symbol: 'FAST',
    name: 'Fastenal Company',
    sector: MarketSector.industrial,
    price: 75.00,
    historicalGrowth: 0.14,
    dividendYield: 0.022,
    volatility: 0.9,
  ),
  'ODFL': const StockInfo(
    symbol: 'ODFL',
    name: 'Old Dominion Freight',
    sector: MarketSector.industrial,
    price: 195.00,
    historicalGrowth: 0.20,
    dividendYield: 0.004,
    volatility: 1.1,
  ),

  // === MATERIALS (Матеріали) ===
  'NUE': const StockInfo(
    symbol: 'NUE',
    name: 'Nucor Corporation',
    sector: MarketSector.materials,
    price: 155.00,
    historicalGrowth: 0.12,
    dividendYield: 0.014,
    volatility: 1.3,
  ),
};

/// Отримати список всіх тікерів
List<String> getAllTickers() => stockDatabase.keys.toList();

/// Отримати інформацію про акцію
StockInfo? getStockInfo(String symbol) => stockDatabase[symbol];

/// Отримати акції по сектору
List<StockInfo> getStocksBySector(String sector) {
  return stockDatabase.values
      .where((stock) => stock.sector == sector)
      .toList();
}

/// Середній історичний ріст портфеля
double getAverageGrowth() {
  final stocks = stockDatabase.values.toList();
  return stocks.fold(0.0, (sum, s) => sum + s.historicalGrowth) / stocks.length;
}

/// Отримати топ акцій за ростом
List<StockInfo> getTopGrowthStocks(int limit) {
  final stocks = stockDatabase.values.toList();
  stocks.sort((a, b) => b.historicalGrowth.compareTo(a.historicalGrowth));
  return stocks.take(limit).toList();
}

/// Отримати дивідендні акції
List<StockInfo> getDividendStocks({double minYield = 0.02}) {
  return stockDatabase.values
      .where((stock) => stock.dividendYield >= minYield)
      .toList()
    ..sort((a, b) => b.dividendYield.compareTo(a.dividendYield));
}
