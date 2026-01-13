import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';
import 'package:million_dollar_way/presentation/reports/report_catalog_screen.dart';
// ІМПОРТ НОВОГО ГРАФІКА
import 'package:million_dollar_way/presentation/dashboard/widgets/capital_chart.dart';

class IBKRDashboard extends StatelessWidget {
  final String userId = "user_test_1";

  const IBKRDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Мій Портфель'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF00C853)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IBKRReportCatalogScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar вже обробляє верх
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('reports')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  "Дані відсутні.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

          // Сортуємо звіти (найсвіжіший зверху)
          docs.sort((a, b) {
            final tA = (a.data() as Map)['lastSyncTime'];
            final tB = (b.data() as Map)['lastSyncTime'];
            if (tA == null) return 1;
            if (tB == null) return -1;
            return (tB as Timestamp).compareTo(tA as Timestamp);
          });

          final report = IBKRReport.fromFirestore(docs.first);

          // --- ЛОГІКА РОЗРАХУНКІВ ---
          double totalDeposits = report.totalDeposits;
          double totalWithdrawals =
              report.totalWithdrawals; // Зазвичай мінусове число

          // Нетто = Внесення + Виведення (оскільки виведення вже з мінусом)
          double netFlow = totalDeposits + totalWithdrawals;

          // Зміна NAV = Поточний Баланс - (Внесене чистими)
          double changeInNav = report.lastBalance - netFlow;
          // ---------------------------

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Картка з сумою капіталу
                _buildCapitalCard(report.lastBalance, report.cashBalance),

                // 2. Заголовок графіка
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Динаміка капіталу",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 3. --- ВАШ НОВИЙ ГРАФІК ---
                CapitalChart(trades: report.trades),
                // ---------------------------

                // 4. Таблиця статистики (NAV, Внесення)
                _buildNavStats(
                  report.lastBalance,
                  changeInNav,
                  totalDeposits,
                  totalWithdrawals,
                  netFlow,
                ),

                // 5. Заголовок активів
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Позиції",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${report.assets.length} активів",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                if (report.assets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Активів немає",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                // 6. Список активів
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: report.assets.length,
                  itemBuilder: (context, index) =>
                      _buildAssetTile(report.assets[index]),
                ),
                const SizedBox(height: 80), // Відступ знизу
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  // --- ДОПОМІЖНІ ВІДЖЕТИ ---

  Widget _buildCapitalCard(double capital, double cash) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00C853),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Загальний капітал",
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            "${capital.toStringAsFixed(2)}\$",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Вільний кеш: ${cash.toStringAsFixed(2)}\$",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavStats(
    double endNav,
    double change,
    double deposits,
    double withdrawals,
    double net,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Зміна в NAV",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn("Початок", "0.00"),
              _buildStatColumn("Кінець", endNav.toStringAsFixed(2)),
              _buildStatColumn(
                "Зміна",
                "${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}",
                color: change >= 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          const Text(
            "Внесення та виведення коштів (USD)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn("Внесення", deposits.toStringAsFixed(2)),
              _buildStatColumn(
                "Виведення",
                withdrawals.toStringAsFixed(2),
                color: Colors.white70,
              ),
              _buildStatColumn(
                "Нетто",
                "${net >= 0 ? '+' : ''}${net.toStringAsFixed(2)}",
                color: net >= 0 ? Colors.white : Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value, {
    Color color = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetTile(IBKRAsset asset) {
    String quantityStr = asset.quantity < 1
        ? asset.quantity.toStringAsFixed(4)
        : asset.quantity.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: Text(
            asset.symbol.isNotEmpty ? asset.symbol.substring(0, 1) : "?",
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          asset.symbol,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "$quantityStr шт",
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${asset.value.toStringAsFixed(2)}\$",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${asset.change >= 0 ? '+' : ''}${asset.change.toStringAsFixed(2)}\$",
              style: TextStyle(
                color: asset.change >= 0
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
