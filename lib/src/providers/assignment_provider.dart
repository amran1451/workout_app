// lib/src/providers/assignment_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/assignment_repository.dart';
import '../models/exercise_assignment.dart';

final assignmentRepoProvider =
    Provider<AssignmentRepository>((ref) => AssignmentRepository());

final assignmentListProvider =
    StateNotifierProvider<AssignmentNotifier, List<ExerciseAssignment>>(
  (ref) => AssignmentNotifier(ref),
);

class AssignmentNotifier extends StateNotifier<List<ExerciseAssignment>> {
  final Ref ref;
  AssignmentNotifier(this.ref) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await ref.read(assignmentRepoProvider).getAll();
  }

  Future<void> assign(int exerciseId, int day) async {
    await ref.read(assignmentRepoProvider).create(
      ExerciseAssignment(exerciseId: exerciseId, dayOfWeek: day),
    );
    await load();
  }

  Future<void> clearDay(int day) async {
    await ref.read(assignmentRepoProvider).clearDay(day);
    await load();
  }

  Future<void> remove(int id) async {
    await ref.read(assignmentRepoProvider).remove(id);
    await load();
  }

  /// Очищает весь план на неделю
  Future<void> clearAll() async {
    await ref.read(assignmentRepoProvider).clearAll();
    await load();
  }
}
