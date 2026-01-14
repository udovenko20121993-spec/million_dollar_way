<<<<<<< Current (Your changes)
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_firestore_service.dart';
import '../domain/models/ibkr_data.dart';

/// Production логування для IBKR API операцій
class IbkrLogger {
  static void logInfo(String operation, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [IBKR] [$operation] INFO: $message';
    developer.log(logMessage, name: 'MillionDollarWay');
    if (kDebugMode) print('🔵 $logMessage');
  }

  static void logWarning(String operation, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [IBKR] [$operation] WARNING: $message';
    developer.log(logMessage, name: 'MillionDollarWay', level: 900);
    if (kDebugMode) print('🟡 $logMessage');
  }

  static void logError(
    String operation,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [IBKR] [$operation] ERROR: $message';
    developer.log(
      logMessage,
      name: 'MillionDollarWay',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    if (kDebugMode) print('🔴 $logMessage');
    if (error != null) print('🔴 Error details: $error');
  }
}

class IbkrService {
  // Базова URL для API IBKR
  static const String _baseUrl =
      "https://www.interactivebrokers.com/Universal/servlet/FlexStatementService";

  // Production логування
  static void _logInfo(String operation, String message) =>
      IbkrLogger.logInfo(operation, message);
  static void _logWarning(String operation, String message) =>
      IbkrLogger.logWarning(operation, message);
  static void _logError(
    String operation,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => IbkrLogger.logError(
    operation,
    message,
    error: error,
    stackTrace: stackTrace,
  );

  // Ключі для кешування
  static const String _cachedReportKey = 'ibkr_cached_report';
  static const String _cacheTimestampKey = 'ibkr_cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 12); // Кеш діє 12 годин

  // --- МЕТОДИ ДЛЯ РОБОТИ З КЕШЕМ ---

  /// Зберегти звіт в локальний кеш
  static Future<void> _cacheReport(IBKRReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportJson = _reportToCacheMap(report);
      await prefs.setString(_cachedReportKey, jsonEncode(reportJson));
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
      debugPrint('✅ IBKR звіт закешовано');
    } catch (e) {
      debugPrint('❌ Помилка кешування звіту: $e');
    }
  }

  /// Отримати звіт з кешу
  static Future<IBKRReport?> _getCachedReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportJson = prefs.getString(_cachedReportKey);
      final timestamp = prefs.getString(_cacheTimestampKey);

      if (reportJson == null || timestamp == null) {
        return null;
      }

      final cacheTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
        debugPrint('⏰ Кеш звіту протух, видаляємо...');
        await prefs.remove(_cachedReportKey);
        await prefs.remove(_cacheTimestampKey);
        return null;
      }

