import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ibkr_data.dart';

/// Service for interacting with Cloud Firestore for IBKR data
class CloudFirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _defaultUserId = 'default_user'; // TODO: Get from auth

  /// Get the latest IBKR report for the user
  static Future<IBKRReport?> getLatestIbkrReport({String? userId}) async {
    final uid = userId ?? _defaultUserId;
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('reports')
          .orderBy('lastSyncTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return IBKRReport.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting latest IBKR report: $e');
      return null;
    }
  }

  /// Get all IBKR reports for the user
  static Future<List<IBKRReport>> getAllIbkrReports({String? userId}) async {
    final uid = userId ?? _defaultUserId;
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('reports')
          .orderBy('lastSyncTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => IBKRReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all IBKR reports: $e');
      return [];
    }
  }

  /// Get portfolio performance data
  static Future<Map<String, dynamic>> getPortfolioPerformance(
      {String? userId}) async {
    final uid = userId ?? _defaultUserId;
    try {
      final report = await getLatestIbkrReport(userId: uid);
      if (report == null) {
        return {
          'totalValue': 0.0,
          'dailyChange': 0.0,
          'dailyChangePercent': 0.0,
          'totalReturn': 0.0,
          'totalReturnPercent': 0.0,
        };
      }

      // Calculate performance metrics
      final totalValue = report.lastBalance;
      final dailyChange = 0.0; // TODO: Calculate from historical data
      final dailyChangePercent = totalValue > 0 ? (dailyChange / totalValue) * 100 : 0.0;

      return {
        'totalValue': totalValue,
        'dailyChange': dailyChange,
        'dailyChangePercent': dailyChangePercent,
        'totalReturn': 0.0, // TODO: Calculate from historical data
        'totalReturnPercent': 0.0, // TODO: Calculate from historical data
      };
    } catch (e) {
      print('Error getting portfolio performance: $e');
      return {
        'totalValue': 0.0,
        'dailyChange': 0.0,
        'dailyChangePercent': 0.0,
        'totalReturn': 0.0,
        'totalReturnPercent': 0.0,
      };
    }
  }
}
