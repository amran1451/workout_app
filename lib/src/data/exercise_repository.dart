import '../models/exercise.dart';
import 'local/db_service.dart';
import 'i_exercise_repository.dart';

/// Локальный (sqflite) репозиторий упражнений
class ExerciseRepository implements IExerciseRepository {
  final DatabaseService dbService = DatabaseService.instance;

  @override
  Future<Exercise> create(Exercise exercise) async {
    final db = await dbService.database;
    final id = await db.insert('exercises', exercise.toMap());
    exercise.id = id;
    return exercise;
  }

  @override
  Future<List<Exercise>> getAll() async {
    final db = await dbService.database;
    final maps = await db.query('exercises');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  @override
  Future<void> update(Exercise exercise) async {
    final db = await dbService.database;
    await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await dbService.database;
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }
}
