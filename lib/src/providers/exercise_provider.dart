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

  /// Загрузить все упражнения
  Future<void> load() async {
    final repo = ref.read(exerciseLocalRepoProvider);
    state = await repo.getAll();
  }

  /// Добавить
  Future<void> add(Exercise e) async {
    final repo = ref.read(exerciseLocalRepoProvider);
    await repo.create(e);
    await load();
  }

  /// Обновить
  Future<void> update(Exercise e) async {
    final repo = ref.read(exerciseLocalRepoProvider);
    await repo.update(e);
    await load();
  }

  /// Удалить
  Future<void> delete(int id) async {
    final repo = ref.read(exerciseLocalRepoProvider);
    await repo.delete(id);
    await load();
  }
}
