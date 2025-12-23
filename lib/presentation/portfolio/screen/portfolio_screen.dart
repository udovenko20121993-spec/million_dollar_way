import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/remote/firestore_service.dart';
import '../../../models/ibkr_data.dart';

class PortfolioCatalogScreen extends StatelessWidget {
  final String userId = "user_test_1";
  const PortfolioCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Каталог звітів IBKR",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<IBKRReport>>(
        stream: FirestoreService().getReports(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final lastSyncStr = report.lastSyncTime != null
                  ? DateFormat('dd.MM HH:mm').format(report.lastSyncTime!)
                  : "Ніколи";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  title: Text(
                    report.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    report.isSyncRequired
                        ? "Оновлюється сервером..."
                        : "Оновлено: $lastSyncStr",
                    style: TextStyle(
                      color: report.isSyncRequired
                          ? Colors.orange
                          : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${report.lastBalance.toStringAsFixed(2)}\$",
                        style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Якщо йде синхронізація - показуємо спінер, якщо ні - кнопку
                      report.isSyncRequired
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Color(0xFF00C853),
                              ),
                              onPressed: () => FirestoreService()
                                  .triggerManualSync(userId, report.id),
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
