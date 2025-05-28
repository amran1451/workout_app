import '../models/week_assignment.dart';

/// Универсальный интерфейс для WeekAssignment
abstract class IWeekAssignmentRepository {
  Future<List<WeekAssignment>> getByWeekPlan(int planId);
  Future<void> saveForWeekPlan(int planId, List<WeekAssignment> assignments);
}
