import 'package:cloud_firestore/cloud_firestore.dart';

/// Безпечний парсинг дати з Firestore (String | Timestamp | DateTime)
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    // Firestore Timestamp
    return (value as Timestamp).toDate();
  } catch (_) {
    return null;
  }
}

// --- ДОПОМІЖНІ КЛАСИ (Ваші, без змін + додано комісію в угоди) ---

class IBKRAccountInfo {
  final String accountNumber;
  final String baseCurrency;
  final DateTime openedDate;

  IBKRAccountInfo({
    required this.accountNumber,
    required this.baseCurrency,
    required this.openedDate,
  });

  factory IBKRAccountInfo.fromFirestore(Map<String, dynamic> data) {
    return IBKRAccountInfo(
      accountNumber: data['accountNumber']?.toString() ?? '',
      baseCurrency: data['baseCurrency']?.toString() ?? 'USD',
      openedDate: _parseDateTime(data['openedDate']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'accountNumber': accountNumber,
      'baseCurrency': baseCurrency,
      'openedDate': Timestamp.fromDate(openedDate),
    };
  }
}

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

  // Додаємо toFirestore для сумісності
  Map<String, dynamic> toFirestore() {
    return toMap();
  }
}

class IBKRDividend {
  final DateTime date;
  final String symbol;
  final String currency;
  final double grossAmount;
  final double withholdingTax;
  final double netAmount;
  final double amount;
  final String description;

  IBKRDividend({
    required this.date,
    required this.symbol,
    required this.currency,
    required this.grossAmount,
    required this.withholdingTax,
    required this.netAmount,
    this.amount = 0.0,
    this.description = '',
  });

  // Getter for backward compatibility
  // double get amount => grossAmount; // Now using field directly

  factory IBKRDividend.fromFirestore(Map<String, dynamic> data) {
    return IBKRDividend(
      date: _parseDateTime(data['date']) ?? DateTime.now(),
      symbol: data['symbol']?.toString() ?? '',
      currency: data['currency']?.toString() ?? 'USD',
      grossAmount:
          (data['grossAmount'] as num?)?.toDouble() ??
          double.tryParse(data['grossAmount']?.toString() ?? '') ??
          0.0,
      withholdingTax:
          (data['withholdingTax'] as num?)?.toDouble() ??
          double.tryParse(data['withholdingTax']?.toString() ?? '') ??
          0.0,
      netAmount:
          (data['netAmount'] as num?)?.toDouble() ??
          double.tryParse(data['netAmount']?.toString() ?? '') ??
          0.0,
      amount:
          (data['amount'] as num?)?.toDouble() ??
          double.tryParse(data['amount']?.toString() ?? '') ??
          (data['grossAmount'] as num?)?.toDouble() ??
          double.tryParse(data['grossAmount']?.toString() ?? '') ??
          0.0,
      description: data['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'symbol': symbol,
      'currency': currency,
      'grossAmount': grossAmount,
      'withholdingTax': withholdingTax,
      'netAmount': netAmount,
      'amount': amount,
      'description': description,
    };
  }
}

class IBKRCashTransaction {
  final DateTime date;
  final String type;
  final String currency;
  final double amount;
  final String description;

  IBKRCashTransaction({
    required this.date,
    required this.type,
    required this.currency,
    required this.amount,
    required this.description,
  });

  factory IBKRCashTransaction.fromFirestore(Map<String, dynamic> data) {
    return IBKRCashTransaction(
      date: _parseDateTime(data['date']) ?? DateTime.now(),
      type: data['type']?.toString() ?? '',
      currency: data['currency']?.toString() ?? 'USD',
      amount:
          (data['amount'] as num?)?.toDouble() ??
          double.tryParse(data['amount']?.toString() ?? '') ??
          0.0,
      description: data['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'type': type,
      'currency': currency,
      'amount': amount,
      'description': description,
    };
  }
}

class IBKRPosition {
  final String symbol;
  final double quantity;
  final double averageCost;
  final double marketValue;
  final double unrealizedPnl;
  final double lastPrice;
  final double change;
  final double changePercent;
  final String companyName;
  final String exchange;
  final List<double> sparklineData;

