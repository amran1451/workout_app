// lib/src/data/exercise_repository.dart

import 'package:sqflite/sqflite.dart';
import '../local/db_service.dart';
import '../models/exercise.dart';
import 'cloud_exercise_repository.dart';

class ExerciseRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Create local; returns with assigned id
  Future<Exercise> create(Exercise e) async {
    final db = await dbService.database;
    final id = await db.insert('exercises', e.toDbMap());
    e.id = id;
    // mark unsynced by default
    await db.update(
      'exercises',
      {'is_synced': 0, 'cloud_id': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    return e;
  }

  Future<void> update(Exercise e) async {
    final db = await dbService.database;
    final id = e.id!;
    await db.update(
      'exercises',
      {...e.toDbMap(), 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Exercise>> getAll() async {
    final db = await dbService.database;
    final maps = await db.query('exercises');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<List<Exercise>> getUnsynced() async {
    final db = await dbService.database;
    final maps = await db.query(
      'exercises',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<void> markSynced(Exercise e, String cloudId) async {
    final db = await dbService.database;
    await db.update(
      'exercises',
      {'cloud_id': cloudId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  /// Push all pending local to Firestore
  Future<void> syncPending(CloudExerciseRepository cloudRepo) async {
    final list = await getUnsynced();
    for (var e in list) {
      final cloudE = await cloudRepo.create(e);
      await markSynced(e, cloudE.id!);
    }
  }
}
