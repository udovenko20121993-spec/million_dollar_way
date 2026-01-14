import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/midas_ai_service.dart';
import 'investment_snapshot_provider.dart';

final midasInsightProvider = FutureProvider.autoDispose<String>((ref) async {
  final snapshotAsync = await ref.watch(investmentSnapshotProvider.future);
  if (snapshotAsync == null) {
    return 'Мідас очікує на перші дані портфеля.';
  }

  final service = MidasAiService();
  return service.generateInsightFromSnapshot(snapshotAsync);
});