  IBKRPosition({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
    required this.marketValue,
    required this.unrealizedPnl,
    this.lastPrice = 0.0,
    this.change = 0.0,
    this.changePercent = 0.0,
    this.companyName = '',
    this.exchange = '',
    this.sparklineData = const [],
  });

  factory IBKRPosition.fromFirestore(Map<String, dynamic> data) {
    return IBKRPosition(
      symbol: data['symbol']?.toString() ?? '',
      quantity:
          (data['quantity'] as num?)?.toDouble() ??
          double.tryParse(data['quantity']?.toString() ?? '') ??
          0.0,
      averageCost:
          (data['averageCost'] as num?)?.toDouble() ??
          double.tryParse(data['averageCost']?.toString() ?? '') ??
          0.0,
      marketValue:
          (data['marketValue'] as num?)?.toDouble() ??
          double.tryParse(data['marketValue']?.toString() ?? '') ??
          0.0,
      unrealizedPnl:
          (data['unrealizedPnl'] as num?)?.toDouble() ??
          double.tryParse(data['unrealizedPnl']?.toString() ?? '') ??
          0.0,
      lastPrice:
          (data['lastPrice'] as num?)?.toDouble() ??
          double.tryParse(data['lastPrice']?.toString() ?? '') ??
          0.0,
      change:
          (data['change'] as num?)?.toDouble() ??
          double.tryParse(data['change']?.toString() ?? '') ??
          0.0,
      changePercent:
          (data['changePercent'] as num?)?.toDouble() ??
          double.tryParse(data['changePercent']?.toString() ?? '') ??
          0.0,
      companyName: data['companyName']?.toString() ?? '',
      exchange: data['exchange']?.toString() ?? '',
      sparklineData:
          (data['sparklineData'] as List<dynamic>?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'averageCost': averageCost,
      'marketValue': marketValue,
      'unrealizedPnl': unrealizedPnl,
      'lastPrice': lastPrice,
      'change': change,
      'changePercent': changePercent,
      'companyName': companyName,
      'exchange': exchange,
      'sparklineData': sparklineData,
    };
  }
}

class IBKRTrade {
  final DateTime date;
  final String symbol;
  final String action;
  final double quantity;
  final double price;
  final String priceCurrency;
  final double? priceRateToUah;
  final String? priceRateDate;
  final double? priceUah;
  final double cost;
  final double commission;
  final String commissionCurrency;
  final double? commissionRateToUah;
  final String? commissionRateDate;
  final double? commissionUah;

  IBKRTrade({
    required this.date,
    required this.symbol,
    required this.action,
    required this.quantity,
    required this.price,
    this.priceCurrency = 'USD',
    this.priceRateToUah,
    this.priceRateDate,
    this.priceUah,
    required this.cost,
    this.commission = 0.0,
    this.commissionCurrency = 'USD',
    this.commissionRateToUah,
    this.commissionRateDate,
    this.commissionUah,
  });

  factory IBKRTrade.fromMap(Map<String, dynamic> map) {
    return IBKRTrade(
      date: _parseDateTime(map['date']) ?? DateTime.now(),
      symbol: map['symbol']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? "0") ?? 0,
      price: double.tryParse(map['price']?.toString() ?? "0") ?? 0,
      priceCurrency:
          map['priceCurrency']?.toString() ??
          map['currency']?.toString() ??
          'USD',
      priceRateToUah:
          (map['priceRateToUah'] as num?)?.toDouble() ??
          double.tryParse(map['priceRateToUah']?.toString() ?? ''),
      priceRateDate: map['priceRateDate']?.toString(),
      priceUah:
          (map['priceUah'] as num?)?.toDouble() ??
          double.tryParse(map['priceUah']?.toString() ?? ''),
      cost: double.tryParse(map['cost']?.toString() ?? "0") ?? 0,
      commission:
          double.tryParse(map['commission']?.toString() ?? "0") ??
          0, // <-- ДОДАНО
      commissionCurrency:
          map['commissionCurrency']?.toString() ??
          map['priceCurrency']?.toString() ??
          map['currency']?.toString() ??
          'USD',
      commissionRateToUah:
          (map['commissionRateToUah'] as num?)?.toDouble() ??
          double.tryParse(map['commissionRateToUah']?.toString() ?? ''),
      commissionRateDate: map['commissionRateDate']?.toString(),
      commissionUah:
          (map['commissionUah'] as num?)?.toDouble() ??
          double.tryParse(map['commissionUah']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'symbol': symbol,
      'action': action,
      'quantity': quantity,
      'price': price,
      'priceCurrency': priceCurrency,
      'priceRateToUah': priceRateToUah,
      'priceRateDate': priceRateDate,
      'priceUah': priceUah,
      'cost': cost,
      'commission': commission,
      'commissionCurrency': commissionCurrency,
      'commissionRateToUah': commissionRateToUah,
      'commissionRateDate': commissionRateDate,
      'commissionUah': commissionUah,
    };
  }

