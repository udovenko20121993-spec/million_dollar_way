import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:io';

import '../../data/remote/firestore_service.dart';
import '../../domain/models/user_tax_profile.dart';
import '../services/ibkr_service.dart';
import '../domain/models/position.dart';
import '../domain/models/portfolio_state.dart';
import '../../data/providers/auth_providers.dart';

// Змінена назва і типи стану
class ConsolidatedPortfolioNotifier extends Notifier<PortfolioState> {
  final _db = FirebaseFirestore.instance;
  final _firestore = FirestoreService();

  /// Отримання userId з перевіркою авторизації
  String _getUserId() {
    final userId = ref.read(userIdProvider);
    if (userId == null || userId.isEmpty) {
      throw Exception("Користувач не авторизований!");
    }
    return userId;
  }

  @override
  PortfolioState build() {
    // Спочатку спробуємо додати мокові дані
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMockPositions();
    });

    // Слухаємо НОВУ колекцію 'positions'
    final subscription = _db
        .collection('users')
        .doc(_getUserId())
        .collection('positions')
        .snapshots()
        .listen(
          (snapshot) {
            final positions = snapshot.docs
                .map((doc) => Position.fromFirestore(doc.data()))
                .where((pos) => pos.quantity > 0)
                .toList();

            final totalBalance = positions.fold<double>(
              0.0,
              (sum, position) => sum + position.marketValue,
            );

            state = PortfolioState.data(
              totalBalance: totalBalance,
              positions: positions,
            );
          },
          onError: (error, stackTrace) {
            print("🔥🔥🔥 Помилка підписки на колекцію 'positions': $error");
            print("🔄 Перехід на мокові дані через 1 секунду...");
            // Якщо помилка доступу, показуємо мокові дані з невеликою затримкою
            Future.delayed(const Duration(seconds: 1), () {
              print("⏰ Виклик _showMockData()");
              _showMockData();
            });
          },
        );

    ref.onDispose(() => subscription.cancel());

    // Початковий стан - завантаження
    return PortfolioState.loading();
  }

  // Показуємо мокові дані локально
  void _showMockData() {
    print("🚀 Початок _showMockData()");

    final mockPositions = [
      Position(
        symbol: 'AAPL',
        description: 'Apple Inc.',
        quantity: 15.5,
        averageCost: 183.92,
        marketValue: 2850.75,
      ),
      Position(
        symbol: 'GOOGL',
        description: 'Alphabet Inc.',
        quantity: 8.2,
        averageCost: 145.67,
        marketValue: 1234.50,
      ),
      Position(
        symbol: 'MSFT',
        description: 'Microsoft Corporation',
        quantity: 12.0,
        averageCost: 310.45,
        marketValue: 3725.40,
      ),
      Position(
        symbol: 'TSLA',
        description: 'Tesla Inc.',
        quantity: 5.5,
        averageCost: 245.80,
        marketValue: 1351.90,
      ),
    ];

    final totalBalance = mockPositions.fold<double>(
      0.0,
      (sum, position) => sum + position.marketValue,
    );

    print("💰 Розрахований баланс: \$$totalBalance");
    print("📊 Кількість позицій: ${mockPositions.length}");

    state = PortfolioState.data(
      totalBalance: totalBalance,
      positions: mockPositions,
    );

    print('✅ Показано мокові дані локально (Firestore недоступний)');
    print(
      "🎯 Стан оновлено: баланс=${state.totalBalance}, позицій=${state.positions.length}",
    );
  }

  // Метод для додавання мокових позицій напряму
  Future<void> _addMockPositions() async {
    try {
      final userId = _getUserId();
      final positionsRef = _db
          .collection('users')
          .doc(userId)
          .collection('positions');

      final mockPositions = [
        {
          'symbol': 'AAPL',
          'description': 'Apple Inc.',
          'quantity': 15.5,
          'averageCost': 183.92,
          'marketValue': 2850.75,
        },
        {
          'symbol': 'GOOGL',
          'description': 'Alphabet Inc.',
          'quantity': 8.2,
          'averageCost': 145.67,
          'marketValue': 1234.50,
        },
        {
          'symbol': 'MSFT',
          'description': 'Microsoft Corporation',
          'quantity': 12.0,
          'averageCost': 310.45,
          'marketValue': 3725.40,
        },
        {
          'symbol': 'TSLA',
          'description': 'Tesla Inc.',
          'quantity': 5.5,
          'averageCost': 245.80,
          'marketValue': 1351.90,
        },
      ];

      // Перевіримо, чи дані вже існують
      final existingDocs = await positionsRef.get();
      if (existingDocs.docs.isEmpty) {
        // Додаємо мокові дані, якщо колекція порожня
        for (final position in mockPositions) {
          await positionsRef.add(position);
        }
        print('✅ Додано мокові дані до колекції positions');
      } else {
        print('ℹ️ Колекція positions вже містить дані');
      }
    } catch (e) {
      print('❌ Помилка додавання мокових даних: $e');
    }
  }

  // --- Налаштування API ---
  Future<void> saveIbkrSettings(String token, String queryId) async {
    final userId = _getUserId();
    await _db.collection('users').doc(userId).set({
      'ibkr_token': token,
      'ibkr_query_id': queryId,
    }, SetOptions(merge: true));
  }

  Future<Map<String, String>?> getIbkrSettings() async {
    final userId = _getUserId();
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return {
        'token': data['ibkr_token'] ?? '',
        'queryId': data['ibkr_query_id'] ?? '',
      };
    }
    return null;
  }

  Future<void> saveUserTaxProfile(UserTaxProfile profile) async {
    final userId = _getUserId();
    await _firestore.saveUserTaxProfile(userId, profile);
  }

  Future<UserTaxProfile?> getUserTaxProfile() async {
    final userId = _getUserId();
    return await _firestore.getUserTaxProfile(userId);
  }

  Future<void> saveDividendTaxSettings({
    required double pitRate,
    required double militaryRate,
    required bool applyForeignTaxCredit,
  }) async {
    final userId = _getUserId();
    await _db.collection('users').doc(userId).set({
      'dividend_pit_rate': pitRate,
      'dividend_military_rate': militaryRate,
      'dividend_apply_foreign_tax_credit': applyForeignTaxCredit,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getDividendTaxSettings() async {
    final userId = _getUserId();
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return {
        'pitRate': (data['dividend_pit_rate'] as num?)?.toDouble(),
        'militaryRate': (data['dividend_military_rate'] as num?)?.toDouble(),
        'applyForeignTaxCredit':
            data['dividend_apply_foreign_tax_credit'] as bool?,
      };
    }
    return null;
  }

  // --- Дії імпорту ---
  Future<void> syncWithIbkr() async {
    try {
      final userId = ref.read(userIdProvider);
      if (userId == null || userId.isEmpty) {
        throw Exception("Користувач не авторизований!");
      }

      final settings = await getIbkrSettings();
      if (settings == null ||
          settings['token']!.isEmpty ||
          settings['queryId']!.isEmpty) {
        throw "В налаштуваннях немає токена IBKR";
      }

      final xmlContent = await IbkrService.fetchFlexQuery(
        settings['token']!,
        settings['queryId']!,
      );

      await _processAndSaveXml(xmlContent);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> importReport({String? customName}) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);
    final xmlContent = await file.readAsString();
    await _processAndSaveXml(xmlContent);
  }

  // --- НОВА АСИНХРОННА ЛОГІКА ІМПОРТУ ---
  Future<void> importAndProcessReport() async {
    // 1. Повідомляємо UI, що почався процес
    state = state.copyWith(isProcessing: true);

    try {
      print('🔄 Починаємо асинхронний імпорт звіту...');

      // 2. Асинхронний вибір файлу
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );

      if (result == null || result.files.isEmpty) {
        // Користувач скасував вибір
        print('📄 Користувач скасував вибір файлу');
        state = state.copyWith(isProcessing: false);
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        throw Exception("Шлях до файлу не отримано.");
      }

      print('📁 Файл обрано: $path');

      // 3. Асинхронне читання файлу
      final file = File(path);
      final xmlContent = await file.readAsString();
      print('📄 Файл успішно прочитано (${xmlContent.length} символів)');

      // 4. Парсинг у фоновому ізоляті (використовуємо існуючий метод)
      final parsedData = await IbkrService.parseLargeXml(xmlContent);
      print('🔄 XML успішно розпарсено у фоновому потоці');

      // 5. Конвертація активів з IBKR формату в моделі Position
      final assets = (parsedData['assets'] as List<dynamic>? ?? [])
          .map(
            (assetData) =>
                _convertAssetToPosition(assetData as Map<String, dynamic>),
          )
          .toList();

      if (assets.isEmpty) {
        print("ℹ️ У звіті немає активів для оновлення.");
        return;
      }

      print('📊 Знайдено ${assets.length} активів для оновлення');

      // 6. Отримання userId та атомарне оновлення позицій
      final userId = _getUserId();
      await _updateConsolidatedPositions(assets, userId);

      print('✅ Імпорт та обробка успішно завершені.');
    } catch (e, stackTrace) {
      print('🔥🔥🔥 Помилка під час імпорту: $e');
      print('🔥 Stack trace: $stackTrace');

      // Оновлюємо стан, щоб показати помилку користувачу
      state = state.copyWith(error: e, isProcessing: false);

      // Можна додати SnackBar або інше сповіщення для користувача
      rethrow; // Передаємо помилку далі для обробки у UI
    } finally {
      // 7. У будь-якому випадку вимикаємо індикатор завантаження
      if (state.isProcessing) {
        state = state.copyWith(isProcessing: false);
      }
      print('🏁 Процес імпорту завершено');
    }
  }

  // --- 🔥 НОВА ЛОГІКА ЗБЕРЕЖЕННЯ ---
  Future<void> _processAndSaveXml(String xmlContent) async {
    // 1. Отримуємо реальний userId
    final userId = ref.read(userIdProvider);
    if (userId == null || userId.isEmpty) {
      throw Exception("Користувач не авторизований або userId порожній.");
    }

    print('🔄 Починаємо обробку XML для користувача: $userId');

    // 2. Парсинг XML для отримання списку активів
    final rawData = await IbkrService.parseLargeXml(xmlContent);

    // Конвертуємо активи з IBKR формату в моделі Position
    final assets = (rawData['assets'] as List<dynamic>? ?? [])
        .map(
          (assetData) =>
              _convertAssetToPosition(assetData as Map<String, dynamic>),
        )
        .toList();

    if (assets.isEmpty) {
      print("ℹ️ У звіті немає активів для оновлення.");
      return;
    }

    // 3. Виклик нового методу для атомарного оновлення
    await _updateConsolidatedPositions(assets, userId);

    print('✅ Консолідовані позиції для користувача $userId успішно оновлено.');
  }

  /// Конвертація активу з IBKR формату в модель Position
  Position _convertAssetToPosition(Map<String, dynamic> assetData) {
    return Position(
      symbol: assetData['symbol']?.toString() ?? '',
      description:
          assetData['symbol']?.toString() ??
          '', // IBKR не дає description, використовуємо symbol
      quantity: (assetData['quantity'] as num?)?.toDouble() ?? 0.0,
      averageCost: assetData['price'] != null
          ? (assetData['price'] as num?)?.toDouble() ?? 0.0
          : 0.0, // IBKR дає price, використовуємо як averageCost
      marketValue: (assetData['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<void> _updateConsolidatedPositions(
    List<Position> assets,
    String userId,
  ) async {
    final positionsRef = _db
        .collection('users')
        .doc(userId)
        .collection('positions');
    final batch = _db.batch();

    print('⚙️ Підготовка batch-операції для ${assets.length} активів...');

    for (final asset in assets) {
      // Використовуємо symbol як ID документа
      final docRef = positionsRef.doc(asset.symbol);

      batch.set(
        docRef,
        {
          'symbol': asset.symbol,
          'description': asset.description,
          'quantity': FieldValue.increment(asset.quantity), // Атомарна операція
          'marketValue': asset.marketValue,
          'averageCost': asset.averageCost,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ), // Створює документ, якщо його немає, або оновлює
      );
    }

    try {
      await batch.commit();
      print('✅ Batch-операція успішно завершена.');
    } catch (e) {
      print('🔥🔥🔥 Помилка виконання batch-операції: $e');
      rethrow; // Передаємо помилку далі для обробки у UI
    }
  }

  // --- Для екрану історії (якщо ти його все ще використовуєш) ---
  // Тепер історія і головний екран дивляться в одну колекцію 'reports'
  Stream<QuerySnapshot> getHistoryStream() {
    final userId = _getUserId();
    return _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .orderBy('importedAt', descending: true)
        .snapshots();
  }

  Future<void> deleteHistoryReport(String docId) async {
    final userId = _getUserId();
    await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(docId)
        .delete();
  }

  // --- ТЕСТ ПОДАТКІВ ---
  Future<void> generateMockTaxReport() async {
    final userId = _getUserId();
    print('🔥 Creating mock tax report for user: $userId');

    final trades = [
      {
        'date': '2024-01-15',
        'symbol': 'AAPL',
        'action': 'Buy',
        'quantity': 10,
        'price': 100.0,
        'priceCurrency': 'USD',
        'cost': 1000.0,
        'commission': 1.0,
        'commissionCurrency': 'USD',
        'priceRateToUah': 39.5,
        'priceRateDate': '2024-01-15',
        'priceUah': 3950.0,
        'commissionRateToUah': 39.5,
        'commissionRateDate': '2024-01-15',
        'commissionUah': 39.5,
      },
      {
        'date': '2024-06-10',
        'symbol': 'AAPL',
        'action': 'Sell',
        'quantity': 10,
        'price': 250.0,
        'priceCurrency': 'USD',
        'cost': 2500.0,
        'commission': 2.5,
        'commissionCurrency': 'USD',
        'priceRateToUah': 39.5,
        'priceRateDate': '2024-06-10',
        'priceUah': 9875.0,
        'commissionRateToUah': 39.5,
        'commissionRateDate': '2024-06-10',
        'commissionUah': 98.75,
      },
    ];

    final dividends = [
      {
        'date': '2024-07-15',
        'symbol': 'MSFT',
        'amount': 100.0,
        'description': 'MSFT Dividend',
      },
      {
        'date': '2024-07-15',
        'symbol': 'MSFT',
        'amount': -15.0,
        'description': 'Withholding Tax 15%',
      },
    ];

    final docRef = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .add({
          'name': 'Тест Податків 2024',
          'reportName': 'Тест Податків 2024',
          'lastBalance': 0.0,
          'cashBalance': 0.0,
          'totalDividends': 85.0,
          'totalDeposits': 0.0,
          'totalWithdrawals': 0.0,
          'totalCommissions': 138.25,
          'assets': [],
          'trades': trades,
          'dividends': dividends,
          'importedAt': FieldValue.serverTimestamp(),
          'importSource': 'Mock',
          'sourceType': 'localFile',
          'uploadDate': DateTime.now().toIso8601String(),
          'flexQueryId': null,
          'isSyncRequired': false,
          'totalValue': 0.0,
          'lastSyncTime': FieldValue.serverTimestamp(), // 🔥 ВИПРАВЛЕНО
        });

    print('✅ Mock report created with ID: ${docRef.id}');
  }
}

// Оновлене визначення провайдера
final portfolioProvider =
    NotifierProvider<ConsolidatedPortfolioNotifier, PortfolioState>(
      () => ConsolidatedPortfolioNotifier(),
    );
