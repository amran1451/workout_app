// lib/src/providers/week_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/week_plan_repository.dart';
import '../data/week_assignment_repository.dart';

/// Провайдер хранения текущего начала недели (понедельник)
final currentWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // вычисляем ближайший понедельник
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
});

/// Провайдер локального репозитория недельных планов
final weekPlanRepoProvider =
    Provider<WeekPlanRepository>((ref) => WeekPlanRepository());

/// Провайдер локального репозитория заданий плана
final weekAssignmentRepoProvider =
    Provider<WeekAssignmentRepository>(
        (ref) => WeekAssignmentRepository());
