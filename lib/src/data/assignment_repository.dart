// lib/src/data/assignment_repository.dart

import 'package:sqflite/sqflite.dart';
import 'local/db_service.dart';
import '../models/exercise_assignment.dart';

class AssignmentRepository {
  final DatabaseService dbService = DatabaseService.instance;

  Future<ExerciseAssignment> create(ExerciseAssignment a) async {
    final db = await dbService.database;
    final id = await db.insert('assignments', a.toMap());
    return ExerciseAssignment(id: id, exerciseId: a.exerciseId, dayOfWeek: a.dayOfWeek);
  }

  Future<List<ExerciseAssignment>> getAll() async {
    final db = await dbService.database;
    final maps = await db.query('assignments');
    return maps.map((m) => ExerciseAssignment.fromMap(m)).toList();
  }

  Future<int> remove(int id) async {
    final db = await dbService.database;
    return db.delete('assignments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearDay(int day) async {
    final db = await dbService.database;
    return db.delete('assignments', where: 'day = ?', whereArgs: [day]);
  }

  /// Удаляет **все** записи плана на неделю
  Future<int> clearAll() async {
    final db = await dbService.database;
    return db.delete('assignments');
  }
}
