import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/session_repository.dart';
import '../models/session_entry.dart'; 
import '../models/workout_session.dart';

final sessionRepoProvider = Provider<SessionRepository>((ref) => SessionRepository());

final historyProvider = FutureProvider.autoDispose<List<WorkoutSession>>(
  (ref) => ref.read(sessionRepoProvider).getAll(),
);

final sessionEntriesProvider = StateProvider<List<SessionEntry>>((ref) => []);