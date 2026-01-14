import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/ibkr_data.dart';
import '../domain/enums/portfolio_source.dart';
import '../providers/portfolio_source_provider.dart';
import '../utils/user_session.dart';

// Provider for filtered portfolio data based on selected source
final filteredPortfolioProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final selectedSource = ref.watch(selectedPortfolioSourceProvider);

  switch (selectedSource) {
    case PortfolioSource.ibkr:
      return _getIbkrPortfolioStream();
    case PortfolioSource.univer:
      return _getUniverPortfolioStream();
    case PortfolioSource.privatfond:
      return _getPrivatfondPortfolioStream();
  }
});

// Provider for total balance of selected source
final selectedSourceBalanceProvider = StreamProvider<double>((ref) {
  final selectedSource = ref.watch(selectedPortfolioSourceProvider);

  switch (selectedSource) {
    case PortfolioSource.ibkr:
      return _getIbkrBalanceStream();
    case PortfolioSource.univer:
      return _getUniverBalanceStream();
    case PortfolioSource.privatfond:
      return _getPrivatfondBalanceStream();
  }
});

// Provider for assets list of selected source
final selectedSourceAssetsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final selectedSource = ref.watch(selectedPortfolioSourceProvider);

    switch (selectedSource) {
      case PortfolioSource.ibkr:
        return _getIbkrAssetsStream();
      case PortfolioSource.univer:
        return _getUniverAssetsStream();
      case PortfolioSource.privatfond:
        return _getPrivatfondAssetsStream();
    }
  },
);

// IBKR Streams
Stream<Map<String, dynamic>> _getIbkrPortfolioStream() {
  // Get current user ID
  final userId = UserSession.userId;
  if (userId == null) {
    return Stream.value({
      'totalBalance': 0.0,
      'assets': <Map<String, dynamic>>[],
    });
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('reports')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return {'totalBalance': 0.0, 'assets': <Map<String, dynamic>>[]};
        }

        final doc = snapshot.docs.first;
        final data = doc.data();

        // Convert to IBKRReport
        final report = IBKRReport.fromFirestore(doc);

        // Convert IBKR assets to standard format
        final assets = report.positions
            .map(
              (position) => {
                'symbol': position.symbol,
                'quantity': position.quantity,
                'value': position.marketValue,
                'currency': 'USD', // IBKR assets are in USD
              },
            )
            .toList();

        return {
          'totalBalance': report.lastBalance,
          'assets': assets,
          'report': report,
        };
      });
}

Stream<double> _getIbkrBalanceStream() {
  return _getIbkrPortfolioStream().map(
    (data) => data['totalBalance'] as double,
  );
}

Stream<List<Map<String, dynamic>>> _getIbkrAssetsStream() {
  return _getIbkrPortfolioStream().map(
    (data) => data['assets'] as List<Map<String, dynamic>>,
  );
}

// Univer Streams (placeholder)
Stream<Map<String, dynamic>> _getUniverPortfolioStream() {
  return Stream.value({
    'totalBalance': 0.0, // No real data yet
    'assets': <Map<String, dynamic>>[], // Empty until integration
  });
}

Stream<double> _getUniverBalanceStream() {
  return Stream.value(0.0); // No real data yet
}

Stream<List<Map<String, dynamic>>> _getUniverAssetsStream() {
  return Stream.value(<Map<String, dynamic>>[]); // Empty until integration
}

// Privatfond Streams (placeholder)
Stream<Map<String, dynamic>> _getPrivatfondPortfolioStream() {
  return Stream.value({
    'totalBalance': 0.0, // No real data yet
    'assets': <Map<String, dynamic>>[], // Empty until integration
  });
}

Stream<double> _getPrivatfondBalanceStream() {
  return Stream.value(0.0); // No real data yet
}

Stream<List<Map<String, dynamic>>> _getPrivatfondAssetsStream() {
  return Stream.value(<Map<String, dynamic>>[]); // Empty until integration
}

// Combined total balance across all sources
final totalPortfolioBalanceProvider = Provider<double>((ref) {
  final ibkrBalance = ref.watch(selectedSourceBalanceProvider);
  final selectedSource = ref.watch(selectedPortfolioSourceProvider);

  // For now, return only the selected source balance
  // Later we can combine all sources if needed
  return ibkrBalance.when(
    data: (balance) => balance,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
