// lib/src/providers/app_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/exercise.dart';
import '../models/session_entry.dart';
import '../models/week_assignment.dart';
import '../models/week_plan.dart';
import '../models/workout_session.dart';

import '../providers/session_provider.dart';

import '../data/local/db_service.dart';
import '../data/exercise_repository.dart';
import '../data/repository.dart' show ExerciseRepository;
import '../data/session_repository.dart' show SessionRepository;
import '../data/cloud_exercise_repository.dart';
import '../data/cloud_session_repository.dart';

/// Текущий Firebase User ID
final uidProvider = Provider<String>((_) {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) throw Exception('User not signed in');
  return u.uid;
});

/// Локальный репозиторий упражнений
final exerciseRepoProvider =
    Provider<ExerciseRepository>((_) => ExerciseRepository());

/// Облачный репозиторий упражнений
final cloudExerciseRepoProvider =
    Provider<CloudExerciseRepository>(
        (ref) => CloudExerciseRepository(ref.read(uidProvider)));

/// UI-список упражнений (берёт из Firestore, синхронизирует локально)
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
    // синхронизировать локально
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
    await ref.read(cloudExerciseRepoProvider).delete(e.id!);
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

/// Локальный репозиторий упражнений
final exerciseLocalRepoProvider =
    Provider<ExerciseRepository>((_) => ExerciseRepository());

/// Облачный репозиторий упражнений
final cloudExerciseRepoProvider = Provider<CloudExerciseRepository>(
  (ref) => CloudExerciseRepository(ref.read(uidProvider)),
);

/// UI-список записей сессии (WorkoutPage)
final sessionEntriesProvider =
    StateProvider<List<SessionEntry>>((_) => []);
