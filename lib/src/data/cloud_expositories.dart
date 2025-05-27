// lib/src/data/cloud_exRepositories.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import '../models/week_assignment.dart';
import '../models/workout_session.dart';
import '../models/week_plan.dart';

/// Базовый интерфейс для облачных репозиториев
abstract class CloudRepo<T> {
  Future<T> create(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
  Future<List<T>> getAll();
}

/// Облачный репозиторий упражнений
class CloudExerciseRepository implements CloudRepo<Exercise> {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudExerciseRepository(String uid)
      : _col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('exercises');

  @override
  Future<Exercise> create(Exercise e) async {
    await _col.doc(e.id.toString()).set(e.toMap());
    return e;
  }

  @override
  Future<void> update(Exercise e) async {
    await _col.doc(e.id.toString()).set(e.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<List<Exercise>> getAll() async {
    final snaps = await _col.get();
    return snaps.docs.map((d) {
      final m = d.data();
      return Exercise.fromMap({...m, 'id': int.parse(d.id)});
    }).toList();
  }
}

/// Облачный репозиторий планов (WeekPlan)
class CloudWeekPlanRepository implements CloudRepo<WeekPlan> {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudWeekPlanRepository(String uid)
      : _col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('week_plans');

  @override
  Future<WeekPlan> create(WeekPlan wp) async {
    await _col.doc(wp.id.toString()).set(wp.toMap());
    return wp;
  }

  @override
  Future<void> update(WeekPlan wp) async {
    await _col.doc(wp.id.toString()).set(wp.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<List<WeekPlan>> getAll() async {
    final snaps = await _col.get();
    return snaps.docs.map((d) {
      final m = d.data();
      return WeekPlan.fromMap({...m, 'id': int.parse(d.id)});
    }).toList();
  }
}

/// Облачный репозиторий назначений в плане (WeekAssignment)
class CloudWeekAssignmentRepository
    implements CloudRepo<WeekAssignment> {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudWeekAssignmentRepository(String uid, int planId)
      : _col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('week_plans')
            .doc(planId.toString())
            .collection('assignments');

  @override
  Future<WeekAssignment> create(WeekAssignment a) async {
    await _col
        .doc(a.id.toString())
        .set(a.toMap()); // a.id должно быть уникальным в плане
    return a;
  }

  @override
  Future<void> update(WeekAssignment a) async {
    await _col.doc(a.id.toString()).set(a.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<List<WeekAssignment>> getAll() async {
    final snaps = await _col.get();
    return snaps.docs.map((d) {
      final m = d.data();
      return WeekAssignment.fromMap({
        ...m,
        'id': int.parse(d.id),
        'weekPlanId': int.parse(_col.parent!.id),
      });
    }).toList();
  }
}

/// Облачный репозиторий тренировочных сессий
class CloudSessionRepository
    implements CloudRepo<WorkoutSession> {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudSessionRepository(String uid)
      : _col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions');

  @override
  Future<WorkoutSession> create(WorkoutSession s) async {
    final doc = await _col.add(s.toMap());
    for (var e in s.entries) {
      await doc
          .collection('entries')
          .doc(e.id.toString())
          .set(e.toMap());
    }
    return WorkoutSession(
      id: doc.id,
      date: s.date,
      comment: s.comment,
      entries: s.entries,
    );
  }

  @override
  Future<void> update(WorkoutSession s) async {
    final docRef = _col.doc(s.id);
    await docRef.set(s.toMap());
    final old =
        await docRef.collection('entries').get();
    for (var d in old.docs) {
      await d.reference.delete();
    }
    for (var e in s.entries) {
      await docRef
          .collection('entries')
          .doc(e.id.toString())
          .set(e.toMap());
    }
  }

  @override
  Future<void> delete(String id) async {
    final docRef = _col.doc(id);
    final entries = await docRef.collection('entries').get();
    for (var d in entries.docs) {
      await d.reference.delete();
    }
    await docRef.delete();
  }

  @override
  Future<List<WorkoutSession>> getAll() async {
    final snaps = await _col.orderBy('date', descending: true).get();
    final out = <WorkoutSession>[];
    for (var doc in snaps.docs) {
      final m = doc.data();
      final ents = await doc.reference
          .collection('entries')
          .get();
      final entries = ents.docs.map((ed) {
        final d = ed.data();
        return SessionEntry.fromMap({
          'id': ed.id,
          ...d,
        });
      }).toList();
      out.add(WorkoutSession(
        id: doc.id,
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return out;
  }
}
