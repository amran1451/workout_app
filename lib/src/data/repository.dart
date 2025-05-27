import 'package:sqflite/sqflite.dart';
import '../models/workout_session.dart';
import '../models/session_entry.dart';
import 'local/db_service.dart';

class SessionRepository {
  final DatabaseService dbService = DatabaseService.instance;

  /// Создаёт новую сессию и её записи в SQLite
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

  /// Обновляет сессию и её записи
  Future<void> update(WorkoutSession session) async {
    final db = await dbService.database;
    final id = int.parse(session.id!);
    await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    // удаляем старые записи
    await db.delete(
      'entries',
      where: 'session_id = ?',
      whereArgs: [id],
    );
    // вставляем новые
    for (var e in session.entries) {
      await db.insert('entries', e.toDbMap(id));
    }
  }

  /// Возвращает все сессии вместе с их записями
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
        // вручную собираем карту для SessionEntry.fromMap
        return SessionEntry.fromMap({
          'id': e['id'].toString(),
          'exerciseId': e['exerciseId'],
          'completed': e['completed'],
          'comment': e['comment'],
          'weight': e['weight'],
          'reps': e['reps'],
          'sets': e['sets'],
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

  /// Удаляет сессию и её записи
  Future<void> deleteSession(String sessionId) async {
    final db = await dbService.database;
    final id = int.parse(sessionId);
    await db.delete('entries',
        where: 'session_id = ?', whereArgs: [id]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}
