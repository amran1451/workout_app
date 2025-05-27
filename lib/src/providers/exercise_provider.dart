// lib/src/providers/exercise_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import 'app_providers.dart';

/// Провайдер списка упражнений (локальный)
final exerciseListProvider =
    StateNotifierProvider<ExerciseListNotifier, List<Exercise>>(
  (ref) => ExerciseListNotifier(ref),
);

class ExerciseListNotifier extends StateNotifier<List<Exercise>> {
  final Ref ref;
  ExerciseListNotifier(this.ref) : super([]) {
    load();
  }

  /// Загрузить все упражнения из локального репозитория
  Future<void> load() async {
    final repo = ref.read(exerciseLocalRepoProvider);
    state = await repo.getAll();
  }

  /// Добавить упражнение
  Future<void> add(Exercise exercise) async {
    final repo = ref.read(exerciseLocalRepoProvider);
    await repo.create(exercise);
    await load();
  }

  /// Обновить упражнение
  Future<void> update(Exercise exercise) async {
    final repo = ref.read(exerciseLocalRepoProvider);
    await repo.update(exercise);
    await load();
  }

  /// Удалить упражнение
  Future<void> delete(int id) async {
    final repo = ref.read(exerciseLocalRepoProvider);
    await repo.delete(id);
    await load();
  }
}
