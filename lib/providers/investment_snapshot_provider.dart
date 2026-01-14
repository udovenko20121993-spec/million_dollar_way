import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/custom_portfolio_models.dart';
import '../services/investment_logic_service.dart';

// Current user ID provider (should be replaced with actual auth provider)
final currentUserIdProvider = Provider<String>((ref) {
  // TODO: Get actual user ID from auth service
  return 'default_user';
});

/// Provider for investment snapshot data
final investmentSnapshotProvider = FutureProvider.autoDispose<InvestmentSnapshot?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final service = InvestmentLogicService();
  return service.processIbkrData(userId);
});
