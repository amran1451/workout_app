// lib/src/data/session_repository.dart

import 'package:sqflite/sqflite.dart';
import '../models/workout_session.dart';
import '../models/session_entry.dart';
import '../local/db_service.dart';
import 'cloud_session_repository.dart';

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Создаёт новую сессию и её записи в SQLite (is_synced = 0)
  Future<WorkoutSession> create(WorkoutSession session) async {
    final db = await dbService.database;
    final sid = await db.insert('sessions', {
      'date': session.date.toIso8601String(),
      'comment': session.comment,
      'is_synced': 0,
      'cloud_id': null,
    });
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

  /// Обновляет сессию в SQLite и сбрасывает флаг синка
  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    final id = int.parse(session.id!);
    await db.update(
      'sessions',
      {
        'date': session.date.toIso8601String(),
        'comment': session.comment,
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete('entries', where: 'session_id = ?', whereArgs: [id]);
    for (var e in session.entries) {
      await db.insert('entries', e.toDbMap(id));
    }
  }

  /// Читает все сессии с их записями
  Future<List<WorkoutSession>> getAll() async {
    final db = await dbService.database;
    final sessions = <WorkoutSession>[];
    final sessionMaps = await db.query('sessions', orderBy: 'date DESC');

    for (var m in sessionMaps) {
      final sid = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [sid],
      );
      final entries = entriesMaps.map((e) {
        return SessionEntry.fromMap({
          'id': e['id'].toString(),
          'exerciseId': e['exercise_id'],
          'completed': (e['completed'] as int) == 1,
          'comment': e['comment'] as String?,
          'weight': (e['weight'] as num?)?.toDouble(),
          'reps': e['reps'] as int?,
          'sets': e['sets'] as int?,
        });
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

  /// Возвращает локальные сессии, ещё не синхронизированные в облако
  Future<List<WorkoutSession>> getUnsynced() async {
    final db = await dbService.database;
    final pending = <WorkoutSession>[];
    final maps = await db.query('sessions', where: 'is_synced = ?', whereArgs: [0]);
    for (var m in maps) {
      final sid = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [sid],
      );
      final entries = entriesMaps.map((e) {
        return SessionEntry.fromMap({
          'id': e['id'].toString(),
          'exerciseId': e['exercise_id'],
          'completed': (e['completed'] as int) == 1,
          'comment': e['comment'] as String?,
          'weight': (e['weight'] as num?)?.toDouble(),
          'reps': e['reps'] as int?,
          'sets': e['sets'] as int?,
        });
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

  /// Помечает уже синхронизированную сессию (cloud_id + is_synced = 1)
  Future<void> markSynced(String localId, String cloudId) async {
    final db = await dbService.database;
    final lid = int.parse(localId);
    await db.update(
      'sessions',
      {'cloud_id': cloudId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [lid],
    );
  }

  /// Синхронизирует все несинкнутые сессии
  Future<void> syncPending(CloudSessionRepository cloudRepo) async {
    final pending = await getUnsynced();
    for (var s in pending) {
      final cloudS = await cloudRepo.create(s);
      await markSynced(s.id!, cloudS.id);
    }
  }

  /// Полное удаление сессии
  Future<void> deleteSession(String sessionId) async {
    final db = await dbService.database;
    final sid = int.parse(sessionId);
    await db.delete('entries', where: 'session_id = ?', whereArgs: [sid]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [sid]);
  }
}
