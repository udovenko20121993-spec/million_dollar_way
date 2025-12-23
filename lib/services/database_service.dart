import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Збереження нового звіту
  Future<void> saveReport({
    required String name,
    required double amount,
    required String type,
    String queryId = '',
  }) async {
    await _db.collection('reports').add({
      'name': name,
      'amount': amount,
      'type': type,
      'queryId': queryId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ВИДАЛЕННЯ звіту за ID
  Future<void> deleteReport(String docId) async {
    await _db.collection('reports').doc(docId).delete();
  }

  // Отримання потоку звітів
  Stream<QuerySnapshot> getReportsStream() {
    return _db
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
