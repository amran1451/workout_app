import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_week_plan_repository.dart';
import 'week_plan_repository.dart';
import 'cloud_week_plan_repository.dart';
import '../models/week_plan.dart';

/// Репозиторий «локально + облако» для недельных планов
class SyncWeekPlanRepository implements IWeekPlanRepository {
  final WeekPlanRepository local;
  final CloudWeekPlanRepository cloud;
  final Connectivity connectivity;

  SyncWeekPlanRepository(this.local, this.cloud, this.connectivity);

  Future<bool> get _hasNetwork async {
    final res = await connectivity.checkConnectivity();
    return res != ConnectivityResult.none;
  }

  @override
  Future<WeekPlan> getOrCreateForDate(DateTime weekStart) async {
    final localPlan = await local.getOrCreateForDate(weekStart);
    if (await _hasNetwork) {
      try {
        await cloud.getOrCreateForDate(weekStart);
      } catch (_) {}
    }
    return localPlan;
  }
}
