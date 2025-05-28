import 'package:sqflite/sqflite.dart';
import '../local/db_service.dart';
import '../models/workout_session.dart';
import '../models/session_entry.dart';
import 'cloud_session_repository.dart';

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  Future<WorkoutSession> create(WorkoutSession session) async {
    final db = await dbService.database;
    final localId = await db.insert('sessions', session.toMap()
      ..['cloud_id'] = null
      ..['is_synced'] = 0);
    for (var e in session.entries) {
      final map = e.toMap()..['session_id'] = localId;
      await db.insert('entries', map);
    }
    return WorkoutSession(
      id: localId.toString(),
      date: session.date,
      comment: session.comment,
      entries: session.entries,
    );
  }

  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    final localId = int.parse(session.id!);
    await db.update(
      'sessions',
      session.toMap()..['is_synced'] = 0,
      where: 'id = ?',
      whereArgs: [localId],
    );
    await db.delete('entries', where: 'session_id = ?', whereArgs: [localId]);
    for (var e in session.entries) {
      final map = e.toMap()..['session_id'] = localId;
      await db.insert('entries', map);
    }
  }

  Future<List<WorkoutSession>> getAll() async {
    final db = await dbService.database;
    final maps = await db.query('sessions', orderBy: 'date DESC');
    final out = <WorkoutSession>[];
    for (var m in maps) {
      final localId = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [localId],
      );
      final entries = entriesMaps.map<SessionEntry>((eMap) {
        final map = <String, dynamic>{...eMap};
        map['id'] = (eMap['id'] as int).toString();
        return SessionEntry.fromMap(map);
      }).toList();
      out.add(WorkoutSession(
        id: localId.toString(),
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return out;
  }

  Future<int> deleteSession(int sessionId) async {
    final db = await dbService.database;
    await db.delete('entries', where: 'session_id = ?', whereArgs: [sessionId]);
    return db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<List<WorkoutSession>> getUnsynced() async {
    final db = await dbService.database;
    final maps = await db.query('sessions', where: 'is_synced = ?', whereArgs: [0]);
    final out = <WorkoutSession>[];
    for (var m in maps) {
      final localId = m['id'] as int;
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [localId],
      );
      final entries = entriesMaps.map<SessionEntry>((eMap) {
        final map = <String, dynamic>{...eMap};
        map['id'] = (eMap['id'] as int).toString();
        return SessionEntry.fromMap(map);
      }).toList();
      out.add(WorkoutSession(
        id: localId.toString(),
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return out;
  }

  Future<void> markSynced(int localId, String cloudId) async {
    final db = await dbService.database;
    await db.update(
      'sessions',
      {'cloud_id': cloudId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> syncPending(CloudSessionRepository cloudRepo) async {
    final unsynced = await getUnsynced();
    for (var sess in unsynced) {
      final cloudSess = await cloudRepo.create(sess);
      await markSynced(int.parse(sess.id!), cloudSess.id!);
    }
  }
}
