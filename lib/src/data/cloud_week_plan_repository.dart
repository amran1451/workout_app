import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/week_plan.dart';
import 'i_week_plan_repository.dart';

/// Облачный (Firestore) репозиторий недельных планов
class CloudWeekPlanRepository implements IWeekPlanRepository {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudWeekPlanRepository(String uid)
      : _col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('week_plans');

  @override
  Future<WeekPlan> getOrCreateForDate(DateTime weekStart) async {
    final docId = weekStart.toIso8601String();
    final docRef = _col.doc(docId);
    final snap = await docRef.get();
    if (snap.exists) {
      return WeekPlan.fromMap({
        'id': docId,
        'startDate': snap.data()!['startDate'] as String,
      });
    } else {
      final newPlan = WeekPlan(id: docId, startDate: weekStart);
      await docRef.set(newPlan.toMap());
      return newPlan;
    }
  }
}
