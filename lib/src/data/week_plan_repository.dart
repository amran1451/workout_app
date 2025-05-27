// lib/src/data/week_plan_repository.dart

import 'package:sqflite/sqflite.dart';
import 'local/db_service.dart';
import '../models/week_plan.dart';

class WeekPlanRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Получить или создать запись в week_plans по startDate = monday.millisecondsSinceEpoch
  Future<WeekPlan> getOrCreateForDate(DateTime monday) async {
    final db = await dbService.database;
    final key = monday.millisecondsSinceEpoch;
    final maps = await db.query(
      'week_plans',
      where: 'startDate = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      final m = maps.first;
      return WeekPlan(
        id: (m['id'] as int).toString(),
        startDate:
            DateTime.fromMillisecondsSinceEpoch(m['startDate'] as int),
      );
    } else {
      final idInt =
          await db.insert('week_plans', {'startDate': key});
      return WeekPlan(
        id: idInt.toString(),
        startDate: monday,
      );
    }
  }
}
