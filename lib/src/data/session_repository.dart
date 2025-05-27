// lib/src/data/session_repository.dart

import 'package:sqflite/sqflite.dart';
import '../models/workout_session.dart';
import '../models/session_entry.dart';
import '../local/db_service.dart';
import '../data/cloud_session_repository.dart';

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Создаёт новую сессию и её записи в SQLite,
  /// помечая её как не синхронизированную.
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

  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    final id = int.parse(session.id!);
    await db.update(
      'sessions',
      {
        'date': session.date.toIso8601String(),
        'comment': session.comment,
        // при любом апдейте сбрасываем синк-флаг
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

  Future<List<WorkoutSession>> getAll() async {
    final db = await dbService.database;
    final sessionMaps =
        await db.query('sessions', orderBy: 'date DESC');
    final sessions = <WorkoutSession>[];

    for (var m in sessionMaps) {
      final idInt = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [idInt],
      );

      final entries = entriesMaps.map((e) {
        return SessionEntry.fromMap({
          'id': (e['id'] as int).toString(),
          'exerciseId': e['exercise_id'] as int,
          'completed': (e['completed'] as int) == 1,
          'comment': e['comment'] as String?,
          'weight': (e['weight'] as num?)?.toDouble(),
          'reps': e['reps'] as int?,
          'sets': e['sets'] as int?,
        });
      }).toList();

      sessions.add(WorkoutSession.fromMap({
        'id': idInt.toString(),
        'date': m['date'],
        'comment': m['comment'],
      }, entries));
    }
    return sessions;
  }

  /// Возвращает все локальные сессии, ещё не синхронизированные
  Future<List<WorkoutSession>> getUnsynced() async {
    final db = await dbService.database;
    final maps = await db.query(
      'sessions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    final list = <WorkoutSession>[];
    for (var m in maps) {
      final idInt = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [idInt],
      );
      final entries = entriesMaps.map((e) {
        return SessionEntry.fromMap({
          'id': (e['id'] as int).toString(),
          'exerciseId': e['exercise_id'] as int,
          'completed': (e['completed'] as int) == 1,
          'comment': e['comment'] as String?,
          'weight': (e['weight'] as num?)?.toDouble(),
          'reps': e['reps'] as int?,
          'sets': e['sets'] as int?,
        });
      }).toList();
      list.add(WorkoutSession(
        id: idInt.toString(),
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return list;
  }

  /// Помечает локальную сессию как синхронизированную и сохраняет cloudId
  Future<void> markSynced(String localId, String cloudId) async {
    final db = await dbService.database;
    final idInt = int.parse(localId);
    await db.update(
      'sessions',
      {'cloud_id': cloudId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [idInt],
    );
  }

  /// Пробует синхронизировать все незасинкённые
  Future<void> syncPending(CloudSessionRepository cloudRepo) async {
    final pending = await getUnsynced();
    for (var s in pending) {
      final cloudS = await cloudRepo.create(s);
      await markSynced(s.id!, cloudS.id);
    }
  }

  /// Удаление сессии
  Future<void> deleteSession(String sessionId) async {
    final db = await dbService.database;
    final id = int.parse(sessionId);
    await db.delete('entries',
        where: 'session_id = ?', whereArgs: [id]);
    await db.delete('sessions',
        where: 'id = ?', whereArgs: [id]);
  }
}
