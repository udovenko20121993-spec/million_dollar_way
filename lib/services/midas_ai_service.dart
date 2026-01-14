import 'package:firebase_auth/firebase_auth.dart';

import '../domain/models/custom_portfolio_models.dart';

class MidasAiService {
  static final MidasAiService _instance = MidasAiService._();
  factory MidasAiService() => _instance;
  MidasAiService._();

  String _resolveUserName() {
    final rawName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) {
      return 'Олександре';
    }
    return trimmed.split(' ').first;
  }

  void initializeUser() {
    // Placeholder for future AI initialization logic.
  }

  Future<String> sendMessage(
    String message,
    InvestmentSnapshot snapshot,
  ) async {
    final userName = _resolveUserName();
    return 'Вибач, $userName, інтерактивний чат Мідаса тимчасово недоступний.';
  }

  Future<String> generateInsightFromSnapshot(
    InvestmentSnapshot snapshot,
  ) async {
    final userName = _resolveUserName();
    final profitLoss = snapshot.accountSummary.totalProfitLoss;
    final currentBalance = snapshot.accountSummary.currentBalance;

    final portfolioState = profitLoss >= 0 ? 'зростає' : 'коригується';
    final growth = currentBalance > 0
        ? ((profitLoss / currentBalance) * 100).toStringAsFixed(2)
        : '0.00';

    return '$userName, Ваш портфель $portfolioState на $growth% Поточний баланс: \$${currentBalance.toStringAsFixed(2)}.';
  }

  Future<String> generateMidasNarrative(
    String visualStateName,
    dynamic portfolioContext,
  ) async {
    final userName = _resolveUserName();

    double profitLoss = 0;
    if (portfolioContext is InvestmentSnapshot) {
      profitLoss = portfolioContext.accountSummary.totalProfitLoss;
    } else if (portfolioContext is Map<String, dynamic>) {
      final totalValue =
          (portfolioContext['totalValue'] as num?)?.toDouble() ?? 0.0;
      final balance = (portfolioContext['balance'] as num?)?.toDouble() ?? 0.0;
      profitLoss = totalValue - balance;
    }

    final portfolioState = profitLoss >= 0
        ? 'росте впевнено'
        : 'коригується, але тримає курс';
    return '$userName, Ваш капітал на шляху до мільйона. Стан ядра: $visualStateName, портфель $portfolioState.';
  }
}
