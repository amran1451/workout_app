import 'package:connectivity_plus/connectivity_plus.dart';
import 'i_week_assignment_repository.dart';
import 'week_assignment_repository.dart';
import 'cloud_week_assignment_repository.dart';
import '../models/week_assignment.dart';

class SyncWeekAssignmentRepository implements IWeekAssignmentRepository {
  final WeekAssignmentRepository local;
  final CloudWeekAssignmentRepository cloud;
  final Connectivity connectivity;

  SyncWeekAssignmentRepository(this.local, this.cloud, this.connectivity);

  Future<bool> get _hasNetwork async =>
      (await connectivity.checkConnectivity()) != ConnectivityResult.none;

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
