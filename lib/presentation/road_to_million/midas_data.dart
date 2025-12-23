import 'dart:math' as math;

// --- СПИСОК ТІКЕРІВ ---
final List<String> tickersList = [
  "AAPL",
  "NVDA",
  "MSFT",
  "ADBE",
  "AMZN",
  "GOOGL",
  "TSLA",
  "META",
  "KO",
  "PEP",
  "MCD",
  "WMT",
  "COST",
  "PG",
  "JNJ",
  "JPM",
  "V",
  "MA",
  "BAC",
  "XOM",
  "CVX",
  "T",
  "VZ",
  "ADP",
  "AFL",
  "AMAT",
  "AMGN",
  "APH",
  "AXON",
  "BA",
  "BKNG",
  "BRO",
  "CHD",
  "CMCSA",
  "CPRT",
  "CSCO",
  "CTAS",
  "EXPD",
  "FAST",
  "FICO",
  "GILD",
  "HD",
  "IBKR",
  "IDXX",
  "ISRG",
  "KLAC",
  "LOW",
  "LRCX",
  "MNST",
  "NUE",
  "ODFL",
];

// --- ТИПИ СОРТУВАННЯ ---
enum SortType { profitDesc, profitAsc, nameAsc, valueDesc }

// --- ДОПОМІЖНІ ФУНКЦІЇ ---

// Форматування грошей (1000 -> 1 000)
String formatMoney(double value) {
  return value
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
}

// Отримання повної назви (спрощено для прикладу)
String getStockName(String ticker) => "$ticker Corp";

// Профіль акції (ціна та ріст)
Map<String, double> getStockProfile(String ticker) {
  if ([
    "AAPL",
    "NVDA",
    "MSFT",
    "TSLA",
    "AMZN",
    "GOOGL",
    "META",
  ].contains(ticker)) {
    // Технологічні гіганти
    return {"price": 180.0, "growth": 0.25};
  }
  // Консервативні
  return {"price": 50.0, "growth": 0.12};
}

// Генерація історії цін для графіку
List<Map<String, dynamic>> generateHistory(
  double currentPrice,
  int yearsTotal,
) {
  List<Map<String, dynamic>> data = [];
  // Генеруємо 6 точок для графіку
  // Крок між точками залежить від загальної кількості років
  int step = (yearsTotal / 5).ceil();
  if (step < 1) step = 1;

  for (int i = 0; i < 6; i++) {
    int year = DateTime.now().year - (i * step);
    // Чим далі в минуле, тим менша ціна (експоненційний спад)
    double historicalPrice = currentPrice / math.pow(1.15, i * step);

    data.add({'year': year, 'price': historicalPrice});
  }
  return data.reversed.toList();
}
