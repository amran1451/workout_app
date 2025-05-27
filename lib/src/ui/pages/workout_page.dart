import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../main.dart';
import '../../routes.dart';
import '../../models/workout_session.dart';
import '../../models/exercise.dart';
import '../../models/week_assignment.dart';
import '../../providers/session_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/week_providers.dart';
import '../../utils/id_utils.dart';
import '../../models/session_entry.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage>
    with WidgetsBindingObserver, RouteAware {
  static const _draftKey = 'workout_draft';
  late TextEditingController _restController;
  bool _isEditing = false;
  WorkoutSession? _editingSession;
  List<SessionEntry> _entries = [];
  bool _isRestDay = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restController = TextEditingController();
    ref.read(exerciseListProvider.notifier).load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WorkoutSession) {
      _isEditing = true;
      _editingSession = args;
      _entries = List.from(args.entries);
      _isRestDay = _entries.isEmpty;
      _restController.text = args.comment ?? '';
      setState(() {});
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_draftKey)) {
      final map = jsonDecode(prefs.getString(_draftKey)!) as Map<String, dynamic>;
      _isRestDay = map['isRest'] as bool;
      _restController.text = map['restComment'] as String;
      _entries = (map['entries'] as List)
          .cast<Map<String, dynamic>>()
          .map((m) => SessionEntry(
                exerciseId: m['exerciseId'] as int,
                completed: m['completed'] as bool,
                comment: m['comment'] as String?,
                weight: (m['weight'] as num?)?.toDouble(),
                reps: m['reps'] as int?,
                sets: m['sets'] as int?,
              ))
          .toList();
      setState(() {});
      return;
    }

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final plan = await ref.read(weekPlanRepoProvider).getOrCreateForDate(monday);
    final planId = toIntId(plan.id);
    final assignments =
        await ref.read(weekAssignmentRepoProvider).getByWeekPlan(planId);
    final today = now.weekday;
    final todays = assignments.where((a) => a.dayOfWeek == today);
    final exercises = ref.read(exerciseListProvider);
    _entries = todays.map((a) {
      final ex = exercises.firstWhere(
        (e) => e.id == a.exerciseId,
        orElse: () => Exercise(id: a.exerciseId, name: 'Неизвестно'),
      );
      return SessionEntry(
        exerciseId: ex.id!,
        completed: false,
        comment: null,
        weight: a.defaultWeight ?? ex.weight,
        reps: a.defaultReps ?? ex.reps,
        sets: a.defaultSets ?? ex.sets,
      );
    }).toList();
    _isRestDay = _entries.isEmpty;
    setState(() {});
  }

  Future<void> _saveDraft() async {
    if (_isEditing) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode({
      'isRest': _isRestDay,
      'restComment': _restController.text,
      'entries': _entries.map((e) => {
            'exerciseId': e.exerciseId,
            'completed': e.completed,
            'comment': e.comment,
            'weight': e.weight,
            'reps': e.reps,
            'sets': e.sets,
          }).toList(),
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _restController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final exercises = ref.read(exerciseListProvider);
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (_, __) => const Divider(),
          itemCount: exercises.length + 1,
          itemBuilder: (c, i) {
            if (i < exercises.length) {
              final e = exercises[i];
              return ListTile(
                title: Text(e.name),
                onTap: () => Navigator.pop(c, e.id),
              );
            }
            return ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Новое упражнение'),
              onTap: () => Navigator.pop(c, -1),
            );
          },
        ),
      ),
    );
    if (selected == null) return;
    if (selected == -1) {
      await Navigator.pushNamed(context, Routes.exerciseForm);
      await ref.read(exerciseListProvider.notifier).load();
      return _addExercise();
    }
    final ex = exercises.firstWhere((e) => e.id == selected);
    setState(() {
      _entries.add(SessionEntry(
        exerciseId: ex.id!,
        completed: false,
        comment: null,
        weight: ex.weight,
        reps: ex.reps,
        sets: ex.sets,
      ));
      _isRestDay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Редактировать тренировку' : 'Новая тренировка'),
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addExercise)],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: _isRestDay
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('День отдыха', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _restController,
                      decoration: const InputDecoration(labelText: 'Комментарий к дню отдыха'),
                      maxLines: 5,
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (ctx, i) {
                    final e = _entries[i];
                    final ex = ref
                        .read(exerciseListProvider)
                        .firstWhere(
                          (x) => x.id == e.exerciseId,
                          orElse: () => Exercise(id: e.exerciseId, name: 'Неизвестно'),
                        );
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Checkbox(
                                value: e.completed,
                                onChanged: (v) => setState(() => e.completed = v ?? false),
                              ),
                              Text(ex.name),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                onPressed: () => setState(() {
                                  _entries.removeAt(i);
                                  if (_entries.isEmpty) _isRestDay = true;
                                }),
                              ),
                            ]),
                            Row(children: [
                              const Text('Вес:'),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => setState(() => e.weight = (e.weight ?? 0) - 0.5),
                              ),
                              Text('${e.weight ?? 0}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => e.weight = (e.weight ?? 0) + 0.5),
                              ),
                            ]),
                            Row(children: [
                              const Text('Повторы:'),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => setState(() => e.reps = (e.reps ?? 0) - 1),
                              ),
                              Text('${e.reps ?? 0}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => e.reps = (e.reps ?? 0) + 1),
                              ),
                            ]),
                            Row(children: [
                              const Text('Подходы:'),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => setState(() => e.sets = (e.sets ?? 0) - 1),
                              ),
                              Text('${e.sets ?? 0}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => e.sets = (e.sets ?? 0) + 1),
                              ),
                            ]),
                            TextField(
                              controller: TextEditingController(text: e.comment),
                              decoration: const InputDecoration(labelText: 'Комментарий'),
                              onChanged: (v) => e.comment = v,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.check),
          label: const Text('Сохранить'),
          onPressed: () async {
            final repo = ref.read(sessionRepoProvider);
            if (_isEditing && _editingSession != null) {
              await repo.update(WorkoutSession(
                id: _editingSession!.id,
                date: _editingSession!.date,
                comment: _isRestDay ? _restController.text : null,
                entries: _entries,
              ));
            } else {
              await repo.create(WorkoutSession(
                date: DateTime.now(),
                comment: _isRestDay ? _restController.text : null,
                entries: _entries,
              ));
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
