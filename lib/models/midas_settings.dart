import 'package:cloud_firestore/cloud_firestore.dart';

/// Налаштування Мідаса для збереження в Firestore
class MidasSettings {
  final int years;
  final double weeklyPerStock;
  final bool useBotStrategy;
  final double targetAmount; // Ціль (за замовчуванням $1,000,000)
  final List<String> selectedTickers;
  final DateTime? lastUpdated;

  // Досягнуті віхи
  final List<MidasMilestone> achievedMilestones;

  MidasSettings({
    this.years = 20,
    this.weeklyPerStock = 1.0,
    this.useBotStrategy = true,
    this.targetAmount = 1000000,
    this.selectedTickers = const [],
    this.lastUpdated,
    this.achievedMilestones = const [],
  });

  factory MidasSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MidasSettings.fromMap(data);
  }

  factory MidasSettings.fromMap(Map<String, dynamic> data) {
    return MidasSettings(
      years: data['years'] ?? 20,
      weeklyPerStock: (data['weeklyPerStock'] ?? 1.0).toDouble(),
      useBotStrategy: data['useBotStrategy'] ?? true,
      targetAmount: (data['targetAmount'] ?? 1000000).toDouble(),
      selectedTickers: List<String>.from(data['selectedTickers'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      achievedMilestones: (data['achievedMilestones'] as List? ?? [])
          .map((m) => MidasMilestone.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'years': years,
      'weeklyPerStock': weeklyPerStock,
      'useBotStrategy': useBotStrategy,
      'targetAmount': targetAmount,
      'selectedTickers': selectedTickers,
      'lastUpdated': FieldValue.serverTimestamp(),
      'achievedMilestones': achievedMilestones.map((m) => m.toMap()).toList(),
    };
  }

  MidasSettings copyWith({
    int? years,
    double? weeklyPerStock,
    bool? useBotStrategy,
    double? targetAmount,
    List<String>? selectedTickers,
    List<MidasMilestone>? achievedMilestones,
  }) {
    return MidasSettings(
      years: years ?? this.years,
      weeklyPerStock: weeklyPerStock ?? this.weeklyPerStock,
      useBotStrategy: useBotStrategy ?? this.useBotStrategy,
      targetAmount: targetAmount ?? this.targetAmount,
      selectedTickers: selectedTickers ?? this.selectedTickers,
      lastUpdated: DateTime.now(),
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
    );
  }
}

/// Віха (milestone) на шляху до мільйона
class MidasMilestone {
  final double amount;
  final String title;
  final String emoji;
  final DateTime? achievedAt;
  final bool isAchieved;

  MidasMilestone({
    required this.amount,
    required this.title,
    required this.emoji,
    this.achievedAt,
    this.isAchieved = false,
  });

  factory MidasMilestone.fromMap(Map<String, dynamic> data) {
    return MidasMilestone(
      amount: (data['amount'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      emoji: data['emoji'] ?? '🏆',
      achievedAt: (data['achievedAt'] as Timestamp?)?.toDate(),
      isAchieved: data['isAchieved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'title': title,
      'emoji': emoji,
      'achievedAt': achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
      'isAchieved': isAchieved,
    };
  }

  MidasMilestone copyWith({bool? isAchieved, DateTime? achievedAt}) {
    return MidasMilestone(
      amount: amount,
      title: title,
      emoji: emoji,
      achievedAt: achievedAt ?? this.achievedAt,
      isAchieved: isAchieved ?? this.isAchieved,
    );
  }
}

/// Стандартні віхи
List<MidasMilestone> getDefaultMilestones() {
  return [
    MidasMilestone(amount: 10000, title: 'Перші 10K', emoji: '🌱'),
    MidasMilestone(amount: 25000, title: 'Чверть сотні', emoji: '🌿'),
    MidasMilestone(amount: 50000, title: 'Півсотні', emoji: '🌳'),
    MidasMilestone(amount: 100000, title: 'Перші 100K', emoji: '💎'),
    MidasMilestone(amount: 250000, title: 'Чверть мільйона', emoji: '🚀'),
    MidasMilestone(amount: 500000, title: 'Півмільйона', emoji: '⭐'),
    MidasMilestone(amount: 750000, title: 'Три чверті', emoji: '🔥'),
    MidasMilestone(amount: 1000000, title: 'МІЛЬЙОН!', emoji: '👑'),
  ];
}

/// Дані для графіку прогресу
class ProgressPoint {
  final int year;
  final double value;
  final double invested;

  ProgressPoint({
    required this.year,
    required this.value,
    required this.invested,
  });
}
