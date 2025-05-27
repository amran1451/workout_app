import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/week_assignment.dart';
import 'i_week_assignment_repository.dart';
import '../utils/id_utils.dart';

/// Облачный (Firestore) репозиторий заданий в недельном плане
class CloudWeekAssignmentRepository implements IWeekAssignmentRepository {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudWeekAssignmentRepository(String uid)
      : _col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('week_plans');

  @override
  Future<List<WeekAssignment>> getByWeekPlan(int planId) async {
    final docId = planId.toString();
    final snap = await _col.doc(docId).collection('assignments').get();
    return snap.docs.map((d) {
      final m = d.data();
      return WeekAssignment(
        id: toIntId(d.id),
        weekPlanId: planId,
        exerciseId: m['exerciseId'] as int,
        dayOfWeek: m['dayOfWeek'] as int,
        defaultWeight: (m['defaultWeight'] as num?)?.toDouble(),
        defaultReps: m['defaultReps'] as int?,
        defaultSets: m['defaultSets'] as int?,
      );
    }).toList();
  }

  @override
  Future<void> saveForWeekPlan(
      int planId, List<WeekAssignment> assignments) async {
    final docId = planId.toString();
    final ref = _col.doc(docId).collection('assignments');
    final batch = FirebaseFirestore.instance.batch();
    final old = await ref.get();
    for (var d in old.docs) batch.delete(d.reference);
    for (var a in assignments) {
      final docRef = ref.doc();
      batch.set(docRef, {
        'exerciseId': a.exerciseId,
        'dayOfWeek': a.dayOfWeek,
        'defaultWeight': a.defaultWeight,
        'defaultReps': a.defaultReps,
        'defaultSets': a.defaultSets,
      });
    }
    await batch.commit();
  }
}
