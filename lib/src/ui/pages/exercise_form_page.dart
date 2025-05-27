// lib/src/ui/pages/exercise_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/exercise.dart';
import '../../data/exercise_repository.dart';
import '../../data/cloud_exercise_repository.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_provider.dart';

class ExerciseFormPage extends ConsumerStatefulWidget {
  const ExerciseFormPage({Key? key}) : super(key: key);
  @override
  ConsumerState<ExerciseFormPage> createState() =>
      _ExerciseFormPageState();
}

class _ExerciseFormPageState extends ConsumerState<ExerciseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _wCtrl = TextEditingController();
  final _rCtrl = TextEditingController();
  final _sCtrl = TextEditingController();
  final _nCtrl = TextEditingController();

  Exercise? _editing;
  bool _isEditing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEditing) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Exercise) {
        _editing = args;
        _isEditing = true;
        _nameCtrl.text = args.name;
        _wCtrl.text = args.weight?.toString() ?? '';
        _rCtrl.text = args.reps?.toString() ?? '';
        _sCtrl.text = args.sets?.toString() ?? '';
        _nCtrl.text = args.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wCtrl.dispose();
    _rCtrl.dispose();
    _sCtrl.dispose();
    _nCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактировать упражнение' : 'Новое упражнение',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите название' : null,
              ),
              TextFormField(
                controller: _wCtrl,
                decoration: const InputDecoration(labelText: 'Вес (кг)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _rCtrl,
                decoration: const InputDecoration(labelText: 'Повторы'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _sCtrl,
                decoration: const InputDecoration(labelText: 'Подходы'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _nCtrl,
                decoration: const InputDecoration(labelText: 'Заметки'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  // Сбор данных
                  final name = _nameCtrl.text;
                  final weight = _wCtrl.text.isNotEmpty
                      ? double.parse(_wCtrl.text)
                      : null;
                  final reps = _rCtrl.text.isNotEmpty
                      ? int.parse(_rCtrl.text)
                      : null;
                  final sets = _sCtrl.text.isNotEmpty
                      ? int.parse(_sCtrl.text)
                      : null;
                  final notes =
                      _nCtrl.text.isNotEmpty ? _nCtrl.text : null;

                  // 1) локальное сохранение
                  final local = ref.read(exerciseLocalRepoProvider);
                  late Exercise e;
                  if (_isEditing && _editing != null) {
                    e = _editing!
                      ..name = name
                      ..weight = weight
                      ..reps = reps
                      ..sets = sets
                      ..notes = notes;
                    await local.update(e);
                  } else {
                    e = Exercise(
                      name: name,
                      weight: weight,
                      reps: reps,
                      sets: sets,
                      notes: notes,
                    );
                    e = await local.create(e);
                  }

                  // 2) пуш в облако
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final cloud = ref.read(cloudExerciseRepoProvider);
                    final cloudE = _isEditing
                        ? await cloud.update(e).then((_) => e)
                        : await cloud.create(e);
                    await local.markSynced(
                        e, cloudE.id!.toString());
                  }

                  // 3) обновить список
                  ref
                      .read(exerciseListProvider.notifier)
                      .load();

                  Navigator.pop(context);
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
