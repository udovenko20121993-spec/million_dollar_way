import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sync_settings.dart';
import '../models/ibkr_data.dart';

/// Сервіс для роботи з IBKR синхронізацією
class IbkrService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ID користувача (в реальному додатку - з Firebase Auth)
  final String userId;

  IbkrService({required this.userId});

  // ============== НАЛАШТУВАННЯ СИНХРОНІЗАЦІЇ ==============

  /// Отримати налаштування синхронізації (Stream)
  Stream<SyncSettings> getSyncSettingsStream() {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => SyncSettings.fromFirestore(doc));
  }

  /// Отримати налаштування синхронізації (одноразово)
  Future<SyncSettings> getSyncSettings() async {
    final doc = await _db.collection('users').doc(userId).get();
    return SyncSettings.fromFirestore(doc);
  }

  /// Зберегти налаштування синхронізації
  Future<void> saveSyncSettings(SyncSettings settings) async {
    await _db.collection('users').doc(userId).set(
          settings.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Оновити IBKR токен
  Future<void> updateIbkrToken(String token) async {
    await _db.collection('users').doc(userId).set({
      'ibkrToken': token,
    }, SetOptions(merge: true));
  }

  /// Оновити Query ID
  Future<void> updateQueryId(String queryId) async {
    await _db.collection('users').doc(userId).set({
      'queryId': queryId,
    }, SetOptions(merge: true));
  }

  /// Увімкнути/вимкнути автосинхронізацію
  Future<void> setAutoSyncEnabled(bool enabled) async {
    await _db.collection('users').doc(userId).set({
      'isAutoSyncEnabled': enabled,
    }, SetOptions(merge: true));
  }

  /// Налаштувати час синхронізації
  Future<void> setSyncSchedule({
    bool? syncOnMarketOpen,
    bool? syncOnMarketClose,
  }) async {
    final Map<String, dynamic> data = {};
    if (syncOnMarketOpen != null) data['syncOnMarketOpen'] = syncOnMarketOpen;
    if (syncOnMarketClose != null) data['syncOnMarketClose'] = syncOnMarketClose;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
    }
  }

  // ============== ЗВІТИ ==============

  /// Отримати всі звіти користувача
  Stream<List<IBKRReport>> getReportsStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .orderBy('lastSyncTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => IBKRReport.fromFirestore(doc)).toList());
  }

  /// Отримати останній звіт
  Future<IBKRReport?> getLatestReport() async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .orderBy('lastSyncTime', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return IBKRReport.fromFirestore(snapshot.docs.first);
  }

  // ============== СИНХРОНІЗАЦІЯ ==============

  /// Запустити ручну синхронізацію звіту
  /// Cloud Function відреагує на зміну isSyncRequired
  Future<void> triggerSync(String reportId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .update({
      'isSyncRequired': true,
      'lastError': null,
    });
  }

  /// Створити новий звіт для синхронізації
  Future<String> createReport({
    required String name,
    required String queryId,
  }) async {
    final docRef = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .add({
      'name': name,
      'queryId': queryId,
      'lastBalance': 0,
      'cashBalance': 0,
      'totalDividends': 0,
      'totalDeposits': 0,
      'totalWithdrawals': 0,
      'totalCommissions': 0,
      'assets': [],
      'dividends': [],
      'trades': [],
      'cashTransactions': [],
      'isSyncRequired': true, // Одразу запускаємо синхронізацію
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Видалити звіт
  Future<void> deleteReport(String reportId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(reportId)
        .delete();
  }

  // ============== ДОПОМІЖНІ МЕТОДИ ==============

  /// Перевірити чи сьогодні робочий день (NYSE)
  static bool isMarketDay() {
    final now = DateTime.now().toUtc();
    // Понеділок = 1, Неділя = 7
    return now.weekday >= 1 && now.weekday <= 5;
  }

  /// Отримати час до наступної синхронізації
  static Duration? getTimeUntilNextSync() {
    if (!isMarketDay()) return null;

    final now = DateTime.now().toUtc();
    
    // Час відкриття ринку (14:30 UTC)
    final marketOpen = DateTime.utc(now.year, now.month, now.day, 14, 30);
    
    // Час закриття ринку (21:00 UTC)
    final marketClose = DateTime.utc(now.year, now.month, now.day, 21, 0);

    if (now.isBefore(marketOpen)) {
      return marketOpen.difference(now);
    } else if (now.isBefore(marketClose)) {
      return marketClose.difference(now);
    }

    return null; // Ринок вже закритий
  }

  /// Форматувати час останньої синхронізації
  static String formatLastSyncTime(DateTime? time) {
    if (time == null) return 'Ніколи';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Щойно';
    if (diff.inMinutes < 60) return '${diff.inMinutes} хв тому';
    if (diff.inHours < 24) return '${diff.inHours} год тому';
    if (diff.inDays < 7) return '${diff.inDays} дн тому';

    return '${time.day}.${time.month}.${time.year}';
  }
}
