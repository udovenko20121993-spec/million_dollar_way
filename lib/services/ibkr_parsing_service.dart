import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ibkr_import_service_v2.dart';
import '../domain/models/upload_log_model.dart';
import '../domain/models/transaction_model.dart';

/// Service wrapper for IBKR parsing operations
/// This service provides a consistent interface for IBKR data parsing
class IbkrParsingService {
  /// Get upload history stream for a user
  static Stream<List<UploadLogModel>> getUploadHistory(String userId) {
    return IbkrImportService.getUploadHistory(userId);
  }

  /// Upload a file and process it
  static Future<UploadLogModel> uploadFile({
    required String userId,
    required File file,
  }) async {
    return IbkrImportService.uploadFile(
      userId: userId,
      file: file,
    );
  }

  /// Parse XML content and batch save transactions
  static Future<UploadLogModel> parseAndBatchSave({
    required String xmlContent,
    required String userId,
    required UploadSourceType sourceType,
    String? fileName,
    String? queryId,
  }) async {
    return IbkrImportService.processReport(
      xmlContent: xmlContent,
      userId: userId,
      sourceType: sourceType,
      fileName: fileName,
      queryId: queryId,
    );
  }

  /// Get transactions by account ID
  static Future<List<TransactionModel>> getTransactionsByAccount({
    required String userId,
    required String accountId,
  }) async {
    // Query transactions filtered by accountId
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('accountId', isEqualTo: accountId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  /// Get all unique account IDs for a user
  static Future<List<String>> getUserAccountIds(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    final accountIds = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['accountId'] != null) {
        accountIds.add(data['accountId'] as String);
      }
    }

    return accountIds.toList()..sort();
  }

  /// Get account upload statistics
  static Future<Map<String, dynamic>> getAccountUploadStats(
    String userId,
  ) async {
    return IbkrImportService.getUploadStats(userId);
  }
}
