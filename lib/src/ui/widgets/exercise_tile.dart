import 'package:flutter/material.dart';
import '../../models/exercise.dart';

typedef OnEdit = void Function(Exercise);
typedef OnDelete = void Function(int);

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final OnEdit onEdit;
  final OnDelete onDelete;

  const ExerciseTile({
    Key? key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(exercise.name),
      subtitle: Text(
         "Вес: ${exercise.weight?.toString() ?? '-'} кг, Повт.: ${exercise.reps?.toString() ?? '-'}, Под.: ${exercise.sets?.toString() ?? '-'}"
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => onEdit(exercise),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => onDelete(exercise.id!),
          ),
        ],
      ),
    );
  }
}