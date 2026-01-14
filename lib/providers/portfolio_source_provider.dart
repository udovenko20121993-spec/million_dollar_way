import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/portfolio_source.dart';

// Provider for selected portfolio source
final selectedPortfolioSourceProvider = StateProvider<PortfolioSource>((ref) {
  return PortfolioSource.ibkr; // Default to IBKR
});

// Provider for available sources
final availablePortfolioSourcesProvider = Provider<List<PortfolioSource>>((
  ref,
) {
  return PortfolioSource.values;
});

// Provider for selected source display name
final selectedSourceDisplayNameProvider = Provider<String>((ref) {
  final selectedSource = ref.watch(selectedPortfolioSourceProvider);
  return selectedSource.displayName;
});

// Provider for selected source full name
final selectedSourceFullNameProvider = Provider<String>((ref) {
  final selectedSource = ref.watch(selectedPortfolioSourceProvider);
  return selectedSource.displayName; // Use displayName instead of description
});
