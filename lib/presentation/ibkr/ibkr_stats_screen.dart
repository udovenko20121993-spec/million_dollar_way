import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';
import 'package:million_dollar_way/models/sync_settings.dart';
import 'package:million_dollar_way/presentation/ibkr/history_screen.dart';
import 'package:million_dollar_way/presentation/ibkr/sync_settings_screen.dart';
import 'package:million_dollar_way/services/ibkr_service.dart';

class IBKRStatsScreen extends StatelessWidget {
  final String userId = "user_test_1";

  const IBKRStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("IBKR Аналітика"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Кнопка синхронізації
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              final isAutoSync = snapshot.data?.get('isAutoSyncEnabled') ?? false;
              return IconButton(
                icon: Icon(
                  isAutoSync ? Icons.sync : Icons.sync_disabled,
                  color: isAutoSync ? const Color(0xFF00C853) : Colors.grey,
                ),
                tooltip: isAutoSync ? 'Автосинхронізація увімкнена' : 'Автосинхронізація вимкнена',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SyncSettingsScreen(userId: userId),
                    ),
                  );
                },
              );
            },
          ),
          // Кнопка налаштувань
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SyncSettingsScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          docs.sort((a, b) {
            final tA = (a.data() as Map)['lastSyncTime'];
            final tB = (b.data() as Map)['lastSyncTime'];
            if (tA == null) return 1;
            if (tB == null) return -1;
            return (tB as Timestamp).compareTo(tA as Timestamp);
          });

          final report = IBKRReport.fromFirestore(docs.first);

          // Використовуємо DefaultTabController для вкладок всередині екрану
          return DefaultTabController(
            length: 2, // Дві головні вкладки: Огляд та Деталі
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: Color(0xFF00C853),
                  labelColor: Color(0xFF00C853),
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Головна"),
                    Tab(text: "Історія & Дивіденди"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // ВКЛАДКА 1: ОГЛЯД (Картки)
                      _buildOverviewTab(report),

                      // ВКЛАДКА 2: ІСТОРІЯ (Тут вбудовуємо ваш HistoryScreen)
                      HistoryScreen(
                        dividends: report.dividends,
                        trades: report.trades,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(IBKRReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Статус синхронізації
          _buildSyncStatusCard(report),
          const SizedBox(height: 16),
          
          _buildBigCard(
            title: "Загальний Баланс",
            value: "${report.lastBalance.toStringAsFixed(2)}\$",
            color: const Color(0xFF00C853),
            icon: Icons.account_balance_wallet,
          ),
          const SizedBox(height: 16),
          _buildBigCard(
            title: "Вільний Кеш",
            value: "${report.cashBalance.toStringAsFixed(2)}\$",
            color: Colors.blueAccent,
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 16),
          _buildBigCard(
            title: "Всього Дивідендів",
            value: "${report.totalDividends.toStringAsFixed(2)}\$",
            color: Colors.orangeAccent,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 16),
          // Комісії
          _buildBigCard(
            title: "Комісії",
            value: "-${report.totalCommissions.toStringAsFixed(2)}\$",
            color: Colors.redAccent,
            icon: Icons.receipt_long,
          ),
          const SizedBox(height: 16),
          // Додаткова інформація про депозити
          Row(
            children: [
              Expanded(
                child: _buildSmallCard(
                  "Внесено",
                  report.totalDeposits,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallCard(
                  "Виведено",
                  report.totalWithdrawals,
                  Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard(IBKRReport report) {
    final lastSync = report.lastSyncTime;
    final lastSyncStr = IbkrService.formatLastSyncTime(lastSync);
    final hasError = report.lastError != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError 
            ? Colors.redAccent.withOpacity(0.1) 
            : const Color(0xFF00C853).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError 
              ? Colors.redAccent.withOpacity(0.3) 
              : const Color(0xFF00C853).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.check_circle_outline,
            color: hasError ? Colors.redAccent : const Color(0xFF00C853),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError ? 'Помилка синхронізації' : 'Остання синхронізація',
                  style: TextStyle(
                    color: hasError ? Colors.redAccent : Colors.grey,
                    fontSize: 11,
                  ),
                ),
                Text(
                  hasError ? (report.lastError ?? 'Невідома помилка') : lastSyncStr,
                  style: TextStyle(
                    color: hasError ? Colors.redAccent : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Кнопка ручної синхронізації
          if (report.isSyncRequired)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00C853),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF00C853)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('reports')
                    .doc(report.id)
                    .update({'isSyncRequired': true});
              },
              tooltip: 'Оновити зараз',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildBigCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            "${value.toStringAsFixed(2)}\$",
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
