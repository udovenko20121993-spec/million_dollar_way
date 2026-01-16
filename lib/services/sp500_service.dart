import 'dart:collection';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

/// Fetches historical daily close prices for S&P 500.
///
/// Uses Stooq free CSV endpoint for the index: `^SPX`.
/// Data columns: Date,Open,High,Low,Close,Volume
class Sp500Service {
  static const String _stooqUrl = 'https://stooq.com/q/d/l/?s=%5Espx&i=d';

  /// Simple in-memory cache keyed by URL.
  static SplayTreeMap<DateTime, double>? _cachedDailyClose;

  Future<SplayTreeMap<DateTime, double>> fetchDailyClose() async {
    final cached = _cachedDailyClose;
    if (cached != null && cached.isNotEmpty) return cached;

    final response = await http.get(Uri.parse(_stooqUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch S&P500 data (${response.statusCode}).');
    }

    final converter = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: true,
    );
    final rows = converter.convert(response.body);
    if (rows.isEmpty) {
      throw Exception('Empty S&P500 CSV response.');
    }

    // Skip header if present.
    final startIdx =
        rows.isNotEmpty && rows.first.isNotEmpty && rows.first.first == 'Date'
            ? 1
            : 0;

    final map = SplayTreeMap<DateTime, double>();
    for (int i = startIdx; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;

      final dateStr = row[0]?.toString();
      final closeRaw = row[4];
      if (dateStr == null || dateStr.isEmpty) continue;

      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final close = closeRaw is num
          ? closeRaw.toDouble()
          : double.tryParse(closeRaw?.toString() ?? '');
      if (close == null || close <= 0) continue;

      // Normalize to UTC midnight to simplify matching.
      final normalized = DateTime.utc(date.year, date.month, date.day);
      map[normalized] = close;
    }

    if (map.isEmpty) {
      throw Exception('Parsed S&P500 series is empty.');
    }

    _cachedDailyClose = map;
    return map;
  }

  /// Returns close price for [date] or the most recent prior trading day.
  double? closeOnOrBefore(
    SplayTreeMap<DateTime, double> series,
    DateTime date,
  ) {
    if (series.isEmpty) return null;

    final d = DateTime.utc(date.year, date.month, date.day);
    final exact = series[d];
    if (exact != null) return exact;

    final keys = series.keys.toList(growable: false);
    int lo = 0;
    int hi = keys.length - 1;
    int bestIdx = -1;

    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final midDate = keys[mid];
      if (midDate.isBefore(d) || midDate.isAtSameMomentAs(d)) {
        bestIdx = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    if (bestIdx < 0) return null;
    return series[keys[bestIdx]];
  }
}

