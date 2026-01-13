/// Модель для попереднього перегляду імпорту
class ImportPreview {
  final String fileName;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String accountId;
  
  // Фінансові дані
  final double balance;
  final double cashBalance;
  final double totalDividends;
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalCommissions;
  
  // Кількість записів
  final int tradesCount;
  final int dividendsCount;
  final int assetsCount;
  final int cashTransactionsCount;
  
  // Дублікати (якщо є існуючі дані)
  final int duplicateTradesCount;
  final int duplicateDividendsCount;
  
  // Нові записи (що буде додано)
  final int newTradesCount;
  final int newDividendsCount;
  
  // Сирі дані для імпорту
  final List<Map<String, dynamic>> trades;
  final List<Map<String, dynamic>> dividends;
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> cashTransactions;
  
  // Статус
  final bool isValid;
  final String? errorMessage;

  ImportPreview({
    required this.fileName,
    this.periodStart,
    this.periodEnd,
    this.accountId = '',
    this.balance = 0,
    this.cashBalance = 0,
    this.totalDividends = 0,
    this.totalDeposits = 0,
    this.totalWithdrawals = 0,
    this.totalCommissions = 0,
    this.tradesCount = 0,
    this.dividendsCount = 0,
    this.assetsCount = 0,
    this.cashTransactionsCount = 0,
    this.duplicateTradesCount = 0,
    this.duplicateDividendsCount = 0,
    this.newTradesCount = 0,
    this.newDividendsCount = 0,
    this.trades = const [],
    this.dividends = const [],
    this.assets = const [],
    this.cashTransactions = const [],
    this.isValid = true,
    this.errorMessage,
  });

  /// Форматований період
  String get periodString {
    if (periodStart == null && periodEnd == null) return 'Невідомо';
    
    String format(DateTime? d) {
      if (d == null) return '?';
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }
    
    if (periodStart == periodEnd || periodEnd == null) {
      return format(periodStart);
    }
    
    return '${format(periodStart)} — ${format(periodEnd)}';
  }

  /// Чи є дублікати
  bool get hasDuplicates => duplicateTradesCount > 0 || duplicateDividendsCount > 0;

  /// Загальна кількість нових записів
  int get totalNewRecords => newTradesCount + newDividendsCount;

  /// Створити preview з помилкою
  factory ImportPreview.error(String fileName, String error) {
    return ImportPreview(
      fileName: fileName,
      isValid: false,
      errorMessage: error,
    );
  }
}

/// Результат імпорту (для статистики)
class ImportResult {
  final String fileName;
  final DateTime importTime;
  final bool success;
  final String? error;
  
  // Що було додано
  final int addedTrades;
  final int addedDividends;
  final int addedDeposits;
  final double depositsAmount;
  final double withdrawalsAmount;
  final double dividendsAmount;
  final double commissionsAmount;
  
  // Що було пропущено (дублікати)
  final int skippedTrades;
  final int skippedDividends;

  ImportResult({
    required this.fileName,
    required this.importTime,
    this.success = true,
    this.error,
    this.addedTrades = 0,
    this.addedDividends = 0,
    this.addedDeposits = 0,
    this.depositsAmount = 0,
    this.withdrawalsAmount = 0,
    this.dividendsAmount = 0,
    this.commissionsAmount = 0,
    this.skippedTrades = 0,
    this.skippedDividends = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': fileName,
      'uploadTime': importTime.toIso8601String(),
      'status': success ? 'success' : 'error',
      'error': error,
      'stats': {
        'addedTrades': addedTrades,
        'addedDividends': addedDividends,
        'depositsAmount': depositsAmount,
        'withdrawalsAmount': withdrawalsAmount,
        'dividendsAmount': dividendsAmount,
        'commissionsAmount': commissionsAmount,
        'skippedTrades': skippedTrades,
        'skippedDividends': skippedDividends,
      },
    };
  }
}
