import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import 'i_exercise_repository.dart';

/// Облачный (Firestore) репозиторий упражнений
class CloudExerciseRepository implements IExerciseRepository {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudExerciseRepository(String uid)
      : _col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exercises');

  @override
  Future<Exercise> create(Exercise e) async {
    final ref = await _col.add(e.toMap());
    final snap = await ref.get();
    final data = snap.data()!;
    return Exercise.fromMap({'id': int.tryParse(snap.id) ?? 0, ...data});
  }

  @override
  Future<List<Exercise>> getAll() async {
    final snap = await _col.get();
    return snap.docs.map((d) {
      final m = d.data();
      return Exercise.fromMap({'id': int.tryParse(d.id) ?? 0, ...m});
    }).toList();
  }

  @override
  Future<void> update(Exercise e) async {
    await _col.doc(e.id.toString()).update(e.toMap());
  }

  @override
  Future<void> delete(int id) async {
    await _col.doc(id.toString()).delete();
  }
}
