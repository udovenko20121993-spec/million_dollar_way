import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  buy,
  sell,
  dividend,
  deposit,
  withdrawal,
  fee,
  tax,
  interest,
  transfer;

  static TransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'buy':
      case 'buyt':
        return TransactionType.buy;
      case 'sell':
      case 'sellt':
        return TransactionType.sell;
      case 'dividend':
      case 'cashreceipt':
        return TransactionType.dividend;
      case 'deposit':
      case 'depositswithdrawals':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'fee':
      case 'commission':
        return TransactionType.fee;
      case 'tax':
      case 'withholdingtax':
        return TransactionType.tax;
      case 'interest':
        return TransactionType.interest;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.buy;
    }
  }

  String get name {
    switch (this) {
      case TransactionType.buy:
        return 'buy';
      case TransactionType.sell:
        return 'sell';
      case TransactionType.dividend:
        return 'dividend';
      case TransactionType.deposit:
        return 'deposit';
      case TransactionType.withdrawal:
        return 'withdrawal';
      case TransactionType.fee:
        return 'fee';
      case TransactionType.tax:
        return 'tax';
      case TransactionType.interest:
        return 'interest';
      case TransactionType.transfer:
        return 'transfer';
    }
  }
}

class TransactionModel {
  final String id; // IBKR unique ID (tradeID, ibTransactionID, etc.)
  final String userId;
  final String accountId; // IBKR account ID (e.g., U1234567)
  final DateTime date;
  final String symbol;
  final TransactionType type;
  final double quantity;
  final double price;
  final String currency;
  final double amount; // quantity * price
  final double commission;
  final double tax;
  final String? exchange;
  final Map<String, dynamic>? rawData; // Original IBKR data for reference

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.date,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    required this.currency,
    required this.amount,
    this.commission = 0.0,
    this.tax = 0.0,
    this.exchange,
    this.rawData,
  });

  /// Extract account ID from IBKR raw data
  static String extractAccountIdFromIBKRData(Map<String, dynamic> ibkrData) {
    // Priority order for account identifiers
    final possibleAccountIds = [
      'accountId',
      'ibAccountId',
      'account',
      'acctId',
    ];

    for (final idField in possibleAccountIds) {
      final value = ibkrData[idField];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    // Fallback: try to extract from other fields or use default
    final symbol = ibkrData['symbol']?.toString() ?? '';
    final date = ibkrData['dateTime']?.toString() ?? '';

    // If no account ID found, use a default placeholder
    // In production, you might want to throw an error or handle differently
    return 'UNKNOWN_ACCOUNT';
  }

  /// Extract unique ID from IBKR raw data
  static String extractIdFromIBKRData(Map<String, dynamic> ibkrData) {
    // Priority order for unique identifiers
    final possibleIds = [
      'tradeID',
      'ibTransactionID',
      'transactionID',
      'execID',
      'orderID',
      'conid', // Contract ID as fallback
    ];

    for (final idField in possibleIds) {
      final value = ibkrData[idField];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    // Fallback: create composite key
    final symbol = ibkrData['symbol']?.toString() ?? '';
    final date = ibkrData['dateTime']?.toString() ?? '';
    final type = ibkrData['type']?.toString() ?? '';
    final quantity = ibkrData['quantity']?.toString() ?? '';
    final price = ibkrData['price']?.toString() ?? '';

    return '${symbol}_${date}_${type}_${quantity}_$price';
  }

  factory TransactionModel.fromIBKRData({
    required Map<String, dynamic> ibkrData,
    required String userId,
    String? accountId, // Optional override account ID
  }) {
    final id = extractIdFromIBKRData(ibkrData);

    // Extract account ID from data or use provided override
    final extractedAccountId =
        accountId ?? extractAccountIdFromIBKRData(ibkrData);

    // Parse date from IBKR data
    DateTime date;
    try {
      final dateStr =
          ibkrData['dateTime']?.toString() ??
          ibkrData['date']?.toString() ??
          ibkrData['time']?.toString() ??
          '';
      date = DateTime.parse(dateStr);
    } catch (e) {
      date = DateTime.now();
    }

    final type = TransactionType.fromString(
      ibkrData['type']?.toString() ?? 'buy',
    );
    final symbol = ibkrData['symbol']?.toString() ?? '';
    final quantity =
        double.tryParse(ibkrData['quantity']?.toString() ?? '0') ?? 0.0;
    final price = double.tryParse(ibkrData['price']?.toString() ?? '0') ?? 0.0;
    final currency = ibkrData['currency']?.toString() ?? 'USD';
    final amount =
        double.tryParse(ibkrData['amount']?.toString() ?? '0') ??
        (quantity * price);
    final commission =
        double.tryParse(ibkrData['commission']?.toString() ?? '0') ?? 0.0;
    final tax = double.tryParse(ibkrData['tax']?.toString() ?? '0') ?? 0.0;
    final exchange = ibkrData['exchange']?.toString();

    return TransactionModel(
      id: id,
      userId: userId,
      accountId: extractedAccountId,
      date: date,
      symbol: symbol,
      type: type,
      quantity: quantity,
      price: price,
      currency: currency,
      amount: amount,
      commission: commission,
      tax: tax,
      exchange: exchange,
      rawData: ibkrData,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      accountId: data['accountId'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      symbol: data['symbol'] as String? ?? '',
      type: TransactionType.fromString(data['type'] as String? ?? 'buy'),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      commission: (data['commission'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      exchange: data['exchange'] as String?,
      rawData: data['rawData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountId': accountId,
      'date': Timestamp.fromDate(date),
      'symbol': symbol,
      'type': type.name,
      'quantity': quantity,
      'price': price,
      'currency': currency,
      'amount': amount,
      'commission': commission,
      'tax': tax,
      if (exchange != null) 'exchange': exchange,
      if (rawData != null) 'rawData': rawData,
      'updatedAt': Timestamp.now(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    DateTime? date,
    String? symbol,
    TransactionType? type,
    double? quantity,
    double? price,
    String? currency,
    double? amount,
    double? commission,
    double? tax,
    String? exchange,
    Map<String, dynamic>? rawData,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      commission: commission ?? this.commission,
      tax: tax ?? this.tax,
      exchange: exchange ?? this.exchange,
      rawData: rawData ?? this.rawData,
    );
  }

  /// Get the document ID for Firestore (using IBKR unique ID)
  String get documentId => id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModel(id: $id, symbol: $symbol, type: $type, date: $date, amount: $amount)';
  }
}