  IBKRTrade copyWith({
    DateTime? date,
    String? symbol,
    String? action,
    double? quantity,
    double? price,
    String? priceCurrency,
    double? priceRateToUah,
    String? priceRateDate,
    double? priceUah,
    double? cost,
    double? commission,
    String? commissionCurrency,
    double? commissionRateToUah,
    String? commissionRateDate,
    double? commissionUah,
  }) {
    return IBKRTrade(
      date: date ?? this.date,
      symbol: symbol ?? this.symbol,
      action: action ?? this.action,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      priceRateToUah: priceRateToUah ?? this.priceRateToUah,
      priceRateDate: priceRateDate ?? this.priceRateDate,
      priceUah: priceUah ?? this.priceUah,
      cost: cost ?? this.cost,
      commission: commission ?? this.commission,
      commissionCurrency: commissionCurrency ?? this.commissionCurrency,
      commissionRateToUah: commissionRateToUah ?? this.commissionRateToUah,
      commissionRateDate: commissionRateDate ?? this.commissionRateDate,
      commissionUah: commissionUah ?? this.commissionUah,
    );
  }
}

// --- ГОЛОВНИЙ КЛАС ЗВІТУ (ОНОВЛЕНИЙ) ---

enum ReportSourceType { flexQuery, localFile }

class IBKRReport {
  final String id;
  final String name;
  final double lastBalance;
  final double cashBalance;
  final double totalDividends;
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalCommissions; // <-- ДОДАНО: Загальна комісія
  final IBKRAccountInfo? accountInfo;
  final List<IBKRAsset> assets;
  final List<IBKRPosition> positions;
  final List<IBKRDividend> dividends;
  final List<IBKRTrade> trades;
  final DateTime? lastSyncTime;
  final bool isSyncRequired;
  final String? lastError;
  final List<String> sourceFiles;

  // Зберігаємо оригінальні кеш-транзакції для історії
  final List<IBKRCashTransaction> cashTransactions;

  // Нові поля для CRUD управління
  final ReportSourceType sourceType;
  final String reportName;
  final DateTime uploadDate;
  final String? flexQueryId;
  final String? originalFileName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final List<String> sections;
  final bool isActive; // <-- ДОДАНО: Властивість для визначення активного стану

  IBKRReport({
    required this.id,
    required this.name,
    required this.lastBalance,
    required this.cashBalance,
    required this.totalDividends,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.totalCommissions, // <-- ДОДАНО
    this.accountInfo,
    required this.assets,
    required this.positions,
    required this.dividends,
    required this.trades,
    this.lastSyncTime,
    this.isSyncRequired = false,
    this.lastError,
    this.sourceFiles = const [],
    this.cashTransactions = const [],
    required this.sourceType,
    required this.reportName,
    required this.uploadDate,
    this.flexQueryId,
    this.originalFileName,
    this.periodStart,
    this.periodEnd,
    this.sections = const [],
    this.isActive = true, // <-- ДОДАНО: За замовчуванням звіт активний
  });

