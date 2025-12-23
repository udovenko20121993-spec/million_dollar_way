import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Якщо потрібно форматувати дати, додайте це

class IbkrHistoryPage extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const IbkrHistoryPage({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    // Витягуємо списки
    final trades = List<Map<String, dynamic>>.from(reportData['trades'] ?? []);
    final dividends = List<Map<String, dynamic>>.from(
      reportData['dividends'] ?? [],
    );
    final cash = List<Map<String, dynamic>>.from(
      reportData['cashTransactions'] ?? [],
    );

    // Сортуємо за датою (спочатку нові)
    trades.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    dividends.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    cash.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Історія операцій",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.candlestick_chart), text: "Угоди"),
              Tab(icon: Icon(Icons.attach_money), text: "Дивіденди"),
              Tab(icon: Icon(Icons.account_balance_wallet), text: "Кеш"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTradesList(
              trades,
              reportData,
            ), // Передаємо весь звіт для доступу до totals
            _buildDividendsList(dividends),
            _buildCashList(cash),
          ],
        ),
      ),
    );
  }

  // --- Вкладка 1: Угоди ---
  Widget _buildTradesList(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> reportData,
  ) {
    if (items.isEmpty) return _emptyState("Угод поки немає");

    // Отримуємо загальну комісію (беремо з бази або рахуємо "на льоту")
    double totalComm =
        reportData['totalCommissions'] ??
        items.fold(
          0,
          (sum, item) => sum + (item['commission'] as double? ?? 0),
        );

    return Column(
      children: [
        // Картка загальної комісії
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1), // Світло-червоний фон
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text(
                "Всього сплачено комісій",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "${totalComm.toStringAsFixed(2)} \$", // Покажемо як є (наприклад -15.40 $)
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Список угод
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isBuy = item['action'] == 'BUY';
              final commission = item['commission'] as double? ?? 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBuy
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['symbol'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Відображення комісії в конкретній угоді
                      if (commission != 0)
                        Text(
                          "Com: ${commission.toStringAsFixed(2)}\$",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    "${item['date']} • ${item['quantity']} шт. по \$${item['price']}",
                  ),
                  trailing: Text(
                    "${isBuy ? '-' : '+'}\$${(item['quantity'] * item['price']).toStringAsFixed(2)}",
                    style: TextStyle(
                      color: isBuy ? Colors.black : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Вкладка 2: Дивіденди ---
  Widget _buildDividendsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _emptyState("Дивідендів ще немає");
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(
                "\$",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item['symbol'] == 'DIV' ? 'Дивіденди' : item['symbol'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item['date']),
            trailing: Text(
              "+\$${item['amount'].toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Вкладка 3: Кеш (Депозити/Виведення) ---
  Widget _buildCashList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _emptyState("Транзакцій немає");
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final amount = item['amount'] as double;
        final isDeposit = amount > 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              isDeposit ? Icons.add_circle : Icons.remove_circle,
              color: isDeposit ? Colors.green : Colors.orange,
              size: 32,
            ),
            title: Text(
              isDeposit ? "Поповнення" : "Виведення",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item['date']),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isDeposit ? '+' : ''}${amount.toStringAsFixed(2)} \$",
                  style: TextStyle(
                    color: isDeposit ? Colors.green : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Якщо є оригінальна валюта, покажемо дрібним шрифтом
                if (item['originalAmount'] != null && item['currency'] != 'USD')
                  Text(
                    "${item['originalAmount']} ${item['currency']}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }
}
