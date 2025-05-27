import '../models/exercise.dart';

/// Универсальный интерфейс для репозиториев упражнений
abstract class IExerciseRepository {
  Future<Exercise> create(Exercise e);
  Future<List<Exercise>> getAll();
  Future<void> update(Exercise e);
  Future<void> delete(int id);
}
