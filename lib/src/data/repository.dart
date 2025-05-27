// lib/src/data/repository.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'local/db_service.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart' show WorkoutSession, SessionEntry;

class ExerciseRepository {
  final DatabaseService dbService = DatabaseService.instance;

  Future<Exercise> create(Exercise exercise) async {
    final db = await dbService.database;
    final id = await db.insert('exercises', exercise.toMap());
    exercise.id = id;
    return exercise;
  }

  Future<List<Exercise>> getAll() async {
    final db = await dbService.database;
    final maps = await db.query('exercises');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<int> update(Exercise exercise) async {
    final db = await dbService.database;
    return db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await dbService.database;
    return db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }
}

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Создаёт новую тренировочную сессию и её записи.
  Future<WorkoutSession> create(WorkoutSession session) async {
    final db = await dbService.database;
    final sid = await db.insert('sessions', session.toMap());
    for (var e in session.entries) {
      await db.insert('entries', e.toDbMap(sid));
    }
    return WorkoutSession(
      id: sid.toString(),
      date: session.date,
      comment: session.comment,
      entries: session.entries,
    );
  }

  /// Обновляет сессию и её записи.
  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    final id = int.parse(session.id!);
    await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'entries',
      where: 'session_id = ?',
      whereArgs: [id],
    );
    for (var e in session.entries) {
      await db.insert('entries', e.toDbMap(id));
    }
  }

  /// Получает все сессии с их записями.
  Future<List<WorkoutSession>> getAll() async {
    final db = await dbService.database;
    final sessionMaps = await db.query('sessions', orderBy: 'date DESC');
    final sessions = <WorkoutSession>[];
    for (var m in sessionMaps) {
      final idInt = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [idInt],
      );
      final entries = entriesMaps
          .map<SessionEntry>((e) => SessionEntry.fromMap(e))
          .toList();
      sessions.add(WorkoutSession.fromMap(
        {
          ...m,
          'id': idInt.toString(),
        },
        entries,
      ));
    }
    return sessions;
  }

  /// Удаляет сессию вместе с её записями.
  Future<void> deleteSession(String sessionId) async {
    final db = await dbService.database;
    final id = int.parse(sessionId);
    await db.delete('entries', where: 'session_id = ?', whereArgs: [id]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}