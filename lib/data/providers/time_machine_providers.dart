import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/milestone.dart';
import '../../services/mdw_engine.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/portfolio_providers.dart';
import '../../data/providers/report_providers.dart';

class TimeMachineParams {
  final double monthlyContribution;
  final double expectedAnnualReturn;
  final int projectionYears;

  const TimeMachineParams({
    required this.monthlyContribution,
    required this.expectedAnnualReturn,
    required this.projectionYears,
  });

  TimeMachineParams copyWith({
    double? monthlyContribution,
    double? expectedAnnualReturn,
    int? projectionYears,
  }) {
    return TimeMachineParams(
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      expectedAnnualReturn: expectedAnnualReturn ?? this.expectedAnnualReturn,
      projectionYears: projectionYears ?? this.projectionYears,
    );
  }
}

class TimeMachineProgress {
  final double currentValue;
  final double goalValue;
  final double progressPercent;
  final int? yearsToGoal;

  const TimeMachineProgress({
    required this.currentValue,
    required this.goalValue,
    required this.progressPercent,
    required this.yearsToGoal,
  });
}

final timeMachineParamsProvider = StateProvider<TimeMachineParams>((ref) {
  return const TimeMachineParams(
    monthlyContribution: 1200,
    expectedAnnualReturn: 12,
    projectionYears: 15,
  );
});

final milestonesProvider = StreamProvider.autoDispose<List<Milestone>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) {
    return const Stream.empty();
  }

  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getMilestones(userId);
});

final timeMachineProjectionProvider = FutureProvider.autoDispose<List<FlSpot>>((
  ref,
) async {
  final params = ref.watch(timeMachineParamsProvider);
  final summary = await ref.watch(portfolioSummaryProvider.future);
  final currentCapital = summary?.totalValueUah ?? 0.0;

  final points = MDWEngine.instance.calculateProjectionSeries(
    initialCapital: currentCapital,
    monthlyContribution: params.monthlyContribution,
    expectedAnnualReturn: params.expectedAnnualReturn / 100,
    projectionYears: params.projectionYears,
  );

  return points.map((point) => FlSpot(point.year, point.value)).toList();
});

final timeMachineProgressProvider = Provider<TimeMachineProgress>((ref) {
  final summaryAsync = ref.watch(portfolioSummaryProvider);
  final params = ref.watch(timeMachineParamsProvider);

  const goalValue = 1000000.0;

  final currentValue = summaryAsync.maybeWhen(
    data: (summary) => summary?.totalValueUah ?? 0.0,
    orElse: () => 0.0,
  );

  final progressPercent = goalValue == 0
      ? 0.0
      : (currentValue / goalValue * 100).clamp(0, 100).toDouble();

  int? yearsToGoal;
  if (currentValue >= goalValue) {
    yearsToGoal = 0;
  } else if (params.monthlyContribution > 0) {
    yearsToGoal = MDWEngine.instance.estimateYearsToGoal(
      currentCapital: currentValue,
      monthlyContribution: params.monthlyContribution,
      expectedAnnualReturn: params.expectedAnnualReturn / 100,
      goalValue: goalValue,
    );
  }

  return TimeMachineProgress(
    currentValue: currentValue,
    goalValue: goalValue,
    progressPercent: progressPercent,
    yearsToGoal: yearsToGoal,
  );
});
