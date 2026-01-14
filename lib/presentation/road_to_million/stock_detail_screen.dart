import 'package:flutter/material.dart';
import 'midas_data.dart'; // Підключаємо файл з даними
import '../../services/stock_logo_service.dart';

class StockDetailScreen extends StatelessWidget {
  final Map<String, dynamic> stock;
  final bool useBot;
  final int yearsTotal;

  const StockDetailScreen({
    super.key,
    required this.stock,
    required this.useBot,
    this.yearsTotal = 20,
  });

  @override
  Widget build(BuildContext context) {
    double marketPrice = stock['currentPrice'];
    double myPrice = stock['avgPrice'];
    double discount = marketPrice - myPrice;

    final history = generateHistory(marketPrice, yearsTotal);

    // --- ЛОГІКА РОЗРАХУНКУ ІСТОРІЇ ---
    // 1. Скільки всього грошей вкладено (Qty * AvgPrice)
    double totalInvestedReal = stock['qty'] * stock['avgPrice'];
    // 2. Ділимо на кількість періодів, щоб дізнатися суму одного внеску
    double moneyPerPeriod = totalInvestedReal / history.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: Text(
          stock['name'],
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // SafeArea гарантує, що контент не сховається під системними кнопками
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ГОЛОВНІ ЦИФРИ
                Center(
                  child: Column(
                    children: [
                      // Логотип акції
                      StockLogo(
                        symbol: stock['symbol'],
                        size: 70,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "${formatMoney(stock['qty'] * marketPrice)} \$",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "Ваш капітал в ${stock['symbol']}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 2. ПОРІВНЯННЯ ЦІН
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _priceBox(
                            "Ринок платить",
                            "${marketPrice.toStringAsFixed(2)}\$",
                            Colors.white,
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white24,
                          ),
                          _priceBox(
                            "Ви платите",
                            "${myPrice.toStringAsFixed(2)}\$",
                            const Color(0xFF00C853),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 30),
                      Text(
                        "ЕКОНОМІЯ НА 1 АКЦІЇ: +${discount.toStringAsFixed(2)}\$",
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. ПОЯСНЕННЯ (СЕКРЕТ УСПІХУ)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ЗВІДКИ ТАКИЙ ПРИБУТОК?",
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              useBot
                                  ? "Секрет у часі та алгоритмі. Ви почали купувати цю акцію $yearsTotal років тому, коли вона коштувала копійки. Бот автоматично докуповував більше штук, коли ціна була низькою (див. графік нижче)."
                                  : "Секрет у часі. Ви почали купувати цю акцію $yearsTotal років тому, коли вона коштувала значно дешевше. Ваша низька середня ціна сформувалася завдяки старим покупкам.",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  "ХРОНОЛОГІЯ УСПІХУ",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 15),

                // 4. ІСТОРІЯ (TIMELINE)
                ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    bool isLast = index == history.length - 1;

                    double historicalPrice = item['price'];
                    // Правильна формула: Гроші / Ціна = Кількість штук
                    double sharesBoughtAtThatTime =
                        moneyPerPeriod / historicalPrice;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isLast
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                                border: isLast
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 50,
                                color: Colors.white10,
                              ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Рік ${item['year']}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Ціна: ${historicalPrice.toStringAsFixed(2)}\$",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "Куплено: +${sharesBoughtAtThatTime.toStringAsFixed(1)} шт",
                                      style: TextStyle(
                                        color: isLast
                                            ? Colors.grey
                                            : const Color(0xFF00C853),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Відступ для комфортного скролу
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceBox(String label, String price, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          price,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
