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

import 'connectivity_provider.dart';
import 'local_provider.dart';

/// 1) UID текущего пользователя
final userUidProvider = Provider<String>((_) {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) throw StateError('User not signed in');
  return u.uid;
});

/// 2) Репозиторий упражнений (только локальный)
final exerciseRepoProvider = Provider<IExerciseRepository>((_) {
  return ExerciseRepository();
});

/// 3) Репозиторий сессий (локально + облако)
final sessionRepoProvider = Provider<ISessionRepository>((ref) {
  final uid = ref.read(userUidProvider);
  final local = SessionRepository();
  final cloud = CloudSessionRepository(uid);
  final conn = ref.read(connectivityProvider);
  return SyncSessionRepository(local, cloud, conn);
});

/// 4) Репозиторий планов недели (локально + облако)
final weekPlanRepoProvider = Provider<IWeekPlanRepository>((ref) {
  final uid = ref.read(userUidProvider);
  final local = WeekPlanRepository(ref.read(databaseServiceProvider));
  final cloud = CloudWeekPlanRepository(uid);
  final conn = ref.read(connectivityProvider);
  return SyncWeekPlanRepository(local, cloud, conn);
});

/// 5) Репозиторий заданий недели (локально + облако)
final weekAssignmentRepoProvider =
    Provider<IWeekAssignmentRepository>((ref) {
  final uid = ref.read(userUidProvider);
  final local = WeekAssignmentRepository(ref.read(databaseServiceProvider));
  final cloud = CloudWeekAssignmentRepository(uid);
  final conn = ref.read(connectivityProvider);
  return SyncWeekAssignmentRepository(local, cloud, conn);
});
