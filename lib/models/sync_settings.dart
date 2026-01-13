import 'package:cloud_firestore/cloud_firestore.dart';

/// Налаштування автоматичної синхронізації IBKR звітів
class SyncSettings {
  final String? ibkrToken;
  final String? queryId;
  final bool isAutoSyncEnabled;
  final bool syncOnMarketOpen;
  final bool syncOnMarketClose;
  final DateTime? lastSyncTime;
  final String? lastSyncStatus;
  final String? lastError;

  // Години роботи NYSE (Eastern Time)
  // Відкриття: 9:30 ET = 14:30 UTC (зима) / 13:30 UTC (літо)
  // Закриття: 16:00 ET = 21:00 UTC (зима) / 20:00 UTC (літо)
  static const String marketOpenUTC = "14:30"; // ~9:30 AM ET
  static const String marketCloseUTC = "21:00"; // ~4:00 PM ET

  SyncSettings({
    this.ibkrToken,
    this.queryId,
    this.isAutoSyncEnabled = false,
    this.syncOnMarketOpen = true,
    this.syncOnMarketClose = true,
    this.lastSyncTime,
    this.lastSyncStatus,
    this.lastError,
  });

  /// Перевірка чи налаштування валідні для синхронізації
  bool get isConfigured =>
      ibkrToken != null &&
      ibkrToken!.isNotEmpty &&
      queryId != null &&
      queryId!.isNotEmpty;

  /// Перевірка чи автосинк активний і налаштований
  bool get canAutoSync => isConfigured && isAutoSyncEnabled;

  factory SyncSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SyncSettings.fromMap(data);
  }

  factory SyncSettings.fromMap(Map<String, dynamic> data) {
    return SyncSettings(
      ibkrToken: data['ibkrToken']?.toString(),
      queryId: data['queryId']?.toString(),
      isAutoSyncEnabled: data['isAutoSyncEnabled'] ?? false,
      syncOnMarketOpen: data['syncOnMarketOpen'] ?? true,
      syncOnMarketClose: data['syncOnMarketClose'] ?? true,
      lastSyncTime: (data['lastSyncTime'] as Timestamp?)?.toDate(),
      lastSyncStatus: data['lastSyncStatus']?.toString(),
      lastError: data['lastError']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ibkrToken': ibkrToken,
      'queryId': queryId,
      'isAutoSyncEnabled': isAutoSyncEnabled,
      'syncOnMarketOpen': syncOnMarketOpen,
      'syncOnMarketClose': syncOnMarketClose,
      if (lastSyncTime != null) 'lastSyncTime': Timestamp.fromDate(lastSyncTime!),
      if (lastSyncStatus != null) 'lastSyncStatus': lastSyncStatus,
      if (lastError != null) 'lastError': lastError,
    };
  }

  SyncSettings copyWith({
    String? ibkrToken,
    String? queryId,
    bool? isAutoSyncEnabled,
    bool? syncOnMarketOpen,
    bool? syncOnMarketClose,
    DateTime? lastSyncTime,
    String? lastSyncStatus,
    String? lastError,
  }) {
    return SyncSettings(
      ibkrToken: ibkrToken ?? this.ibkrToken,
      queryId: queryId ?? this.queryId,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      syncOnMarketOpen: syncOnMarketOpen ?? this.syncOnMarketOpen,
      syncOnMarketClose: syncOnMarketClose ?? this.syncOnMarketClose,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Статус синхронізації
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Розширення для форматування статусу
extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.idle:
        return 'Очікування';
      case SyncStatus.syncing:
        return 'Синхронізація...';
      case SyncStatus.success:
        return 'Успішно';
      case SyncStatus.error:
        return 'Помилка';
    }
  }

  String get emoji {
    switch (this) {
      case SyncStatus.idle:
        return '⏸️';
      case SyncStatus.syncing:
        return '🔄';
      case SyncStatus.success:
        return '✅';
      case SyncStatus.error:
        return '❌';
    }
  }
}
