import 'package:cloud_firestore/cloud_firestore.dart';

// --- ДОПОМІЖНІ КЛАСИ (Ваші, без змін + додано комісію в угоди) ---

class IBKRAsset {
  final String symbol;
  final String name;
  final double value;
  final double change;
  final double quantity;

  IBKRAsset({
    required this.symbol,
    required this.name,
    required this.value,
    required this.change,
    required this.quantity,
  });

  factory IBKRAsset.fromMap(Map<String, dynamic> map) {
    return IBKRAsset(
      symbol: map['symbol']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      value: double.tryParse(map['value']?.toString() ?? "0") ?? 0,
      change: double.tryParse(map['change']?.toString() ?? "0") ?? 0,
      quantity: double.tryParse(map['quantity']?.toString() ?? "0") ?? 0,
    );
  }

  // Додаємо toMap, щоб можна було передавати дані далі
  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'name': name,
      'value': value,
      'change': change,
      'quantity': quantity,
    };
  }
}

class IBKRDividend {
  final String date;
  final String symbol;
  final double amount;
  final String description;

  IBKRDividend({
    required this.date,
    required this.symbol,
    required this.amount,
    required this.description,
  });

  factory IBKRDividend.fromMap(Map<String, dynamic> map) {
    return IBKRDividend(
      date: map['date']?.toString() ?? '',
      symbol: map['symbol']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? "0") ?? 0,
      description: map['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'symbol': symbol,
      'amount': amount,
      'description': description,
    };
  }
}

class IBKRTrade {
  final String date;
  final String symbol;
  final String action;
  final double quantity;
  final double price;
  final double cost;
  final double commission; // <-- ДОДАНО: Комісія для конкретної угоди

  IBKRTrade({
    required this.date,
    required this.symbol,
    required this.action,
    required this.quantity,
    required this.price,
    required this.cost,
    this.commission = 0.0, // <-- ДОДАНО
  });

  factory IBKRTrade.fromMap(Map<String, dynamic> map) {
    return IBKRTrade(
      date: map['date']?.toString() ?? '',
      symbol: map['symbol']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? "0") ?? 0,
      price: double.tryParse(map['price']?.toString() ?? "0") ?? 0,
      cost: double.tryParse(map['cost']?.toString() ?? "0") ?? 0,
      commission:
          double.tryParse(map['commission']?.toString() ?? "0") ??
          0, // <-- ДОДАНО
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'symbol': symbol,
      'action': action,
      'quantity': quantity,
      'price': price,
      'cost': cost,
      'commission': commission,
    };
  }
}

// --- ГОЛОВНИЙ КЛАС ЗВІТУ (ОНОВЛЕНИЙ) ---

class IBKRReport {
  final String id;
  final String name;
  final double lastBalance;
  final double cashBalance;
  final double totalDividends;
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalCommissions; // <-- ДОДАНО: Загальна комісія
  final List<IBKRAsset> assets;
  final List<IBKRDividend> dividends;
  final List<IBKRTrade> trades;
  final DateTime? lastSyncTime;
  final bool isSyncRequired;
  final String? lastError;
  final List<String> sourceFiles;

  // Зберігаємо оригінальні кеш-транзакції для історії
  final List<Map<String, dynamic>> cashTransactions;

  IBKRReport({
    required this.id,
    required this.name,
    required this.lastBalance,
    required this.cashBalance,
    required this.totalDividends,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.totalCommissions, // <-- ДОДАНО
    required this.assets,
    required this.dividends,
    required this.trades,
    this.lastSyncTime,
    this.isSyncRequired = false,
    this.lastError,
    this.sourceFiles = const [],
    this.cashTransactions = const [],
  });

  factory IBKRReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<IBKRAsset> parsedAssets = (data['assets'] as List? ?? [])
        .map((item) => IBKRAsset.fromMap(item as Map<String, dynamic>))
        .toList();

    double parsedCash =
        double.tryParse(data['cashBalance']?.toString() ?? "0") ?? 0;
    double finalBalance =
        double.tryParse(data['lastBalance']?.toString() ?? "0") ?? 0;

    // Ваша логіка перерахунку балансу (збережено)
    if (finalBalance == 0) {
      finalBalance = double.tryParse(data['value']?.toString() ?? "0") ?? 0;
    }
    if (finalBalance == 0) {
      double assetsTotal = 0;
      for (var asset in parsedAssets) assetsTotal += asset.value;
      finalBalance = assetsTotal + parsedCash;
    }

    return IBKRReport(
      id: doc.id,
      name: data['name']?.toString() ?? 'Звіт',
      lastBalance: finalBalance,
      cashBalance: parsedCash,
      totalDividends:
          double.tryParse(data['totalDividends']?.toString() ?? "0") ?? 0,
      totalDeposits:
          double.tryParse(data['totalDeposits']?.toString() ?? "0") ?? 0,
      totalWithdrawals:
          double.tryParse(data['totalWithdrawals']?.toString() ?? "0") ?? 0,
      totalCommissions:
          double.tryParse(data['totalCommissions']?.toString() ?? "0") ??
          0, // <-- Читаємо з бази

      assets: parsedAssets,
      dividends: (data['dividends'] as List? ?? [])
          .map((item) => IBKRDividend.fromMap(item as Map<String, dynamic>))
          .toList(),
      trades: (data['trades'] as List? ?? [])
          .map((item) => IBKRTrade.fromMap(item as Map<String, dynamic>))
          .toList(),

      // Зберігаємо оригінальні дані для передачі в історію
      cashTransactions: List<Map<String, dynamic>>.from(
        data['cashTransactions'] ?? [],
      ),

      lastSyncTime: (data['lastSyncTime'] as Timestamp?)?.toDate(),
      isSyncRequired: data['isSyncRequired'] ?? false,
      lastError: data['lastError']?.toString(),
      sourceFiles: (data['sourceFiles'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  // <-- ДОДАНО: Метод toMap, необхідний для навігації в історію
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastBalance': lastBalance,
      'cashBalance': cashBalance,
      'totalDividends': totalDividends,
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'totalCommissions': totalCommissions,
      'trades': trades.map((e) => e.toMap()).toList(),
      'dividends': dividends.map((e) => e.toMap()).toList(),
      'assets': assets.map((e) => e.toMap()).toList(),
      'cashTransactions': cashTransactions,
    };
  }
}
