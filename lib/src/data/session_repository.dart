// lib/src/data/session_repository.dart
import 'package:sqflite/sqflite.dart';
import '../models/workout_session.dart';
import '../models/session_entry.dart';  // <-- импорт модели
import 'local/db_service.dart';

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  Future<WorkoutSession> create(WorkoutSession session) async {
    final db = await dbService.database;
    final sid = await db.insert('sessions', session.toMap());
    for (var e in session.entries) {
      await db.insert('entries', e.toDbMap(sid));  // <-- toDbMap
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
      await db.insert('entries', e.toDbMap(id));  // <-- toDbMap
    }
  }

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

  Future<void> deleteSession(String sessionId) async {
    final db = await dbService.database;
    final id = int.parse(sessionId);
    await db.delete('entries',
        where: 'session_id = ?', whereArgs: [id]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}
