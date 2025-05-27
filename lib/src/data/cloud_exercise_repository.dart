// lib/src/data/cloud_exercise_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

/// Облачный репозиторий упражнений
class CloudExerciseRepository {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudExerciseRepository(String uid)
      : _col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exercises');

  Future<Exercise> create(Exercise e) async {
    // используем строковый doc ID = локальный целочисленный ID
    await _col.doc(e.id.toString()).set(e.toMap());
    return e;
  }

  Future<void> update(Exercise e) async {
    await _col.doc(e.id.toString()).set(e.toMap());
  }

  Future<void> delete(int id) async {
    await _col.doc(id.toString()).delete();
  }

  Future<List<Exercise>> getAll() async {
    final snaps = await _col.get();
    return snaps.docs.map((d) {
      final m = d.data();
      return Exercise.fromMap({...m, 'id': int.parse(d.id)});
    }).toList();
  }
}
