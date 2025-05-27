import '../models/week_plan.dart';
import 'local/db_service.dart';
import 'i_week_plan_repository.dart';

/// Локальный (sqflite) репозиторий недельных планов
class WeekPlanRepository implements IWeekPlanRepository {
  final DatabaseService dbService;
  WeekPlanRepository(this.dbService);

  @override
  Future<WeekPlan> getOrCreateForDate(DateTime date) async {
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    final db = await dbService.database;
    final list = await db.query(
      'week_plans',
      where: 'startDate = ?',
      whereArgs: [monday.millisecondsSinceEpoch],
    );
    if (list.isNotEmpty) {
      final m = list.first;
      return WeekPlan(
        id: m['id'].toString(),
        startDate: DateTime.fromMillisecondsSinceEpoch(m['startDate'] as int),
      );
    }
    final newId = await db.insert(
      'week_plans',
      {'startDate': monday.millisecondsSinceEpoch},
    );
    return WeekPlan(id: newId.toString(), startDate: monday);
  }
}
