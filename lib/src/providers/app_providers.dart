// lib/src/providers/app_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/exercise_repository.dart';
import '../data/cloud_exercise_repository.dart';
import '../data/session_repository.dart';
import '../data/cloud_session_repository.dart';

/// Текущий Firebase UID
final uidProvider = Provider<String>((ref) {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) throw Exception('User not signed in');
  return u.uid;
});

/// Локальный репозиторий упражнений
final exerciseLocalRepoProvider =
    Provider<ExerciseRepository>((ref) => ExerciseRepository());

/// Облачный репозиторий упражнений
final cloudExerciseRepoProvider = Provider<CloudExerciseRepository>(
  (ref) => CloudExerciseRepository(ref.read(uidProvider)),
);

/// Локальный репозиторий сессий
final sessionRepoProvider =
    Provider<SessionRepository>((ref) => SessionRepository());

/// Облачный репозиторий сессий
final cloudSessionRepoProvider = Provider<CloudSessionRepository>(
  (ref) => CloudSessionRepository(ref.read(uidProvider)),
);
