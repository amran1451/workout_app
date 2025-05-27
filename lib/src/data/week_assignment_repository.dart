// lib/src/data/week_assignment_repository.dart

import 'package:sqflite/sqflite.dart';
import 'local/db_service.dart';
import '../models/week_assignment.dart';

class WeekAssignmentRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Вернуть все задания для плана с PK = weekPlanId
  Future<List<WeekAssignment>> getByWeekPlan(int weekPlanId) async {
    final db = await dbService.database;
    final maps = await db.query(
      'week_assignments',
      where: 'weekPlanId = ?',
      whereArgs: [weekPlanId],
    );
    return maps.map((m) => WeekAssignment.fromMap(m)).toList();
  }

  /// Заменить все задания для данного плана
  Future<void> createAll(
      int weekPlanId, List<WeekAssignment> list) async {
    final db = await dbService.database;
    // Удалить старые
    await db.delete(
      'week_assignments',
      where: 'weekPlanId = ?',
      whereArgs: [weekPlanId],
    );
    // Вставить новые
    for (var a in list) {
      await db.insert('week_assignments', {
        'weekPlanId': weekPlanId,
        'dayOfWeek': a.dayOfWeek,
        'exerciseId': a.exerciseId,
        'defaultWeight': a.defaultWeight,
        'defaultReps': a.defaultReps,
        'defaultSets': a.defaultSets,
      });
    }
  }
}
