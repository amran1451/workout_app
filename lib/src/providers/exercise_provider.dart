// lib/src/providers/exercise_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository.dart';
import '../models/exercise.dart';

/// Провайдер репозитория упражнений
final exerciseRepositoryProvider =
    Provider<ExerciseRepository>((ref) => ExerciseRepository());

/// Провайдер-стейтнотификатор списка упражнений
final exerciseListProvider =
    StateNotifierProvider<ExerciseListNotifier, List<Exercise>>(
  (ref) => ExerciseListNotifier(ref),
);

class ExerciseListNotifier extends StateNotifier<List<Exercise>> {
  final Ref ref;
  ExerciseListNotifier(this.ref) : super([]) {
    load();
  }

  /// Загрузить все упражнения из БД
  Future<void> load() async {
    state = await ref.read(exerciseRepositoryProvider).getAll();
  }

  /// Добавить упражнение
  Future<void> add(Exercise e) async {
    await ref.read(exerciseRepositoryProvider).create(e);
    await load();
  }

  /// Обновить упражнение
  Future<void> update(Exercise e) async {
    await ref.read(exerciseRepositoryProvider).update(e);
    await load();
  }

  /// Удалить упражнение
  Future<void> delete(int id) async {
    await ref.read(exerciseRepositoryProvider).delete(id);
    await load();
  }
}
