// lib/src/ui/pages/exercise_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_provider.dart';

class ExerciseFormPage extends ConsumerStatefulWidget {
  const ExerciseFormPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends ConsumerState<ExerciseFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _setsController;
  late TextEditingController _notesController;

  Exercise? _editing;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _weightController = TextEditingController();
    _repsController = TextEditingController();
    _setsController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editing == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Exercise) {
        _editing = args;
        _isEditing = true;
        _nameController.text = _editing!.name;
        _weightController.text = _editing!.weight?.toString() ?? '';
        _repsController.text = _editing!.reps?.toString() ?? '';
        _setsController.text = _editing!.sets?.toString() ?? '';
        _notesController.text = _editing!.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать упражнение' : 'Новое упражнение'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => v == null || v.isEmpty ? 'Введите название' : null,
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Вес (кг)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(labelText: 'Повторы'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _setsController,
                decoration: const InputDecoration(labelText: 'Подходы'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Важные заметки'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text;
                    final weight = _weightController.text.isNotEmpty
                        ? double.parse(_weightController.text)
                        : null;
                    final reps = _repsController.text.isNotEmpty
                        ? int.parse(_repsController.text)
                        : null;
                    final sets = _setsController.text.isNotEmpty
                        ? int.parse(_setsController.text)
                        : null;
                    final notes = _notesController.text.isNotEmpty
                        ? _notesController.text
                        : null;

                    final repo = ref.read(exerciseListProvider.notifier);
                    if (_isEditing && _editing != null) {
                      _editing!
                        ..name = name
                        ..weight = weight
                        ..reps = reps
                        ..sets = sets
                        ..notes = notes;
                      await repo.update(_editing!);
                    } else {
                      await repo.add(
                        Exercise(
                          name: name,
                          weight: weight,
                          reps: reps,
                          sets: sets,
                          notes: notes,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(_isEditing ? 'Обновить' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}