import 'i_exercise_repository.dart';
import '../models/exercise.dart';
import 'repository.dart'; // здесь определён ExerciseRepository

/// Локальная реализация, использующая SQLite через ExerciseRepository
class LocalExerciseRepository implements IExerciseRepository {
  final ExerciseRepository _repo = ExerciseRepository();

  @override
  Future<Exercise> create(Exercise e) => _repo.create(e);

  @override
  Future<void> delete(int id) => _repo.delete(id);

  @override
  Future<List<Exercise>> getAll() => _repo.getAll();

  @override
  Future<void> update(Exercise e) => _repo.update(e);
}
