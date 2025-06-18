import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/session_entry.dart';
import '../../models/workout_session.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/week_providers.dart';
import '../../utils/id_utils.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage>
    with WidgetsBindingObserver {
  static const _draftKey = 'workout_draft';
  final _restCtrl = TextEditingController();
  bool _isEditing = false;
  WorkoutSession? _editing;
  List<SessionEntry> _entries = [];
  bool _isRest = true;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_initialize);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _saveDraft();
  }

  Future<void> _initialize() async {
    if (_inited) return;
    _inited = true;

    final args = ModalRoute.of(context)?.settings.arguments as WorkoutSession?;
    if (args != null) {
      _isEditing = true;
      _editing = args;
      _entries = List.from(args.entries);
      _isRest = _entries.isEmpty;
      _restCtrl.text = args.comment ?? '';
      setState(() {});
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_draftKey)) {
      final map = jsonDecode(prefs.getString(_draftKey)!) as Map<String, dynamic>;
      _isRest = map['isRest'] as bool;
      _restCtrl.text = map['comment'] as String;
      _entries = (map['entries'] as List)
          .cast<Map<String, dynamic>>()
          .map(SessionEntry.fromMap)
          .toList();
      setState(() {});
      return;
    }

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekPlan =
        await ref.read(weekPlanRepoProvider).getOrCreateForDate(monday);
    final planId = toIntId(weekPlan.id);
    final assignments =
        await ref.read(weekAssignmentRepoProvider).getByWeekPlan(planId);
    final todays = assignments.where((a) => a.dayOfWeek == now.weekday);
    final exercises = ref.read(exerciseListProvider);

    _entries = [];
    for (final a in todays) {
      final ex = exercises.firstWhere((e) => e.id == a.exerciseId);
      final last = await ref
          .read(sessionRepoProvider)
          .getLastEntryForExercise(ex.id!);
      _entries.add(SessionEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: ex.id!,
        completed: false,
        weight: a.defaultWeight ?? last?.weight ?? ex.weight,
        reps: a.defaultReps ?? last?.reps ?? ex.reps,
        sets: a.defaultSets ?? last?.sets ?? ex.sets,
        comment: null,
      ));
    }

    _isRest = _entries.isEmpty;
    setState(() {});
  }

  Future<void> _saveDraft() async {
    if (_isEditing) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode({
      'isRest': _isRest,
      'comment': _restCtrl.text,
      'entries': _entries.map((e) => e.toMap()..['id'] = e.id).toList(),
    }));
  }

  Future<void> _addEntry() async {
    final sel = await showModalBottomSheet<int>(
      context: context,
      builder: (_) {
        final list = ref.watch(exerciseListProvider);
        return SafeArea(
          child: ListView.separated(
            separatorBuilder: (_, __) => const Divider(),
            itemCount: list.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(list[i].name),
              onTap: () => Navigator.pop(c, list[i].id),
            ),
          ),
        );
      },
    );
    if (sel == null) return;
    final ex = ref.read(exerciseListProvider).firstWhere((e) => e.id == sel);
    final last = await ref
        .read(sessionRepoProvider)
        .getLastEntryForExercise(ex.id!);
    setState(() {
      _entries.add(SessionEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: ex.id!,
        completed: false,
        weight: last?.weight ?? ex.weight,
        reps: last?.reps ?? ex.reps,
        sets: last?.sets ?? ex.sets,
        comment: null,
      ));
      _isRest = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseListProvider);

    return WillPopScope(
      onWillPop: () async {
        await _saveDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(_isEditing ? 'Редактировать тренировку' : 'Новая тренировка'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final local = ref.read(sessionRepoProvider);
            WorkoutSession sess;
            if (_isEditing) {
              sess = WorkoutSession(
                id: _editing!.id,
                date: DateTime.now(),
                comment: _isRest ? _restCtrl.text : null,
                entries: _entries,
              );
              await local.update(sess);
            } else {
              sess = await local.create(WorkoutSession(
                date: DateTime.now(),
                comment: _isRest ? _restCtrl.text : null,
                entries: _entries,
              ));
            }
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final cloud = ref.read(cloudSessionRepoProvider);
              final cloudS = _isEditing
                  ? await cloud.update(sess).then((_) => sess)
                  : await cloud.create(sess);
              await local.markSynced(
                int.parse(sess.id!),
                cloudS.id!,
              );
            }
            await SharedPreferences.getInstance().then((p) => p.remove(_draftKey));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Сохранено')));
            Navigator.pop(context);
          },
          child: const Icon(Icons.check),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _isRest
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить упражнение'),
                      onPressed: _addEntry,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _restCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Комментарий к отдыху'),
                      maxLines: 3,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить упражнение'),
                        onPressed: _addEntry,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (ctx, i) {
                          final e = _entries[i];
                          final ex = exercises.firstWhere((x) => x.id == e.exerciseId);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Checkbox(
                                      value: e.completed,
                                      onChanged: (v) =>
                                          setState(() => e.completed = v ?? false),
                                    ),
                                    Text(ex.name,
                                        style: const TextStyle(fontSize: 16)),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => setState(() {
                                        _entries.removeAt(i);
                                        if (_entries.isEmpty) _isRest = true;
                                      }),
                                    ),
                                  ]),
                                  Row(children: [
                                    const Text('Вес:'),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () => setState(
                                          () => e.weight = (e.weight ?? 0) - 0.5),
                                    ),
                                    Text('${e.weight ?? 0}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => setState(
                                          () => e.weight = (e.weight ?? 0) + 0.5),
                                    ),
                                  ]),
                                  Row(children: [
                                    const Text('Повторы:'),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () =>
                                          setState(() => e.reps = (e.reps ?? 0) - 1),
                                    ),
                                    Text('${e.reps ?? 0}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () =>
                                          setState(() => e.reps = (e.reps ?? 0) + 1),
                                    ),
                                  ]),
                                  Row(children: [
                                    const Text('Подходы:'),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () =>
                                          setState(() => e.sets = (e.sets ?? 0) - 1),
                                    ),
                                    Text('${e.sets ?? 0}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () =>
                                          setState(() => e.sets = (e.sets ?? 0) + 1),
                                    ),
                                  ]),
                                  TextField(
                                    controller:
                                        TextEditingController(text: e.comment),
                                    decoration: const InputDecoration(
                                        labelText: 'Комментарий'),
                                    onChanged: (v) => e.comment = v,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
