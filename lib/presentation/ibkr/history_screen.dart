import 'package:flutter/material.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';

class HistoryScreen extends StatelessWidget {
  final List<IBKRDividend> dividends;
  final List<IBKRTrade> trades;

  const HistoryScreen({
    super.key,
    required this.dividends,
    required this.trades,
  });

  // --- НОВА ФУНКЦІЯ: Красивий формат кількості ---
  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          title: const Text("Історія та Аналітика"),
          backgroundColor: const Color(0xFF1A1A1A),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00C853),
            labelColor: Color(0xFF00C853),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Дивіденди"),
              Tab(text: "Торгівля"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildGroupedDividendsList(), _buildGroupedTradesList()],
        ),
      ),
    );
  }

  // --- 1. ГРУПУВАННЯ ДИВІДЕНДІВ (Без змін) ---
  Widget _buildGroupedDividendsList() {
    if (dividends.isEmpty) {
      return const Center(
        child: Text("Дивідендів немає", style: TextStyle(color: Colors.grey)),
      );
    }

    final Map<String, List<IBKRDividend>> grouped = {};
    for (var div in dividends) {
      if (!grouped.containsKey(div.symbol)) grouped[div.symbol] = [];
      grouped[div.symbol]!.add(div);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final symbol = sortedKeys[index];
        final history = grouped[symbol]!;

        double totalEarned = 0;
        for (var h in history) {
          totalEarned += h.amount;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00C853).withOpacity(0.2),
                child: Text(
                  symbol.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${history.length} виплат(и)",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Text(
                "+${totalEarned.toStringAsFixed(2)}\$",
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              children: history.map((div) {
                String dateStr = _formatDate(div.date);
                return Container(
                  color: Colors.black12,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    visualDensity: VisualDensity.compact,
                    title: const Text(
                      "Виплата",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    subtitle: Text(
                      dateStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    trailing: Text(
                      "+${div.amount.toStringAsFixed(2)}\$",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // --- 2. ГРУПУВАННЯ ТОРГІВ ---
  Widget _buildGroupedTradesList() {
    if (trades.isEmpty) {
      return const Center(
        child: Text(
          "Історії торгів немає",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 1. Групуємо по Тікеру
    final Map<String, List<IBKRTrade>> grouped = {};
    for (var trade in trades) {
      if (!grouped.containsKey(trade.symbol)) grouped[trade.symbol] = [];
      grouped[trade.symbol]!.add(trade);
    }

    // 2. Сортуємо А-Я
    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final symbol = sortedKeys[index];
        final history = grouped[symbol]!;

        // 3. Рахуємо статистику по групі
        double netQuantity = 0; // Скільки акцій додалось/зменшилось
        double netInvested = 0; // Грошовий потік (Мінус = купив, Плюс = продав)

        for (var t in history) {
          bool isBuy = t.action.toUpperCase() == 'BUY';
          double totalCost = t.price * t.quantity;

          if (isBuy) {
            netQuantity += t.quantity;
            netInvested -= totalCost; // Витратив гроші
          } else {
            netQuantity -= t.quantity;
            netInvested += totalCost; // Отримав гроші
          }
        }

        // Сортуємо всередині групи (найновіші зверху)
        history.sort((a, b) => b.date.compareTo(a.date));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              // ЗАГОЛОВОК ГРУПИ
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: Text(
                  symbol.isNotEmpty ? symbol.substring(0, 1) : "?",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${history.length} угод(и)",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Використовуємо _formatQty для заголовку групи
                  Text(
                    "${netQuantity >= 0 ? '+' : ''}${_formatQty(netQuantity)} шт",
                    style: TextStyle(
                      color: netQuantity >= 0 ? Colors.white : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "${netInvested >= 0 ? '+' : ''}${netInvested.toStringAsFixed(2)}\$",
                    style: TextStyle(
                      color: netInvested >= 0
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              // ДЕТАЛІ (СПИСОК УГОД)
              children: history.map((trade) {
                bool isBuy = trade.action.toUpperCase() == 'BUY';
                String dateStr = _formatDate(trade.date);
                double total = trade.price * trade.quantity;

                return Container(
                  color: Colors.black12,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    title: Text(
                      isBuy ? "Купівля" : "Продаж",
                      style: TextStyle(
                        color: isBuy ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "$dateStr • ${trade.price.toStringAsFixed(2)}\$",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    // Використовуємо _formatQty для конкретної угоди
                    trailing: Text(
                      "${_formatQty(trade.quantity)} шт = ${total.toStringAsFixed(2)}\$",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Допоміжна функція для дати
  String _formatDate(String rawDate) {
    String dateStr = rawDate;
    if (dateStr.contains(';')) dateStr = dateStr.split(';')[0];
    try {
      if (dateStr.length == 8) {
        return "${dateStr.substring(6, 8)}.${dateStr.substring(4, 6)}.${dateStr.substring(0, 4)}";
      }
    } catch (_) {}
    return dateStr;
  }
}
