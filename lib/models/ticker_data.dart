class TickerData {
  final String symbol;
  final String name;
  final double historicalWeeklyGrowthRate; // IRR-based weekly growth rate
  final double currentPrice;
  final double volatility; // For realistic simulations

  const TickerData({
    required this.symbol,
    required this.name,
    required this.historicalWeeklyGrowthRate,
    required this.currentPrice,
    required this.volatility,
  });
}

class TickerRepository {
  static const List<TickerData> _tickers = [
    // Tech Giants
    TickerData(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      historicalWeeklyGrowthRate: 0.0028,
      currentPrice: 195.89,
      volatility: 0.025,
    ),
    TickerData(
      symbol: 'MSFT',
      name: 'Microsoft Corp.',
      historicalWeeklyGrowthRate: 0.0031,
      currentPrice: 378.91,
      volatility: 0.022,
    ),
    TickerData(
      symbol: 'NVDA',
      name: 'NVIDIA Corp.',
      historicalWeeklyGrowthRate: 0.0045,
      currentPrice: 495.22,
      volatility: 0.035,
    ),
    TickerData(
      symbol: 'GOOGL',
      name: 'Alphabet Inc.',
      historicalWeeklyGrowthRate: 0.0025,
      currentPrice: 141.80,
      volatility: 0.028,
    ),
    TickerData(
      symbol: 'AMZN',
      name: 'Amazon.com Inc.',
      historicalWeeklyGrowthRate: 0.0029,
      currentPrice: 155.33,
      volatility: 0.030,
    ),
    TickerData(
      symbol: 'META',
      name: 'Meta Platforms',
      historicalWeeklyGrowthRate: 0.0033,
      currentPrice: 484.03,
      volatility: 0.032,
    ),
    TickerData(
      symbol: 'TSLA',
      name: 'Tesla Inc.',
      historicalWeeklyGrowthRate: 0.0038,
      currentPrice: 242.84,
      volatility: 0.045,
    ),

    // Healthcare
    TickerData(
      symbol: 'UNH',
      name: 'UnitedHealth Group',
      historicalWeeklyGrowthRate: 0.0022,
      currentPrice: 543.27,
      volatility: 0.018,
    ),
    TickerData(
      symbol: 'JNJ',
      name: 'Johnson & Johnson',
      historicalWeeklyGrowthRate: 0.0018,
      currentPrice: 157.33,
      volatility: 0.015,
    ),
    TickerData(
      symbol: 'PFE',
      name: 'Pfizer Inc.',
      historicalWeeklyGrowthRate: 0.0015,
      currentPrice: 28.45,
      volatility: 0.020,
    ),
    TickerData(
      symbol: 'ABBV',
      name: 'AbbVie Inc.',
      historicalWeeklyGrowthRate: 0.0020,
      currentPrice: 175.12,
      volatility: 0.019,
    ),
    TickerData(
      symbol: 'TMO',
      name: 'Thermo Fisher',
      historicalWeeklyGrowthRate: 0.0024,
      currentPrice: 562.11,
      volatility: 0.021,
    ),

    // Finance
    TickerData(
      symbol: 'JPM',
      name: 'JPMorgan Chase',
      historicalWeeklyGrowthRate: 0.0021,
      currentPrice: 198.03,
      volatility: 0.023,
    ),
    TickerData(
      symbol: 'BAC',
      name: 'Bank of America',
      historicalWeeklyGrowthRate: 0.0019,
      currentPrice: 34.78,
      volatility: 0.025,
    ),
    TickerData(
      symbol: 'WFC',
      name: 'Wells Fargo',
      historicalWeeklyGrowthRate: 0.0017,
      currentPrice: 52.91,
      volatility: 0.022,
    ),
    TickerData(
      symbol: 'GS',
      name: 'Goldman Sachs',
      historicalWeeklyGrowthRate: 0.0023,
      currentPrice: 423.67,
      volatility: 0.026,
    ),
    TickerData(
      symbol: 'MS',
      name: 'Morgan Stanley',
      historicalWeeklyGrowthRate: 0.0020,
      currentPrice: 89.34,
      volatility: 0.024,
    ),

    // Consumer Discretionary
    TickerData(
      symbol: 'AMZN',
      name: 'Amazon.com Inc.',
      historicalWeeklyGrowthRate: 0.0029,
      currentPrice: 155.33,
      volatility: 0.030,
    ),
    TickerData(
      symbol: 'TSLA',
      name: 'Tesla Inc.',
      historicalWeeklyGrowthRate: 0.0038,
      currentPrice: 242.84,
      volatility: 0.045,
    ),
    TickerData(
      symbol: 'HD',
      name: 'Home Depot',
      historicalWeeklyGrowthRate: 0.0022,
      currentPrice: 356.67,
      volatility: 0.020,
    ),
    TickerData(
      symbol: 'MCD',
      name: 'McDonald\'s',
      historicalWeeklyGrowthRate: 0.0019,
      currentPrice: 298.12,
      volatility: 0.017,
    ),
    TickerData(
      symbol: 'NKE',
      name: 'Nike Inc.',
      historicalWeeklyGrowthRate: 0.0020,
      currentPrice: 114.78,
      volatility: 0.021,
    ),
    TickerData(
      symbol: 'LOW',
      name: 'Lowe\'s Companies',
      historicalWeeklyGrowthRate: 0.0021,
      currentPrice: 246.89,
      volatility: 0.019,
    ),
    TickerData(
      symbol: 'TGT',
      name: 'Target Corp.',
      historicalWeeklyGrowthRate: 0.0018,
      currentPrice: 167.45,
      volatility: 0.023,
    ),

    // Energy
    TickerData(
      symbol: 'XOM',
      name: 'Exxon Mobil',
      historicalWeeklyGrowthRate: 0.0016,
      currentPrice: 105.34,
      volatility: 0.028,
    ),
    TickerData(
      symbol: 'CVX',
      name: 'Chevron Corp.',
      historicalWeeklyGrowthRate: 0.0017,
      currentPrice: 149.78,
      volatility: 0.026,
    ),
    TickerData(
      symbol: 'COP',
      name: 'ConocoPhillips',
      historicalWeeklyGrowthRate: 0.0018,
      currentPrice: 123.45,
      volatility: 0.027,
    ),
    TickerData(
      symbol: 'SLB',
      name: 'Schlumberger',
      historicalWeeklyGrowthRate: 0.0019,
      currentPrice: 56.78,
      volatility: 0.030,
    ),

    // Industrials
    TickerData(
      symbol: 'BA',
      name: 'Boeing Co.',
      historicalWeeklyGrowthRate: 0.0014,
      currentPrice: 212.34,
      volatility: 0.032,
    ),
    TickerData(
      symbol: 'CAT',
      name: 'Caterpillar Inc.',
      historicalWeeklyGrowthRate: 0.0020,
      currentPrice: 278.91,
      volatility: 0.022,
    ),
    TickerData(
      symbol: 'GE',
      name: 'General Electric',
      historicalWeeklyGrowthRate: 0.0021,
      currentPrice: 156.78,
      volatility: 0.024,
    ),
    TickerData(
      symbol: 'HON',
      name: 'Honeywell',
      historicalWeeklyGrowthRate: 0.0022,
      currentPrice: 198.45,
      volatility: 0.018,
    ),
    TickerData(
      symbol: 'UPS',
      name: 'United Parcel',
      historicalWeeklyGrowthRate: 0.0018,
      currentPrice: 167.23,
      volatility: 0.020,
    ),

    // Materials
    TickerData(
      symbol: 'LIN',
      name: 'Linde plc',
      historicalWeeklyGrowthRate: 0.0023,
      currentPrice: 445.67,
      volatility: 0.019,
    ),
    TickerData(
      symbol: 'ECL',
      name: 'Ecolab Inc.',
      historicalWeeklyGrowthRate: 0.0019,
      currentPrice: 234.56,
      volatility: 0.017,
    ),
    TickerData(
      symbol: 'APD',
      name: 'Air Products',
      historicalWeeklyGrowthRate: 0.0020,
      currentPrice: 289.34,
      volatility: 0.021,
    ),

    // Utilities
    TickerData(
      symbol: 'NEE',
      name: 'NextEra Energy',
      historicalWeeklyGrowthRate: 0.0017,
      currentPrice: 178.91,
      volatility: 0.016,
    ),
    TickerData(
      symbol: 'DUK',
      name: 'Duke Energy',
      historicalWeeklyGrowthRate: 0.0015,
      currentPrice: 98.45,
      volatility: 0.014,
    ),
    TickerData(
      symbol: 'SO',
      name: 'Southern Co.',
      historicalWeeklyGrowthRate: 0.0014,
      currentPrice: 78.23,
      volatility: 0.015,
    ),

    // Real Estate
    TickerData(
      symbol: 'AMT',
      name: 'American Tower',
      historicalWeeklyGrowthRate: 0.0021,
      currentPrice: 189.34,
      volatility: 0.018,
    ),
    TickerData(
      symbol: 'PLD',
      name: 'Prologis Inc.',
      historicalWeeklyGrowthRate: 0.0020,
      currentPrice: 134.56,
      volatility: 0.017,
    ),
    TickerData(
      symbol: 'CCI',
      name: 'Crown Castle',
      historicalWeeklyGrowthRate: 0.0018,
      currentPrice: 167.89,
      volatility: 0.019,
    ),

    // Communication Services
    TickerData(
      symbol: 'VZ',
      name: 'Verizon Comm.',
      historicalWeeklyGrowthRate: 0.0013,
      currentPrice: 38.91,
      volatility: 0.018,
    ),
    TickerData(
      symbol: 'T',
      name: 'AT&T Inc.',
      historicalWeeklyGrowthRate: 0.0011,
      currentPrice: 16.78,
      volatility: 0.020,
    ),
    TickerData(
      symbol: 'CMCSA',
      name: 'Comcast Corp.',
      historicalWeeklyGrowthRate: 0.0016,
      currentPrice: 42.34,
      volatility: 0.022,
    ),
    TickerData(
      symbol: 'DIS',
      name: 'Walt Disney',
      historicalWeeklyGrowthRate: 0.0019,
      currentPrice: 89.67,
      volatility: 0.024,
    ),
    TickerData(
      symbol: 'NFLX',
      name: 'Netflix Inc.',
      historicalWeeklyGrowthRate: 0.0027,
      currentPrice: 487.56,
      volatility: 0.033,
    ),

    // Consumer Staples
    TickerData(
      symbol: 'WMT',
      name: 'Walmart Inc.',
      historicalWeeklyGrowthRate: 0.0017,
      currentPrice: 167.89,
      volatility: 0.016,
    ),
    TickerData(
      symbol: 'PG',
      name: 'Procter & Gamble',
      historicalWeeklyGrowthRate: 0.0015,
      currentPrice: 156.34,
      volatility: 0.014,
    ),
    TickerData(
      symbol: 'KO',
      name: 'Coca-Cola Co.',
      historicalWeeklyGrowthRate: 0.0014,
      currentPrice: 61.78,
      volatility: 0.015,
    ),
    TickerData(
      symbol: 'PEP',
      name: 'PepsiCo Inc.',
      historicalWeeklyGrowthRate: 0.0015,
      currentPrice: 178.91,
      volatility: 0.016,
    ),
    TickerData(
      symbol: 'COST',
      name: 'Costco Wholesale',
      historicalWeeklyGrowthRate: 0.0020,
      currentPrice: 567.89,
      volatility: 0.018,
    ),
  ];

  static List<TickerData> getAllTickers() => _tickers;

  static TickerData? getTicker(String symbol) {
    try {
      return _tickers.firstWhere((ticker) => ticker.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  static double getWeightedAverageGrowthRate() {
    if (_tickers.isEmpty) return 0.0;

    final totalGrowth = _tickers
        .map((ticker) => ticker.historicalWeeklyGrowthRate)
        .reduce((a, b) => a + b);

    return totalGrowth / _tickers.length;
  }

  static double getPortfolioVolatility() {
    if (_tickers.isEmpty) return 0.0;

    final totalVolatility = _tickers
        .map((ticker) => ticker.volatility)
        .reduce((a, b) => a + b);

    return totalVolatility / _tickers.length;
  }
}
