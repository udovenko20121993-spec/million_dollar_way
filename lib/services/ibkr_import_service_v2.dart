import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import '../domain/models/transaction_model.dart';
import '../domain/models/upload_log_model.dart';

class IbkrImportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _batchSize =
      400; // Firestore limit is 500, using 400 for safety

  /// Process IBKR report (XML) with idempotent batch writes
  static Future<UploadLogModel> processReport({
    required String xmlContent,
    required String userId,
    required UploadSourceType sourceType,
    String? fileName,
    String? queryId,
  }) async {
    // Create upload log entry
    final uploadLog = UploadLogModel(
      id: '', // Will be set by Firestore
      userId: userId,
      status: UploadStatus.pending,
      sourceType: sourceType,
      fileName: fileName,
      queryId: queryId,
      stats: const UploadStats(processed: 0, saved: 0),
      timestamp: DateTime.now(),
    );

    // Save initial upload log
    final logDocRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('uploads')
        .add(uploadLog.toFirestore());

    final updatedLog = uploadLog.copyWith(id: logDocRef.id);

    try {
      // Update status to processing
      await _updateUploadStatus(logDocRef, UploadStatus.processing);

      // Parse XML and extract transactions
      final transactions = await _parseIBKRXml(xmlContent, userId);

      if (transactions.isEmpty) {
        await _updateUploadStatus(
          logDocRef,
          UploadStatus.completed,
          stats: const UploadStats(processed: 0, saved: 0),
        );
        return updatedLog.copyWith(
          status: UploadStatus.completed,
          stats: const UploadStats(processed: 0, saved: 0),
        );
      }

      // Process transactions in batches
      final stats = await _processTransactionsInBatches(transactions, userId);

      // Update final status
      await _updateUploadStatus(
        logDocRef,
        UploadStatus.completed,
        stats: stats,
        completedAt: DateTime.now(),
      );

      return updatedLog.copyWith(
        status: UploadStatus.completed,
        stats: stats,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      // Update status to error
      await _updateUploadStatus(
        logDocRef,
        UploadStatus.error,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );

      return updatedLog.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  /// Parse IBKR XML and extract transaction data
  static Future<List<TransactionModel>> _parseIBKRXml(
    String xmlContent,
    String userId,
  ) async {
    try {
      final document = XmlDocument.parse(xmlContent);
      final transactions = <TransactionModel>[];

      // Parse different types of IBKR data
      final trades = document.findAllElements('Trade');
      final cashTransactions = document.findAllElements('CashTransaction');
      final corporateActions = document.findAllElements('CorporateAction');
      final dividends = document.findAllElements('Dividend');

      // Process trades
      for (final tradeElement in trades) {
        final tradeData = _elementToMap(tradeElement);
        final transaction = TransactionModel.fromIBKRData(
          ibkrData: tradeData,
          userId: userId,
        );
        transactions.add(transaction);
      }

      // Process cash transactions
      for (final cashElement in cashTransactions) {
        final cashData = _elementToMap(cashElement);
        final transaction = TransactionModel.fromIBKRData(
          ibkrData: cashData,
          userId: userId,
        );
        transactions.add(transaction);
      }

      // Process dividends
      for (final dividendElement in dividends) {
        final dividendData = _elementToMap(dividendElement);
        final transaction = TransactionModel.fromIBKRData(
          ibkrData: dividendData,
          userId: userId,
        );
        transactions.add(transaction);
      }

      // Process corporate actions
      for (final actionElement in corporateActions) {
        final actionData = _elementToMap(actionElement);
        final transaction = TransactionModel.fromIBKRData(
          ibkrData: actionData,
          userId: userId,
        );
        transactions.add(transaction);
      }

      return transactions;
    } catch (e) {
      throw Exception('Failed to parse IBKR XML: $e');
    }
  }

  /// Convert XML element to Map
  static Map<String, dynamic> _elementToMap(XmlElement element) {
    final data = <String, dynamic>{};

    for (final child in element.children) {
      if (child is XmlElement) {
        data[child.localName] = child.innerText;
      }
    }

    // Add element attributes as well
    for (final attr in element.attributes) {
      data[attr.localName] = attr.value;
    }

    return data;
  }

  /// Process transactions in batches using Firestore batch operations
  static Future<UploadStats> _processTransactionsInBatches(
    List<TransactionModel> transactions,
    String userId,
  ) async {
    int totalProcessed = 0;
    int totalSaved = 0;
    int totalDuplicates = 0;
    int totalErrors = 0;

    final transactionsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');

    // Process in batches
    for (int i = 0; i < transactions.length; i += _batchSize) {
      final batch = _firestore.batch();
      final batchEnd = (i + _batchSize < transactions.length)
          ? i + _batchSize
          : transactions.length;

      final batchTransactions = transactions.sublist(i, batchEnd);

      for (final transaction in batchTransactions) {
        try {
          // Use set() with merge option for idempotency
          // Document ID is the IBKR unique ID
          final docRef = transactionsRef.doc(transaction.documentId);
          batch.set(docRef, transaction.toFirestore(), SetOptions(merge: true));

          totalSaved++;
        } catch (e) {
          totalErrors++;
          print('Error processing transaction ${transaction.id}: $e');
        }
      }

      try {
        await batch.commit();
        totalProcessed += batchTransactions.length;
      } catch (e) {
        totalErrors += batchTransactions.length;
        print('Error committing batch: $e');
      }

      // Small delay to avoid Firestore rate limits
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return UploadStats(
      processed: totalProcessed,
      saved: totalSaved,
      duplicates: totalProcessed - totalSaved - totalErrors,
      errors: totalErrors,
    );
  }

  /// Update upload status in Firestore
  static Future<void> _updateUploadStatus(
    DocumentReference logDocRef,
    UploadStatus status, {
    UploadStats? stats,
    String? errorMessage,
    DateTime? completedAt,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.name,
      'updatedAt': Timestamp.now(),
    };

    if (stats != null) {
      updateData['stats'] = stats.toMap();
    }

    if (errorMessage != null) {
      updateData['errorMessage'] = errorMessage;
    }

    if (completedAt != null) {
      updateData['completedAt'] = Timestamp.fromDate(completedAt);
    }

    await logDocRef.update(updateData);
  }

  /// Get upload history for a user
  static Stream<List<UploadLogModel>> getUploadHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('uploads')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UploadLogModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Fetch and sync Flex Query report from IBKR API
  static Future<UploadLogModel> fetchAndSyncFlexReport({
    required String userId,
    required String flexToken,
    required String queryId,
  }) async {
    try {
      // Step 1: Send request to IBKR
      const requestUrl = 'https://api.ibkr.com/v1/api/tickle';
      final requestResponse = await http.post(
        Uri.parse(requestUrl),
        headers: {
          'Authorization': 'Bearer $flexToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'q=$queryId',
      );

      if (requestResponse.statusCode != 200) {
        throw Exception(
          'Failed to send Flex Query request: ${requestResponse.body}',
        );
      }

      // Extract reference code from response
      final referenceCode = _extractReferenceCode(requestResponse.body);
      if (referenceCode == null) {
        throw Exception('No reference code found in response');
      }

      // Step 2: Get statement
      await Future.delayed(const Duration(seconds: 2)); // Wait for processing

      const statementUrl = 'https://api.ibkr.com/v1/api/statement';
      final statementResponse = await http.get(
        Uri.parse(
          '$statementUrl?reference_code=$referenceCode&token=$flexToken',
        ),
      );

      if (statementResponse.statusCode != 200) {
        throw Exception(
          'Failed to get Flex Query statement: ${statementResponse.body}',
        );
      }

      // Step 3: Process the XML report
      return await processReport(
        xmlContent: statementResponse.body,
        userId: userId,
        sourceType: UploadSourceType.flex_auto,
        queryId: queryId,
      );
    } catch (e) {
      throw Exception('Flex Query sync failed: $e');
    }
  }

  /// Extract reference code from IBKR response
  static String? _extractReferenceCode(String responseBody) {
    try {
      final document = XmlDocument.parse(responseBody);
      final referenceElement = document.findAllElements('ReferenceCode').first;
      return referenceElement.innerText;
    } catch (e) {
      return null;
    }
  }

  /// Manual file upload
  static Future<UploadLogModel> uploadFile({
    required String userId,
    required File file,
  }) async {
    try {
      final xmlContent = await file.readAsString();

      return await processReport(
        xmlContent: xmlContent,
        userId: userId,
        sourceType: UploadSourceType.manual,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  /// Get transactions for a user (with pagination)
  static Future<List<TransactionModel>> getTransactions({
    required String userId,
    int limit = 100,
    TransactionModel? lastTransaction,
  }) async {
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(limit);

    if (lastTransaction != null) {
      query = query.startAfterDocument(
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(lastTransaction.documentId)
            .get(),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  /// Get transactions by symbol
  static Future<List<TransactionModel>> getTransactionsBySymbol(
    String userId,
    String symbol,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('symbol', isEqualTo: symbol)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  /// Delete transaction (for debugging/admin purposes)
  static Future<void> deleteTransaction(
    String userId,
    String transactionId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  /// Get upload statistics for a user
  static Future<Map<String, dynamic>> getUploadStats(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('uploads')
        .get();

    int totalUploads = 0;
    int successfulUploads = 0;
    int failedUploads = 0;
    int totalTransactions = 0;

    for (final doc in snapshot.docs) {
      final upload = UploadLogModel.fromFirestore(doc);
      totalUploads++;

      if (upload.status == UploadStatus.completed) {
        successfulUploads++;
        totalTransactions += upload.stats.saved;
      } else if (upload.status == UploadStatus.error) {
        failedUploads++;
      }
    }

    return {
      'totalUploads': totalUploads,
      'successfulUploads': successfulUploads,
      'failedUploads': failedUploads,
      'totalTransactions': totalTransactions,
      'successRate': totalUploads > 0
          ? (successfulUploads / totalUploads) * 100
          : 0,
    };
  }
}
