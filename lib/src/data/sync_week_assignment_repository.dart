import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_week_assignment_repository.dart';
import 'week_assignment_repository.dart';
import 'cloud_week_assignment_repository.dart';
import '../models/week_assignment.dart';

/// Репозиторий «локально + облако» для заданий в недельном плане
class SyncWeekAssignmentRepository implements IWeekAssignmentRepository {
  final WeekAssignmentRepository local;
  final CloudWeekAssignmentRepository cloud;
  final Connectivity connectivity;

  SyncWeekAssignmentRepository(this.local, this.cloud, this.connectivity);

  Future<bool> get _hasNetwork async {
    final res = await connectivity.checkConnectivity();
    return res != ConnectivityResult.none;
  }

  @override
  Future<List<WeekAssignment>> getByWeekPlan(int planId) =>
      local.getByWeekPlan(planId);

  @override
  Future<void> saveForWeekPlan(
      int planId, List<WeekAssignment> assignments) async {
    await local.saveForWeekPlan(planId, assignments);
    if (await _hasNetwork) {
      try {
        await cloud.saveForWeekPlan(planId, assignments);
      } catch (_) {}
    }
  }
}
