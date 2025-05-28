// lib/src/data/session_repository.dart

import 'package:sqflite/sqflite.dart';
import 'local/db_service.dart';
import '../models/workout_session.dart';
import 'cloud_session_repository.dart';

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// создаёт или обновляет локальную сессию (как было)
  Future<WorkoutSession> create(WorkoutSession session) async {
    final db = await dbService.database;
    final id = await db.insert('sessions', session.toMap());
    for (var e in session.entries) {
      await db.insert('entries', e.toDbMap(id));
    }
    // помечаем как несинхронизированную
    await db.update(
      'sessions',
      {'is_synced': 0, 'cloud_id': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    return WorkoutSession(
      id: id,
      date: session.date,
      comment: session.comment,
      entries: session.entries,
    );
  }

  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    final id = session.id!;
    await db.update(
      'sessions',
      session.toMap()..['is_synced'] = 0,
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
    final maps = await db.query('sessions', orderBy: 'date DESC');
    final out = <WorkoutSession>[];
    for (var m in maps) {
      final sid = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [sid],
      );
      final entries = entriesMaps.map((e) => SessionEntry.fromMap(e)).toList();
      out.add(WorkoutSession.fromMap(m, entries));
    }
    return out;
  }

  Future<int> deleteSession(int sessionId) async {
    final db = await dbService.database;
    await db.delete('entries', where: 'session_id = ?', whereArgs: [sessionId]);
    return db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // ——————— новые методы для sync ———————

  /// возвращает все локальные сессии, помеченные is_synced = 0
  Future<List<WorkoutSession>> getUnsynced() async {
    final db = await dbService.database;
    final maps = await db.query(
      'sessions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    final out = <WorkoutSession>[];
    for (var m in maps) {
      final sid = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [sid],
      );
      final entries = entriesMaps.map((e) => SessionEntry.fromMap(e)).toList();
      out.add(WorkoutSession.fromMap(m, entries));
    }
    return out;
  }

  /// после успешного пуша в облако помечает локальную сессию
  Future<void> markSynced(int localId, String cloudId) async {
    final db = await dbService.database;
    await db.update(
      'sessions',
      {'cloud_id': cloudId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// синхронизирует все pending-сессии в Firestore
  Future<void> syncPending(CloudSessionRepository cloudRepo) async {
    final unsynced = await getUnsynced();
    for (var sess in unsynced) {
      if (sess.cloudId == null) {
        // новая — create
        final cloudSess = await cloudRepo.create(sess);
        await markSynced(sess.id!, cloudSess.id!);
      } else {
        // уже было — update
        await cloudRepo.update(sess);
        await markSynced(sess.id!, sess.cloudId!);
      }
    }
  }
}
