// lib/src/providers/app_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/cloud_exRepositories.dart';
import '../data/session_repository.dart';
import '../data/repository.dart';

import '../models/session_entry.dart';

/// Firebase UID
final uidProvider = Provider<String>((_) {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) throw Exception('Not signed in');
  return u.uid;
});

/// Локальный репозиторий упражнений
final exerciseRepoProvider =
    Provider<ExerciseRepository>((_) => ExerciseRepository());

/// Облачный репозиторий упражнений
final cloudExerciseRepoProvider =
    Provider<CloudExerciseRepository>(
        (ref) => CloudExerciseRepository(ref.read(uidProvider)));

/// Список упражнений (UI StateNotifier) — берет из облака, синхронизирует локально
final exerciseListProvider =
    StateNotifierProvider<ExerciseListNotifier, List<Exercise>>(
  (ref) => ExerciseListNotifier(ref),
);

class ExerciseListNotifier extends StateNotifier<List<Exercise>> {
  final Ref ref;
  ExerciseListNotifier(this.ref) : super([]) {
    load();
  }

  Future<void> load() async {
    final cloud = await ref.read(cloudExerciseRepoProvider).getAll();
    state = cloud;
    // синхронизируем локально
    final local = ref.read(exerciseRepoProvider);
    for (var e in cloud) {
      try {
        await local.update(e);
      } catch (_) {
        await local.create(e);
      }
    }
  }

  Future<void> add(Exercise e) async {
    await ref.read(cloudExerciseRepoProvider).create(e);
    await load();
  }

  Future<void> update(Exercise e) async {
    await ref.read(cloudExerciseRepoProvider).update(e);
    await load();
  }

  Future<void> delete(Exercise e) async {
    await ref.read(cloudExerciseRepoProvider).delete(e.id.toString());
    await load();
  }
}

/// Локальный репозиторий сессий
final sessionRepoProvider =
    Provider<SessionRepository>((_) => SessionRepository());

/// Облачный репозиторий сессий
final cloudSessionRepoProvider =
    Provider<CloudSessionRepository>(
        (ref) => CloudSessionRepository(ref.read(uidProvider)));

/// UI-state записей сессии (WorkoutPage)
final sessionEntriesProvider =
    StateProvider<List<SessionEntry>>((_) => []);
