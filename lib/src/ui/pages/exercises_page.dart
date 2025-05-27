import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/exercise_provider.dart';
import '../../routes.dart';
import '../widgets/exercise_tile.dart';

class ExercisesPage extends ConsumerWidget {
  const ExercisesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exerciseListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Мои упражнения')),
      body: ListView(
        children: exercises.map((e) => ExerciseTile(
          exercise: e,
          onEdit: (ex) async {
            await Navigator.pushNamed(
              context,
              Routes.exerciseForm,
              arguments: ex,  // передаём объект для редактирования
            );
            ref.read(exerciseListProvider.notifier).load();
          },
          onDelete: (id) => ref.read(exerciseListProvider.notifier).delete(id),
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, Routes.exerciseForm)
            .then((_) => ref.read(exerciseListProvider.notifier).load()),
      ),
    );
  }
}