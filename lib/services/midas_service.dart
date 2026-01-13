import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/midas_settings.dart';
import '../models/ibkr_data.dart';

/// Сервіс для Мідаса - розрахунки та Firestore
class MidasService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  MidasService({required this.userId});

  // ============== НАЛАШТУВАННЯ ==============

  /// Отримати налаштування (Stream)
  Stream<MidasSettings> getSettingsStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('midas')
        .doc('settings')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return MidasSettings();
      return MidasSettings.fromFirestore(doc);
    });
  }

  /// Отримати налаштування (одноразово)
  Future<MidasSettings> getSettings() async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('midas')
        .doc('settings')
        .get();

    if (!doc.exists) return MidasSettings();
    return MidasSettings.fromFirestore(doc);
  }

  /// Зберегти налаштування
  Future<void> saveSettings(MidasSettings settings) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('midas')
        .doc('settings')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  // ============== РОЗРАХУНКИ ==============

  /// Розрахунок прогнозу (симулятор)
  SimulationResult calculateSimulation({
    required int years,
    required double weeklyPerStock,
    required int stockCount,
    required bool useBot,
  }) {
    double monthlyTotal = (stockCount * weeklyPerStock * 52) / 12;
    int totalMonths = years * 12;
    double totalInvested = monthlyTotal * totalMonths;
    
    double annualRate = useBot ? 0.20 : 0.10;
    double monthlyRate = annualRate / 12;
    
    double estimatedValue = totalInvested * math.pow(1 + monthlyRate, totalMonths);
    double profit = estimatedValue - totalInvested;

    // Генеруємо точки для графіку
    List<ProgressPoint> progressPoints = [];
    int currentYear = DateTime.now().year;
    
    for (int y = 0; y <= years; y += (years > 10 ? 2 : 1)) {
      int months = y * 12;
      double invested = monthlyTotal * months;
      double value = invested * math.pow(1 + monthlyRate, months);
      
      progressPoints.add(ProgressPoint(
        year: currentYear + y,
        value: value,
        invested: invested,
      ));
    }

    // Рік досягнення мільйона
    int? yearToMillion;
    for (int m = 1; m <= totalMonths; m++) {
      double invested = monthlyTotal * m;
      double value = invested * math.pow(1 + monthlyRate, m);
      if (value >= 1000000 && yearToMillion == null) {
        yearToMillion = currentYear + (m / 12).ceil();
        break;
      }
    }

    return SimulationResult(
      totalInvested: totalInvested,
      estimatedValue: estimatedValue,
      profit: profit,
      profitPercent: (profit / totalInvested) * 100,
      monthlyContribution: monthlyTotal,
      annualRate: annualRate,
      progressPoints: progressPoints,
      yearToMillion: yearToMillion,
    );
  }

  /// Розрахунок прогресу до цілі
  ProgressToGoal calculateProgress({
    required double currentValue,
    required double targetAmount,
    required double monthlyContribution,
    required double annualRate,
  }) {
    double progressPercent = (currentValue / targetAmount) * 100;
    if (progressPercent > 100) progressPercent = 100;

    // Розрахунок часу до цілі
    int? monthsToGoal;
    if (currentValue < targetAmount && monthlyContribution > 0) {
      double monthlyRate = annualRate / 12;
      
      // Формула: FV = PV*(1+r)^n + PMT*((1+r)^n - 1)/r
      // Розв'язуємо відносно n (ітеративно)
      for (int m = 1; m <= 600; m++) { // Макс 50 років
        double fv = currentValue * math.pow(1 + monthlyRate, m) +
            monthlyContribution * (math.pow(1 + monthlyRate, m) - 1) / monthlyRate;
        if (fv >= targetAmount) {
          monthsToGoal = m;
          break;
        }
      }
    }

    return ProgressToGoal(
      currentValue: currentValue,
      targetAmount: targetAmount,
      progressPercent: progressPercent,
      remaining: targetAmount - currentValue,
      monthsToGoal: monthsToGoal,
      yearsToGoal: monthsToGoal != null ? (monthsToGoal / 12) : null,
    );
  }

  // ============== IBKR ІНТЕГРАЦІЯ ==============

  /// Отримати реальний портфель з IBKR
  Future<IBKRComparison?> getIBKRComparison() async {
    try {
      // Отримуємо останній звіт
      final reportsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('reports')
          .orderBy('lastSyncTime', descending: true)
          .limit(1)
          .get();

      if (reportsSnapshot.docs.isEmpty) return null;

      final report = IBKRReport.fromFirestore(reportsSnapshot.docs.first);
      
      // Отримуємо налаштування Мідаса
      final settings = await getSettings();
      
      // Рахуємо симуляцію
      final simulation = calculateSimulation(
        years: settings.years,
        weeklyPerStock: settings.weeklyPerStock,
        stockCount: 51, // Стандартна кількість
        useBot: settings.useBotStrategy,
      );

      return IBKRComparison(
        realBalance: report.lastBalance,
        simulatedBalance: simulation.estimatedValue,
        difference: report.lastBalance - simulation.estimatedValue,
        differencePercent: ((report.lastBalance - simulation.estimatedValue) / 
                           simulation.estimatedValue) * 100,
        realAssets: report.assets,
        lastSyncTime: report.lastSyncTime,
      );
    } catch (e) {
      print('Error getting IBKR comparison: $e');
      return null;
    }
  }

  // ============== ВІХИ ==============

  /// Оновити досягнуті віхи
  Future<List<MidasMilestone>> updateMilestones(
    double currentValue,
    List<MidasMilestone> milestones,
  ) async {
    bool hasChanges = false;
    final updatedMilestones = milestones.map((m) {
      if (!m.isAchieved && currentValue >= m.amount) {
        hasChanges = true;
        return m.copyWith(isAchieved: true, achievedAt: DateTime.now());
      }
      return m;
    }).toList();

    if (hasChanges) {
      final settings = await getSettings();
      await saveSettings(settings.copyWith(achievedMilestones: updatedMilestones));
    }

    return updatedMilestones;
  }
}

/// Результат симуляції
class SimulationResult {
  final double totalInvested;
  final double estimatedValue;
  final double profit;
  final double profitPercent;
  final double monthlyContribution;
  final double annualRate;
  final List<ProgressPoint> progressPoints;
  final int? yearToMillion;

  SimulationResult({
    required this.totalInvested,
    required this.estimatedValue,
    required this.profit,
    required this.profitPercent,
    required this.monthlyContribution,
    required this.annualRate,
    required this.progressPoints,
    this.yearToMillion,
  });
}

/// Прогрес до цілі
class ProgressToGoal {
  final double currentValue;
  final double targetAmount;
  final double progressPercent;
  final double remaining;
  final int? monthsToGoal;
  final double? yearsToGoal;

  ProgressToGoal({
    required this.currentValue,
    required this.targetAmount,
    required this.progressPercent,
    required this.remaining,
    this.monthsToGoal,
    this.yearsToGoal,
  });
}

/// Порівняння з IBKR
class IBKRComparison {
  final double realBalance;
  final double simulatedBalance;
  final double difference;
  final double differencePercent;
  final List<IBKRAsset> realAssets;
  final DateTime? lastSyncTime;

  IBKRComparison({
    required this.realBalance,
    required this.simulatedBalance,
    required this.difference,
    required this.differencePercent,
    required this.realAssets,
    this.lastSyncTime,
  });

  bool get isAheadOfPlan => realBalance >= simulatedBalance;
}
