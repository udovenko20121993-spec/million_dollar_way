import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ibkr_data.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Отримуємо список усіх звітів користувача
  Stream<List<IBKRReport>> getReports(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IBKRReport.fromFirestore(doc))
              .toList(),
        );
  }

  // Функція для кнопки "Refresh"
  Future<void> triggerManualSync(String userId, String reportId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .update({'isSyncRequired': true});
  }
}
