import '../models/week_assignment.dart';

/// Интерфейс репозитория заданий в плане на неделю
abstract class IWeekAssignmentRepository {
  Future<List<WeekAssignment>> getByWeekPlan(int planId);
  Future<void> saveForWeekPlan(int planId, List<WeekAssignment> assignments);
}
