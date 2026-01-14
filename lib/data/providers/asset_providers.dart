import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/finnhub_service.dart';
import 'report_providers.dart';

final finnhubServiceProvider = Provider<FinnhubService>((ref) {
  return FinnhubService();
});

final uniqueTickersProvider = Provider.autoDispose<List<String>>((ref) {
  final report = ref.watch(latestReportProvider);
  if (report == null) return const [];

  final symbols = <String>{};

  for (final position in report.positions) {
    if (position.symbol.isNotEmpty) {
      symbols.add(position.symbol.toUpperCase());
    }
  }

  for (final asset in report.assets) {
    if (asset.symbol.isNotEmpty) {
      symbols.add(asset.symbol.toUpperCase());
    }
  }

  for (final trade in report.trades) {
    if (trade.symbol.isNotEmpty) {
      symbols.add(trade.symbol.toUpperCase());
    }
  }

  return symbols.toList()..sort();
});

final assetPricesProvider = FutureProvider.autoDispose<Map<String, double>>((
  ref,
) async {
  final tickers = ref.watch(uniqueTickersProvider);
  if (tickers.isEmpty) return {};

  final finnhub = ref.watch(finnhubServiceProvider);
  try {
    final quotes = await finnhub.getQuotes(tickers);
    return quotes;
  } catch (e) {
    // У випадку помилки повертаємо порожню мапу, UI покаже попередні значення
    return {};
  }
});
