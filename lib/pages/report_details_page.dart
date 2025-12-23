import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ibkr_history_page.dart'; // Імпортуємо сторінку з вкладками, яку ми створили раніше

class ReportDetailsPage extends StatelessWidget {
  final String reportId;
  final String userId;

  const ReportDetailsPage({
    super.key,
    required this.reportId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // Слухаємо дані з Firebase у реальному часі
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reports')
          .doc(reportId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // Викликаємо наш новий дизайн із вкладками
        return IbkrHistoryPage(reportData: data);
      },
    );
  }
}
