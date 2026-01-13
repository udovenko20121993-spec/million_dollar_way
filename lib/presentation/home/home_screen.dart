import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';
import 'package:million_dollar_way/presentation/dashboard/widgets/capital_chart.dart';

class HomeScreen extends StatelessWidget {
  final String userId = "user_test_1";

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_graph, color: Color(0xFF00C853)),
            SizedBox(width: 10),
            Text(
              'Million Dollar Way',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        centerTitle: false,
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
                "Дані відсутні",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Сортуємо (найсвіжіший звіт зверху)
          docs.sort((a, b) {
            final tA = (a.data() as Map)['lastSyncTime'];
            final tB = (b.data() as Map)['lastSyncTime'];
            if (tA == null) return 1;
            if (tB == null) return -1;
            return (tB as Timestamp).compareTo(tA as Timestamp);
          });

          final report = IBKRReport.fromFirestore(docs.first);

          // Розрахунки
          double netFlow = report.totalDeposits + report.totalWithdrawals;
          double profit = report.lastBalance - netFlow;
          double profitPercent = netFlow != 0
              ? (profit / netFlow.abs()) * 100
              : 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ГОЛОВНА КАРТКА (Баланс + Прибуток)
                _buildMainCard(report.lastBalance, profit, profitPercent),

                const SizedBox(height: 24),

                // 2. СТАТИСТИКА (Плитки 2x2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          "Дивіденди",
                          "+${report.totalDividends.toStringAsFixed(2)}\$",
                          Icons.attach_money,
                          Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          "Комісії",
                          "${report.totalCommissions.toStringAsFixed(2)}\$",
                          Icons.receipt_long,
                          Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          "Внесено",
                          "${report.totalDeposits.toStringAsFixed(0)}\$",
                          Icons.arrow_downward,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          "Виведено",
                          "${report.totalWithdrawals.toStringAsFixed(0)}\$",
                          Icons.arrow_upward,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 3. ГРАФІК КАПІТАЛУ
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Динаміка",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CapitalChart(trades: report.trades),

                // --- СПИСОК АКТИВІВ ВИДАЛЕНО ---
                const SizedBox(height: 50),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  // Віджет головної картки
  Widget _buildMainCard(double balance, double profit, double percent) {
    bool isPos = profit >= 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF0F0F0F).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: (isPos ? const Color(0xFF00C853) : Colors.red).withOpacity(
              0.15,
            ),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Загальний капітал",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "${balance.toStringAsFixed(2)}\$",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isPos ? Colors.green : Colors.red).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPos ? Icons.trending_up : Icons.trending_down,
                  color: isPos ? const Color(0xFF00C853) : Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "${isPos ? '+' : ''}${profit.toStringAsFixed(2)}\$ (${percent.toStringAsFixed(2)}%)",
                  style: TextStyle(
                    color: isPos ? const Color(0xFF00C853) : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Віджет плитки статистики
  Widget _buildStatTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