  factory IBKRReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<IBKRAsset> parsedAssets = (data['assets'] as List? ?? [])
        .map((item) => IBKRAsset.fromMap(item as Map<String, dynamic>))
        .toList();
    List<IBKRPosition> parsedPositions = (data['assets'] as List? ?? [])
        .map((item) => IBKRPosition.fromFirestore(item as Map<String, dynamic>))
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
      for (var asset in parsedAssets) {
        assetsTotal += asset.value;
      }
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

      accountInfo: data['accountInfo'] is Map<String, dynamic>
          ? IBKRAccountInfo.fromFirestore(
              data['accountInfo'] as Map<String, dynamic>,
            )
          : null,
      assets: parsedAssets,
      positions: parsedPositions,
      dividends: (data['dividends'] as List? ?? [])
          .map(
            (item) => IBKRDividend.fromFirestore(item as Map<String, dynamic>),
          )
          .toList(),
      trades: (data['trades'] as List? ?? [])
          .map((item) => IBKRTrade.fromMap(item as Map<String, dynamic>))
          .toList(),

      // Зберігаємо оригінальні дані для передачі в історію
      cashTransactions: (data['cashTransactions'] as List? ?? [])
          .map(
            (item) =>
                IBKRCashTransaction.fromFirestore(item as Map<String, dynamic>),
          )
          .toList(),

      lastSyncTime: _parseDateTime(data['lastSyncTime']),
      isSyncRequired: data['isSyncRequired'] ?? false,
      lastError: data['lastError']?.toString(),
      sourceFiles: (data['sourceFiles'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),

      // Нові поля
      sourceType: IBKRReport.parseSourceType(data['sourceType']),
      reportName:
          data['reportName']?.toString() ??
          data['name']?.toString() ??
          'Звіт IBKR',
      uploadDate: _parseDateTime(data['uploadDate']) ?? DateTime.now(),
      flexQueryId: data['flexQueryId']?.toString(),
      originalFileName: data['originalFileName']?.toString(),
      periodStart: _parseDateTime(data['periodStart']),
      periodEnd: _parseDateTime(data['periodEnd']),
      sections: (data['sections'] as List? ?? [])
          .map((section) => section.toString())
          .toList(),
      isActive:
          data['isActive'] ??
          true, // <-- ДОДАНО: Читання з Firestore, за замовчуванням true
    );
  }

  static ReportSourceType parseSourceType(dynamic value) {
    if (value == null) return ReportSourceType.localFile;
    if (value is String) {
      if (value == 'flexQuery') return ReportSourceType.flexQuery;
      if (value == 'localFile') return ReportSourceType.localFile;
    }
    return ReportSourceType.localFile;
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
      'accountInfo': accountInfo?.toFirestore(),
      'trades': trades.map((e) => e.toMap()).toList(),
      'dividends': dividends.map((e) => e.toFirestore()).toList(),
      'assets': assets.map((asset) => asset.toFirestore()).toList(),
      'positions': positions.map((position) => position.toFirestore()).toList(),
      'cashTransactions': cashTransactions.map((e) => e.toFirestore()).toList(),
      'sourceType': sourceType.name,
      'reportName': reportName,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'flexQueryId': flexQueryId,
      'originalFileName': originalFileName,
      'periodStart': periodStart != null
          ? Timestamp.fromDate(periodStart!)
          : null,
      'periodEnd': periodEnd != null ? Timestamp.fromDate(periodEnd!) : null,
      'sections': sections,
      'isActive': isActive, // <-- ДОДАНО: Серіалізація поля isActive
    };
  }

