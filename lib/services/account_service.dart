import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ibkr_account.dart';

/// Сервіс для управління рахунками IBKR
class AccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  // Ключ для зберігання вибраного рахунку
  static const String _selectedAccountKey = 'selected_ibkr_account';

  AccountService({required this.userId});

  /// Колекція рахунків користувача
  CollectionReference<Map<String, dynamic>> get _accountsCollection =>
      _db.collection('users').doc(userId).collection('accounts');

  // ============== ОТРИМАННЯ РАХУНКІВ ==============

  /// Отримати всі рахунки (Stream)
  Stream<List<IBKRAccount>> getAccountsStream() {
    return _accountsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IBKRAccount.fromFirestore(doc))
            .toList());
  }

  /// Отримати всі рахунки (одноразово)
  Future<List<IBKRAccount>> getAccounts() async {
    final snapshot = await _accountsCollection
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => IBKRAccount.fromFirestore(doc)).toList();
  }

  /// Отримати рахунок за ID
  Future<IBKRAccount?> getAccount(String accountId) async {
    final doc = await _accountsCollection.doc(accountId).get();
    if (!doc.exists) return null;
    return IBKRAccount.fromFirestore(doc);
  }

  /// Отримати основний рахунок
  Future<IBKRAccount?> getDefaultAccount() async {
    final snapshot = await _accountsCollection
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      // Якщо немає основного, повертаємо перший
      final allAccounts = await getAccounts();
      return allAccounts.isNotEmpty ? allAccounts.first : null;
    }
    
    return IBKRAccount.fromFirestore(snapshot.docs.first);
  }

  // ============== ВИБРАНИЙ РАХУНОК ==============

  /// Отримати ID вибраного рахунку (з локального сховища)
  Future<String?> getSelectedAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_selectedAccountKey}_$userId');
  }

  /// Зберегти вибраний рахунок
  Future<void> setSelectedAccountId(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_selectedAccountKey}_$userId', accountId);
  }

  /// Отримати вибраний рахунок
  Future<IBKRAccount?> getSelectedAccount() async {
    final selectedId = await getSelectedAccountId();
    
    if (selectedId != null) {
      final account = await getAccount(selectedId);
      if (account != null) return account;
    }
    
    // Якщо вибраного немає, повертаємо основний
    return getDefaultAccount();
  }

  // ============== СТВОРЕННЯ/ОНОВЛЕННЯ ==============

  /// Створити новий рахунок
  Future<String> createAccount({
    required String name,
    String? accountNumber,
    String? accountType,
    String currency = 'USD',
    bool isDefault = false,
  }) async {
    // Якщо це перший рахунок або встановлено isDefault
    if (isDefault) {
      await _clearDefaultFlag();
    }

    // Перевіряємо чи це перший рахунок
    final accounts = await getAccounts();
    final shouldBeDefault = accounts.isEmpty || isDefault;

    final docRef = await _accountsCollection.add({
      'name': name,
      'accountNumber': accountNumber,
      'accountType': accountType,
      'currency': currency,
      'isDefault': shouldBeDefault,
      'isAutoSyncEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Автоматично вибираємо новий рахунок
    await setSelectedAccountId(docRef.id);

    return docRef.id;
  }

  /// Оновити рахунок
  Future<void> updateAccount(String accountId, Map<String, dynamic> data) async {
    // Якщо встановлюємо як основний, знімаємо прапорець з інших
    if (data['isDefault'] == true) {
      await _clearDefaultFlag();
    }

    await _accountsCollection.doc(accountId).update(data);
  }

  /// Оновити токен та query ID для рахунку
  Future<void> updateAccountCredentials(
    String accountId, {
    String? ibkrToken,
    String? queryId,
  }) async {
    final Map<String, dynamic> data = {};
    if (ibkrToken != null) data['ibkrToken'] = ibkrToken;
    if (queryId != null) data['queryId'] = queryId;

    if (data.isNotEmpty) {
      await _accountsCollection.doc(accountId).update(data);
    }
  }

  /// Встановити рахунок як основний
  Future<void> setAsDefault(String accountId) async {
    await _clearDefaultFlag();
    await _accountsCollection.doc(accountId).update({'isDefault': true});
  }

  /// Зняти прапорець "основний" з усіх рахунків
  Future<void> _clearDefaultFlag() async {
    final snapshot = await _accountsCollection
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }

  // ============== ВИДАЛЕННЯ ==============

  /// Видалити рахунок
  Future<void> deleteAccount(String accountId) async {
    // Видаляємо всі звіти цього рахунку
    final reportsSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .doc(accountId)
        .collection('reports')
        .get();

    for (final doc in reportsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Видаляємо сам рахунок
    await _accountsCollection.doc(accountId).delete();

    // Якщо це був вибраний рахунок, вибираємо інший
    final selectedId = await getSelectedAccountId();
    if (selectedId == accountId) {
      final accounts = await getAccounts();
      if (accounts.isNotEmpty) {
        await setSelectedAccountId(accounts.first.id);
      }
    }
  }

  // ============== СИНХРОНІЗАЦІЯ ==============

  /// Оновити статус синхронізації
  Future<void> updateSyncStatus(
    String accountId, {
    DateTime? lastSyncTime,
    double? lastBalance,
    String? lastError,
  }) async {
    final Map<String, dynamic> data = {};
    
    if (lastSyncTime != null) {
      data['lastSyncTime'] = Timestamp.fromDate(lastSyncTime);
    }
    if (lastBalance != null) {
      data['lastBalance'] = lastBalance;
    }
    if (lastError != null) {
      data['lastError'] = lastError;
    } else {
      data['lastError'] = FieldValue.delete();
    }

    if (data.isNotEmpty) {
      await _accountsCollection.doc(accountId).update(data);
    }
  }

  /// Увімкнути/вимкнути автосинхронізацію
  Future<void> setAutoSync(String accountId, bool enabled) async {
    await _accountsCollection.doc(accountId).update({
      'isAutoSyncEnabled': enabled,
    });
  }

  // ============== МІГРАЦІЯ ==============

  /// Мігрувати старі дані в новий формат (якщо потрібно)
  Future<void> migrateFromOldFormat() async {
    final accounts = await getAccounts();
    
    // Якщо вже є рахунки, міграція не потрібна
    if (accounts.isNotEmpty) return;

    // Перевіряємо чи є старі звіти
    final oldReportsSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('reports')
        .limit(1)
        .get();

    if (oldReportsSnapshot.docs.isEmpty) return;

    // Створюємо рахунок за замовчуванням
    final accountId = await createAccount(
      name: 'Основний рахунок',
      accountType: AccountType.individual,
      isDefault: true,
    );

    // Копіюємо старі налаштування синхронізації
    final userDoc = await _db.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    if (userData['ibkrToken'] != null || userData['queryId'] != null) {
      await updateAccountCredentials(
        accountId,
        ibkrToken: userData['ibkrToken'],
        queryId: userData['queryId'],
      );
    }

    print('Migration completed: created default account $accountId');
  }

  // ============== ДОПОМІЖНІ МЕТОДИ ==============

  /// Отримати загальний баланс по всіх рахунках
  Future<double> getTotalBalance() async {
    final accounts = await getAccounts();
    return accounts.fold(0.0, (sum, acc) => sum + (acc.lastBalance ?? 0));
  }

  /// Отримати кількість рахунків
  Future<int> getAccountCount() async {
    final snapshot = await _accountsCollection.count().get();
    return snapshot.count ?? 0;
  }
}
