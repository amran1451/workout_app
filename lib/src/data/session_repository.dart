// lib/src/data/session_repository.dart

import 'package:sqflite/sqflite.dart';
import 'local/db_service.dart';
import '../models/session_entry.dart';
import '../models/workout_session.dart';
import 'cloud_session_repository.dart';

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Создать новую сессию локально
  Future<WorkoutSession> create(WorkoutSession session) async {
    final db = await dbService.database;
    // 1) вставляем саму сессию
    final localId = await db.insert('sessions', {
      'date': session.date.toIso8601String(),
      'comment': session.comment,
      'cloud_id': null,
      'is_synced': 0,
    });
    // 2) вставляем записи, в snake_case
    for (var e in session.entries) {
      await db.insert('entries', {
        'exercise_id': e.exerciseId,
        'completed': e.completed ? 1 : 0,
        'comment': e.comment,
        'weight': e.weight,
        'reps': e.reps,
        'sets': e.sets,
        'session_id': localId,
      });
    }
    return WorkoutSession(
      id: localId.toString(),
      date: session.date,
      comment: session.comment,
      entries: session.entries,
    );
  }

  /// Обновить существующую сессию локально
  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    final localId = int.parse(session.id!);
    await db.update(
      'sessions',
      {
        'date': session.date.toIso8601String(),
        'comment': session.comment,
        'is_synced': 0, // сбрасываем метку sync
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
    // удаляем старые entries
    await db.delete('entries', where: 'session_id = ?', whereArgs: [localId]);
    // вставляем новые
    for (var e in session.entries) {
      await db.insert('entries', {
        'exercise_id': e.exerciseId,
        'completed': e.completed ? 1 : 0,
        'comment': e.comment,
        'weight': e.weight,
        'reps': e.reps,
        'sets': e.sets,
        'session_id': localId,
      });
    }
  }

  /// Получить все сессии
  Future<List<WorkoutSession>> getAll() async {
    final db = await dbService.database;
    final sessions = <WorkoutSession>[];
    final maps = await db.query('sessions', orderBy: 'date DESC');
    for (var m in maps) {
      final sid = m['id'] as int;
      // вытаскиваем записи
      final rows = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [sid],
      );
      final entries = rows.map((r) {
        // приводим к тому виду, что ожидает SessionEntry.fromMap
        final map = <String, dynamic>{
          'id': (r['id'] as int).toString(),
          'exerciseId': r['exercise_id'],
          'completed': (r['completed'] as int) == 1,
          'comment': r['comment'],
          'weight': (r['weight'] as num?)?.toDouble(),
          'reps': r['reps'],
          'sets': r['sets'],
        };
        return SessionEntry.fromMap(map);
      }).toList();
      sessions.add(WorkoutSession(
        id: sid.toString(),
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return sessions;
  }

  /// Удалить сессию
  Future<int> deleteSession(int sessionId) async {
    final db = await dbService.database;
    await db.delete('entries', where: 'session_id = ?', whereArgs: [sessionId]);
    return db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  /// Получить последнюю запись по упражнению
  Future<SessionEntry?> getLastEntryForExercise(int exerciseId) async {
    final db = await dbService.database;
    final rows = await db.rawQuery('''
      SELECT e.id, e.exercise_id, e.completed, e.comment, e.weight, e.reps, e.sets
      FROM entries e
      JOIN sessions s ON e.session_id = s.id
      WHERE e.exercise_id = ?
      ORDER BY s.date DESC
      LIMIT 1
    ''', [exerciseId]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return SessionEntry.fromMap({
      'id': (r['id'] as int).toString(),
      'exerciseId': r['exercise_id'],
      'completed': (r['completed'] as int) == 1,
      'comment': r['comment'],
      'weight': (r['weight'] as num?)?.toDouble(),
      'reps': r['reps'],
      'sets': r['sets'],
    });
  }

  /// Синхронизация — получить все несинхронизированные
  Future<List<WorkoutSession>> getUnsynced() async {
    final db = await dbService.database;
    final maps = await db.query('sessions', where: 'is_synced = ?', whereArgs: [0]);
    final pending = <WorkoutSession>[];
    for (var m in maps) {
      final sid = m['id'] as int;
      final rows = await db.query('entries', where: 'session_id = ?', whereArgs: [sid]);
      final entries = rows.map((r) {
        final map = <String, dynamic>{
          'id': (r['id'] as int).toString(),
          'exerciseId': r['exercise_id'],
          'completed': (r['completed'] as int) == 1,
          'comment': r['comment'],
          'weight': (r['weight'] as num?)?.toDouble(),
          'reps': r['reps'],
          'sets': r['sets'],
        };
        return SessionEntry.fromMap(map);
      }).toList();
      pending.add(WorkoutSession(
        id: sid.toString(),
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return pending;
  }

  /// После пуша пометить как синхронизированное
  Future<void> markSynced(int localId, String cloudId) async {
    final db = await dbService.database;
    await db.update(
      'sessions',
      {'cloud_id': cloudId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Пуш всех pending в Firestore
  Future<void> syncPending(CloudSessionRepository cloudRepo) async {
    final unsynced = await getUnsynced();
    for (var sess in unsynced) {
      final localId = int.parse(sess.id!);
      final cloudSess = await cloudRepo.create(sess);
      await markSynced(localId, cloudSess.id!);
    }
  }
}
