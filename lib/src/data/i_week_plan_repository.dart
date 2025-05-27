import '../models/week_plan.dart';

/// Интерфейс репозитория недельных планов
abstract class IWeekPlanRepository {
  Future<WeekPlan> getOrCreateForDate(DateTime weekStart);
}