      final reportMap = jsonDecode(reportJson) as Map<String, dynamic>;
      debugPrint('✅ Звіт отримано з кешу');
      return _reportFromCacheMap(reportMap);
    } catch (e) {
      debugPrint('❌ Помилка отримання звіту з кешу: $e');
      return null;
    }
  }

  /// Очистити кеш
  static Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedReportKey);
      await prefs.remove(_cacheTimestampKey);
      debugPrint('🗑️ Кеш IBKR очищено');
    } catch (e) {
      debugPrint('❌ Помилка очищення кешу: $e');
    }
  }

  // --- МЕТОД 1: ЗАВАНТАЖЕННЯ ЗВІТУ (2 кроки) ---
  static Future<String> fetchFlexQuery(String token, String queryId) async {
    const operation = 'FETCH_FLEX_QUERY';
    try {
      _logInfo(operation, 'Starting IBKR Flex Query fetch');
      _logInfo(
        operation,
        'Called from: ${StackTrace.current.toString().split('\n')[1]}',
      );

      // 1. Надсилаємо запит на створення звіту
      final url1 = Uri.parse("$_baseUrl.SendRequest?t=$token&q=$queryId&v=3");
      _logInfo(
        operation,
        'Step 1: Requesting report generation from ${url1.toString().substring(0, 50)}...',
      );

      final response1 = await http.get(
        url1,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/xml, text/xml, */*',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response1.statusCode != 200) {
        _logError(
          operation,
          'HTTP error in step 1',
          error: 'Status: ${response1.statusCode}, Body: ${response1.body}',
        );
        throw Exception(
          "Помилка з'єднання з IBKR: ${response1.statusCode} - ${response1.body}",
        );
      }

      _logInfo(operation, 'Step 1 response received, parsing XML...');

      // Парсимо відповідь, щоб знайти ReferenceCode
      final doc1 = XmlDocument.parse(response1.body);

      // Перевіряємо на помилки від IBKR
      final errorCode = doc1.findAllElements('ErrorCode').firstOrNull?.text;
      final errorMessage = doc1
          .findAllElements('ErrorMessage')
          .firstOrNull
          ?.text;
      if (errorCode != null) {
        _logError(
          operation,
          'IBKR API error',
          error: 'Code: $errorCode, Message: $errorMessage',
        );
        throw Exception("IBKR Error ($errorCode): $errorMessage");
      }

      final refCode = doc1.findAllElements('ReferenceCode').firstOrNull?.text;
      if (refCode == null) {
        _logError(operation, 'No ReferenceCode found in response');
        throw Exception(
          "Не вдалося отримати ReferenceCode. Перевірте Токен та ID.",
        );
      }

      _logInfo(operation, 'Step 1 successful. ReferenceCode: $refCode');
      _logInfo(operation, 'Waiting 1 second before download...');

      // IBKR вимагає паузу, поки генерується файл
      await Future.delayed(const Duration(seconds: 1));

      // 2. Забираємо готовий XML
      final url2 = Uri.parse("$_baseUrl.GetStatement?q=$refCode&t=$token&v=3");
      _logInfo(
        operation,
        'Step 2: Downloading XML report from ${url2.toString().substring(0, 50)}...',
      );

      final response2 = await http.get(
        url2,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/xml, text/xml, */*',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response2.statusCode != 200) {
        _logError(
          operation,
          'HTTP error in step 2',
          error: 'Status: ${response2.statusCode}, Body: ${response2.body}',
        );
        throw Exception(
          "Помилка завантаження XML: ${response2.statusCode} - ${response2.body}",
        );
      }

      _logInfo(
        operation,
        'XML downloaded successfully. Size: ${response2.body.length} bytes',
      );
      return response2.body;
    } catch (e, stackTrace) {
      _logError(
        operation,
        'IBKR API request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // --- МЕТОД 2: ПАРСИНГ (Той самий, що й був) ---
  static Future<Map<String, dynamic>> parseLargeXml(String xmlBody) async {
    return await compute(_doHeavyParsing, xmlBody);
  }

  static Map<String, dynamic> _doHeavyParsing(String xml) {
    final document = XmlDocument.parse(xml);

    double totalBalance = 0.0;
    double cashBalance = 0.0;

    // 1. NAV
    final equityNodes = document.findAllElements(
      'EquitySummaryByReportDateInBase',
    );
    if (equityNodes.isNotEmpty) {
      totalBalance =
          double.tryParse(equityNodes.last.getAttribute('total') ?? '0') ?? 0.0;
    }
    if (totalBalance == 0) {
      final navNodes = document.findAllElements('NetAssetValue');
      for (var node in navNodes) {
        if (node.getAttribute('reportFieldName') == 'Total' ||
            node.getAttribute('reportFieldName') == 'Net Asset Value') {
          totalBalance =
              double.tryParse(
                node.getAttribute('value') ?? node.getAttribute('total') ?? '0',
              ) ??
              0;
        }
      }
    }

    // 2. Cash
    final cashNodes = document.findAllElements('CashReportCurrency');
    for (var node in cashNodes) {
      String curr = node.getAttribute('currency') ?? '';
      if (curr == 'USD' || curr == 'BASE') {
        cashBalance =
            double.tryParse(
              node.getAttribute('endingCash') ??
                  node.getAttribute('endingSettledCash') ??
                  '0',
            ) ??
            0;
        if (cashBalance != 0) break;
      }
    }

    // 3. Assets
    List<Map<String, dynamic>> assets = [];
    double totalAssetsValue = 0.0;

    final positionNodes = document.findAllElements('OpenPosition');
    debugPrint(
      'IBKRService:_doHeavyParsing => OpenPosition nodes found: ${positionNodes.length}',
    );
    for (final node in positionNodes) {
      final symbol = node.getAttribute('symbol') ?? 'Unknown';
      final qty = double.tryParse(node.getAttribute('position') ?? '0') ?? 0;
      if (qty.abs() < 0.0001) {
        continue;
      }

      final val =
          double.tryParse(node.getAttribute('positionValue') ?? '0') ?? 0;
      final price = double.tryParse(node.getAttribute('markPrice') ?? '0') ?? 0;
      totalAssetsValue += val;

      debugPrint(
        'IBKRService:_doHeavyParsing => position parsed: $symbol / qty=$qty / value=$val / price=$price',
      );

      assets.add({
        'symbol': symbol,
        'quantity': qty,
        'value': val,
        'price': price,
      });
    }
    debugPrint(
      'IBKRService:_doHeavyParsing => total parsed positions: ${assets.length}',
    );

    // 4. Fallback for Cash
    if (cashBalance == 0 && totalBalance > 0) {
      cashBalance = totalBalance - totalAssetsValue;
    }

    return {
      'lastBalance': totalBalance,
      'cashBalance': cashBalance,
      'assets': assets,
      'lastSyncTime': DateTime.now().toIso8601String(),
    };
  }

  // Отримання поточного портфеля для MidasAiService
  static Future<Map<String, dynamic>?> getCurrentPortfolio({
    bool forceRefresh = false,
  }) async {
    try {
      // Спочатку пробуємо отримати з кешу, якщо не вимагаємо примусового оновлення
      if (!forceRefresh) {
        final cachedReport = await _getCachedReport();
        if (cachedReport != null) {
          debugPrint('📱 Використовуємо кешовані дані IBKR');
          return _convertReportToPortfolio(cachedReport);
        }
      }

      // Пробуємо отримати останній звіт з Firestore
      final report = await CloudFirestoreService.getLatestIbkrReport();

      if (report != null) {
        // Кешуємо звіт для майбутнього використання
        await _cacheReport(report);
        debugPrint('🔄 Отримано свіжі дані з Firestore');

        return _convertReportToPortfolio(report);
      }

      debugPrint('⚠️ Немає доступних даних портфеля');
      return null;
    } catch (e) {
      debugPrint('❌ Помилка отримання поточного портфеля: $e');
      return null;
    }
  }

  /// Конвертація звіту в формат портфеля
  static Map<String, dynamic> _convertReportToPortfolio(IBKRReport report) {
    return {
      'balance': report.cashBalance,
      'totalValue': report.lastBalance,
      'dailyChange': 0.0, // Можна додати логіку розрахунку
      'currency': 'USD', // Припустимо USD за замовчуванням
      'positions': report.positions
          .map(
            (position) => {
              'symbol': position.symbol,
              'quantity': position.quantity,
              'marketPrice': position.quantity != 0
                  ? position.marketValue / position.quantity
                  : position.averageCost,
              'marketValue': position.marketValue,
              'currency': 'USD',
            },
          )
          .toList(),
    };
  }

  /// Синхронізація останніх даних - основний метод для оновлення портфеля
  static Future<bool> syncLatestData() async {
    const operation = 'SYNC_LATEST_DATA';
    try {
      _logInfo(operation, 'Starting IBKR data synchronization');

      // Очищуємо кеш для отримання свіжих даних
      await _clearCache();

      // Отримуємо свіжі дані з Firestore
      final report = await CloudFirestoreService.getLatestIbkrReport();

      if (report != null) {
        // Кешуємо новий звіт
        await _cacheReport(report);
        _logInfo(operation, 'Successfully synchronized latest IBKR data');
        return true;
      } else {
        _logWarning(operation, 'No IBKR report found to synchronize');
        return false;
      }
    } catch (e, stackTrace) {
      _logError(
        operation,
        'Failed to synchronize IBKR data',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Map<String, dynamic> _reportToCacheMap(IBKRReport report) {
    return {
      'id': report.id,
      'name': report.reportName,
      'lastBalance': report.lastBalance,
      'cashBalance': report.cashBalance,
      'uploadDate': report.uploadDate.toIso8601String(),
      'positions': report.positions
          .map(
            (position) => {
              'symbol': position.symbol,
              'quantity': position.quantity,
              'averageCost': position.averageCost,
              'marketValue': position.marketValue,
              'unrealizedPnl': position.unrealizedPnl,
            },
          )
          .toList(),
    };
  }

  static IBKRReport _reportFromCacheMap(Map<String, dynamic> map) {
    final uploadDate =
        DateTime.tryParse(map['uploadDate']?.toString() ?? '') ??
        DateTime.now();
    final positions = (map['positions'] as List? ?? []).map((item) {
      final data = item as Map<String, dynamic>;
      return IBKRPosition(
        symbol: data['symbol']?.toString() ?? '',
        quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
        averageCost: (data['averageCost'] as num?)?.toDouble() ?? 0,
        marketValue: (data['marketValue'] as num?)?.toDouble() ?? 0,
        unrealizedPnl: (data['unrealizedPnl'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return IBKRReport(
      id: map['id']?.toString() ?? 'cached',
      name: map['name']?.toString() ?? 'Cached Report',
      lastBalance: (map['lastBalance'] as num?)?.toDouble() ?? 0,
      cashBalance: (map['cashBalance'] as num?)?.toDouble() ?? 0,
      totalDividends: 0,
      totalDeposits: 0,
      totalWithdrawals: 0,
      totalCommissions: 0,
      accountInfo: null,
      assets: positions
          .map(
            (position) => IBKRAsset(
              symbol: position.symbol,
              name: position.symbol,
              value: position.marketValue,
              change: 0,
              quantity: position.quantity,
            ),
          )
          .toList(),
      positions: positions,
      dividends: const [],
      trades: const [],
      lastSyncTime: uploadDate,
      isSyncRequired: false,
      lastError: null,
      sourceFiles: const [],
      cashTransactions: const [],
      sourceType: ReportSourceType.localFile,
      reportName: map['name']?.toString() ?? 'Cached Report',
      uploadDate: uploadDate,
      flexQueryId: null,
    );
=======
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
>>>>>>> Incoming (Background Agent changes)
  }
}
