import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель рахунку IBKR
class IBKRAccount {
  final String id;
  final String name;                  // Назва рахунку (напр. "Основний", "Пенсійний")
  final String? accountNumber;        // Номер рахунку в IBKR (U1234567)
  final String? accountType;          // Тип: "individual", "ira", "joint"
  final String? currency;             // Базова валюта: USD, EUR
  final String? ibkrToken;            // Flex Query Token для цього рахунку
  final String? queryId;              // Query ID для цього рахунку
  final bool isDefault;               // Чи є це основний рахунок
  final bool isAutoSyncEnabled;       // Автосинхронізація
  final DateTime? lastSyncTime;       // Остання синхронізація
  final double? lastBalance;          // Останній відомий баланс
  final String? lastError;            // Остання помилка
  final DateTime createdAt;           // Дата створення

  IBKRAccount({
    required this.id,
    required this.name,
    this.accountNumber,
    this.accountType,
    this.currency = 'USD',
    this.ibkrToken,
    this.queryId,
    this.isDefault = false,
    this.isAutoSyncEnabled = false,
    this.lastSyncTime,
    this.lastBalance,
    this.lastError,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Створити з Firestore документа
  factory IBKRAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return IBKRAccount(
      id: doc.id,
      name: data['name'] ?? 'Рахунок',
      accountNumber: data['accountNumber'],
      accountType: data['accountType'],
      currency: data['currency'] ?? 'USD',
      ibkrToken: data['ibkrToken'],
      queryId: data['queryId'],
      isDefault: data['isDefault'] ?? false,
      isAutoSyncEnabled: data['isAutoSyncEnabled'] ?? false,
      lastSyncTime: (data['lastSyncTime'] as Timestamp?)?.toDate(),
      lastBalance: (data['lastBalance'] as num?)?.toDouble(),
      lastError: data['lastError'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Конвертувати в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'accountNumber': accountNumber,
      'accountType': accountType,
      'currency': currency,
      'ibkrToken': ibkrToken,
      'queryId': queryId,
      'isDefault': isDefault,
      'isAutoSyncEnabled': isAutoSyncEnabled,
      'lastSyncTime': lastSyncTime != null ? Timestamp.fromDate(lastSyncTime!) : null,
      'lastBalance': lastBalance,
      'lastError': lastError,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Копіювання з оновленими полями
  IBKRAccount copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? accountType,
    String? currency,
    String? ibkrToken,
    String? queryId,
    bool? isDefault,
    bool? isAutoSyncEnabled,
    DateTime? lastSyncTime,
    double? lastBalance,
    String? lastError,
    DateTime? createdAt,
  }) {
    return IBKRAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      ibkrToken: ibkrToken ?? this.ibkrToken,
      queryId: queryId ?? this.queryId,
      isDefault: isDefault ?? this.isDefault,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastBalance: lastBalance ?? this.lastBalance,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Чи налаштований рахунок (має токен та query id)
  bool get isConfigured => ibkrToken != null && ibkrToken!.isNotEmpty && 
                           queryId != null && queryId!.isNotEmpty;

  /// Назва типу рахунку
  String get accountTypeName {
    switch (accountType) {
      case 'individual': return 'Індивідуальний';
      case 'ira': return 'Пенсійний (IRA)';
      case 'joint': return 'Спільний';
      case 'trust': return 'Траст';
      case 'corporate': return 'Корпоративний';
      default: return 'Інший';
    }
  }

  /// Іконка для типу рахунку
  String get accountTypeEmoji {
    switch (accountType) {
      case 'individual': return '👤';
      case 'ira': return '🏦';
      case 'joint': return '👥';
      case 'trust': return '🏛️';
      case 'corporate': return '🏢';
      default: return '💼';
    }
  }

  /// Форматований баланс
  String get formattedBalance {
    if (lastBalance == null) return 'Н/Д';
    return '\$${lastBalance!.toStringAsFixed(2)}';
  }
}

/// Типи рахунків для вибору
class AccountType {
  static const String individual = 'individual';
  static const String ira = 'ira';
  static const String joint = 'joint';
  static const String trust = 'trust';
  static const String corporate = 'corporate';

  static List<Map<String, String>> get all => [
    {'value': individual, 'label': 'Індивідуальний', 'emoji': '👤'},
    {'value': ira, 'label': 'Пенсійний (IRA)', 'emoji': '🏦'},
    {'value': joint, 'label': 'Спільний', 'emoji': '👥'},
    {'value': trust, 'label': 'Траст', 'emoji': '🏛️'},
    {'value': corporate, 'label': 'Корпоративний', 'emoji': '🏢'},
  ];
}