  factory IBKRReport.fromMap(Map<String, dynamic> map) {
    return IBKRReport(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      lastBalance: (map['lastBalance'] as num?)?.toDouble() ?? 0.0,
      cashBalance: (map['cashBalance'] as num?)?.toDouble() ?? 0.0,
      totalDividends: (map['totalDividends'] as num?)?.toDouble() ?? 0.0,
      totalDeposits: (map['totalDeposits'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals: (map['totalWithdrawals'] as num?)?.toDouble() ?? 0.0,
      totalCommissions: (map['totalCommissions'] as num?)?.toDouble() ?? 0.0,
      accountInfo: map['accountInfo'] != null
          ? IBKRAccountInfo.fromFirestore(
              map['accountInfo'] as Map<String, dynamic>,
            )
          : null,
      assets: (map['assets'] as List? ?? [])
          .map((item) => IBKRAsset.fromMap(item as Map<String, dynamic>))
          .toList(),
      positions: (map['positions'] as List? ?? [])
          .map(
            (item) => IBKRPosition.fromFirestore(item as Map<String, dynamic>),
          )
          .toList(),
      dividends: (map['dividends'] as List? ?? [])
          .map(
            (item) => IBKRDividend.fromFirestore(item as Map<String, dynamic>),
          )
          .toList(),
      trades: (map['trades'] as List? ?? [])
          .map((item) => IBKRTrade.fromMap(item as Map<String, dynamic>))
          .toList(),
      cashTransactions: (map['cashTransactions'] as List? ?? [])
          .map(
            (item) =>
                IBKRCashTransaction.fromFirestore(item as Map<String, dynamic>),
          )
          .toList(),
      sourceType: ReportSourceType.values.firstWhere(
        (type) => type.name == map['sourceType'],
        orElse: () => ReportSourceType.localFile,
      ),
      reportName: map['reportName']?.toString() ?? '',
      uploadDate: map['uploadDate'] is Timestamp
          ? (map['uploadDate'] as Timestamp).toDate()
          : DateTime.now(),
      flexQueryId: map['flexQueryId']?.toString(),
      originalFileName: map['originalFileName']?.toString(),
      periodStart: map['periodStart'] != null
          ? (map['periodStart'] as Timestamp).toDate()
          : null,
      periodEnd: map['periodEnd'] != null
          ? (map['periodEnd'] as Timestamp).toDate()
          : null,
      sections: (map['sections'] as List?)?.cast<String>() ?? [],
      isActive: map['isActive'] ?? true, // <-- ДОДАНО: Читання з map
    );
  }

  IBKRReport copyWith({
    String? id,
    String? name,
    double? lastBalance,
    double? cashBalance,
    double? totalDividends,
    double? totalDeposits,
    double? totalWithdrawals,
    double? totalCommissions,
    IBKRAccountInfo? accountInfo,
    List<IBKRAsset>? assets,
    List<IBKRPosition>? positions,
    List<IBKRDividend>? dividends,
    List<IBKRTrade>? trades,
    DateTime? lastSyncTime,
    bool? isSyncRequired,
    String? lastError,
    List<String>? sourceFiles,
    List<IBKRCashTransaction>? cashTransactions,
    ReportSourceType? sourceType,
    String? reportName,
    DateTime? uploadDate,
    String? flexQueryId,
    String? originalFileName,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<String>? sections,
    bool? isActive, // <-- ДОДАНО: Параметр для copyWith
  }) {
    return IBKRReport(
      id: id ?? this.id,
      name: name ?? this.name,
      lastBalance: lastBalance ?? this.lastBalance,
      cashBalance: cashBalance ?? this.cashBalance,
      totalDividends: totalDividends ?? this.totalDividends,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      totalCommissions: totalCommissions ?? this.totalCommissions,
      accountInfo: accountInfo ?? this.accountInfo,
      assets: assets ?? this.assets,
      positions: positions ?? this.positions,
      dividends: dividends ?? this.dividends,
      trades: trades ?? this.trades,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncRequired: isSyncRequired ?? this.isSyncRequired,
      lastError: lastError ?? this.lastError,
      sourceFiles: sourceFiles ?? this.sourceFiles,
      cashTransactions: cashTransactions ?? this.cashTransactions,
      sourceType: sourceType ?? this.sourceType,
      reportName: reportName ?? this.reportName,
      uploadDate: uploadDate ?? this.uploadDate,
      flexQueryId: flexQueryId ?? this.flexQueryId,
      originalFileName: originalFileName ?? this.originalFileName,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      sections: sections ?? this.sections,
      isActive: isActive ?? this.isActive, // <-- ДОДАНО: Передача в конструктор
    );
  }
}
