import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_week_plan_repository.dart';
import 'week_plan_repository.dart';
import 'cloud_week_plan_repository.dart';
import '../models/week_plan.dart';

class SyncWeekPlanRepository implements IWeekPlanRepository {
  final WeekPlanRepository local;
  final CloudWeekPlanRepository cloud;
  final Connectivity connectivity;

  SyncWeekPlanRepository(this.local, this.cloud, this.connectivity);

  Future<bool> get _hasNetwork async =>
      (await connectivity.checkConnectivity()) != ConnectivityResult.none;

  @override
  Future<WeekPlan> getOrCreateForDate(DateTime weekStart) async {
    final localPlan = await local.getOrCreateForDate(weekStart);
    if (await _hasNetwork) {
      try {
        // создаём в облаке, но не дублируем, если уже есть
        await cloud.getOrCreateForDate(weekStart);
      } catch (_) {}
    }
    return localPlan;
  }
}
