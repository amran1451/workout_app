import '../models/workout_session.dart';
import '../models/workout_session.dart' show SessionEntry;
import 'local/db_service.dart';
import 'i_session_repository.dart';

/// Локальный (sqflite) репозиторий тренировочных сессий
class SessionRepository implements ISessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  @override
  Future<WorkoutSession> create(WorkoutSession session) async {
    final db = await dbService.database;
    final sid = await db.insert('sessions', session.toMap());
    for (var e in session.entries) {
      await db.insert('entries', e.toMap(sid));
    }
    return WorkoutSession(
      id: sid.toString(),
      date: session.date,
      comment: session.comment,
      entries: session.entries,
    );
  }

  @override
  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [int.parse(session.id!)],
    );
    await db.delete(
      'entries',
      where: 'session_id = ?',
      whereArgs: [int.parse(session.id!)],
    );
    for (var e in session.entries) {
      await db.insert('entries', e.toMap(int.parse(session.id!)));
    }
  }

  @override
  Future<List<WorkoutSession>> getAll() async {
    final db = await dbService.database;
    final maps = await db.query('sessions', orderBy: 'date DESC');
    final sessions = <WorkoutSession>[];
    for (var m in maps) {
      final entriesMaps = await db.query(
        'entries',
        where: 'session_id = ?',
        whereArgs: [m['id']],
      );
      final entries =
          entriesMaps.map((e) => SessionEntry.fromMap(e)).toList();
      sessions.add(WorkoutSession.fromMap(m, entries));
    }
    return sessions;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final db = await dbService.database;
    await db.delete(
      'entries',
      where: 'session_id = ?',
      whereArgs: [int.parse(sessionId)],
    );
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [int.parse(sessionId)],
    );
  }
}
