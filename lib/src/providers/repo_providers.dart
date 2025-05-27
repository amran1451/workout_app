// lib/src/providers/repo_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/i_exercise_repository.dart';
import '../data/exercise_repository.dart';

import '../data/i_session_repository.dart';
import '../data/session_repository.dart';
import '../data/cloud_session_repository.dart';
import '../data/sync_session_repository.dart';

import '../data/i_week_plan_repository.dart';
import '../data/week_plan_repository.dart';
import '../data/cloud_week_plan_repository.dart';
import '../data/sync_week_plan_repository.dart';

import '../data/i_week_assignment_repository.dart';
import '../data/week_assignment_repository.dart';
import '../data/cloud_week_assignment_repository.dart';
import '../data/sync_week_assignment_repository.dart';

import 'local_provider.dart';

/// Провайдер текущего UID пользователя Firebase
final userUidProvider = Provider<String>((_) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('User is not signed in');
  return user.uid;
});

/// Репозиторий упражнений — локальный
final exerciseRepoProvider = Provider<IExerciseRepository>((ref) {
  return ExerciseRepository();
});

/// Репозиторий тренировочных сессий — локальный + облако
final sessionRepoProvider = Provider<ISessionRepository>((ref) {
  final uid = ref.watch(userUidProvider);
  final local = SessionRepository();
  final cloud = CloudSessionRepository(uid);
  final conn = ref.watch(connectivityProvider);
  return SyncSessionRepository(local, cloud, conn);
});

/// Репозиторий недельных планов — локальный + облако
final weekPlanRepoProvider = Provider<IWeekPlanRepository>((ref) {
  final uid = ref.watch(userUidProvider);
  final local = WeekPlanRepository(ref.read(databaseServiceProvider));
  final cloud = CloudWeekPlanRepository(uid);
  final conn = ref.watch(connectivityProvider);
  return SyncWeekPlanRepository(local, cloud, conn);
});

/// Репозиторий заданий в недельном плане — локальный + облако
final weekAssignmentRepoProvider = Provider<IWeekAssignmentRepository>((ref) {
  final uid = ref.watch(userUidProvider);
  final local = WeekAssignmentRepository(ref.read(databaseServiceProvider));
  final cloud = CloudWeekAssignmentRepository(uid);
  final conn = ref.watch(connectivityProvider);
  return SyncWeekAssignmentRepository(local, cloud, conn);
});
