import '../models/week_assignment.dart';
import 'local/db_service.dart';
import 'i_week_assignment_repository.dart';

class WeekAssignmentRepository implements IWeekAssignmentRepository {
  final dbService = DatabaseService.instance;

  @override
  Future<List<WeekAssignment>> getByWeekPlan(int planId) async {
    final db = await dbService.database;
    final maps = await db.query(
      'week_assignments',
      where: 'weekPlanId = ?',
      whereArgs: [planId],
    );
    return maps.map((m) => WeekAssignment.fromMap(m)).toList();
  }

  @override
  Future<void> saveForWeekPlan(
      int planId, List<WeekAssignment> assignments) async {
    final db = await dbService.database;
    await db.delete(
      'week_assignments',
      where: 'weekPlanId = ?',
      whereArgs: [planId],
    );
    for (var a in assignments) {
      final map = a.toMap();
      map['weekPlanId'] = planId;
      map.remove('id');
      await db.insert('week_assignments', map);
    }
  }
}
