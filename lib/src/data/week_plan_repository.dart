import '../models/week_plan.dart';
import 'local/db_service.dart';
import 'i_week_plan_repository.dart';

class WeekPlanRepository implements IWeekPlanRepository {
  final dbService = DatabaseService.instance;

  @override
  Future<WeekPlan> getOrCreateForDate(DateTime date) async {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final db = await dbService.database;
    final list = await db.query(
      'week_plans',
      where: 'startDate = ?',
      whereArgs: [monday.toIso8601String()],
    );
    if (list.isNotEmpty) {
      return WeekPlan.fromMap({
        'id': list.first['id'].toString(),
        'startDate': list.first['startDate'] as String,
      });
    }
    final id = await db.insert('week_plans', {
      'startDate': monday.toIso8601String(),
    });
    return WeekPlan(id: id.toString(), startDate: monday);
  }
}
