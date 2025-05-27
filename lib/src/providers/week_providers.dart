import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/week_plan_repository.dart';
import '../data/week_assignment_repository.dart';
import 'local_provider.dart';
import '../models/week_assignment.dart';
import '../utils/id_utils.dart';

final weekPlanRepoProvider = Provider<WeekPlanRepository>(
  (ref) => WeekPlanRepository(ref.read(databaseServiceProvider)),
);

final weekAssignmentRepoProvider = Provider<WeekAssignmentRepository>(
  (ref) => WeekAssignmentRepository(ref.read(databaseServiceProvider)),
);

final currentWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
});

final weekAssignmentsProvider =
    FutureProvider.autoDispose<List<WeekAssignment>>((ref) async {
  final monday = ref.watch(currentWeekStartProvider);
  final plan = await ref.read(weekPlanRepoProvider).getOrCreateForDate(monday);
  final planId = toIntId(plan.id);
  return ref.read(weekAssignmentRepoProvider).getByWeekPlan(planId);
});
