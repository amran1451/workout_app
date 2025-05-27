// lib/src/ui/pages/workout_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/session_entry.dart';
import '../../models/workout_session.dart';
import '../../models/exercise.dart';
import '../../providers/week_providers.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/session_provider.dart';
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

  Future<void> _initialize() async {
    if (_inited) return;
    _inited = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as WorkoutSession?;
    if (args != null) {
      // Редактируем существующую сессию
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
      // Загружаем черновик
      final m = jsonDecode(prefs.getString(_draftKey)!) as Map<String, dynamic>;
      _isRest = m['isRest'] as bool;
      _restCtrl.text = m['comment'] as String;
      _entries = (m['entries'] as List)
          .cast<Map<String, dynamic>>()
          .map((e) => SessionEntry.fromMap(e))
          .toList();
      setState(() {});
      return;
    }

    // Восстановление из плана на текущую неделю
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekPlan =
        await ref.read(weekPlanRepoProvider).getOrCreateForDate(monday);
    final planId = toIntId(weekPlan.id);
    final assignments =
        await ref.read(weekAssignmentRepoProvider).getByWeekPlan(planId);
    final today = now.weekday;
    final todays = assignments.where((a) => a.dayOfWeek == today).toList();
    final exercises = ref.read(exerciseListProvider);

    _entries = todays.map((a) {
      final ex = exercises.firstWhere(
        (e) => e.id == a.exerciseId,
        orElse: () =>
            Exercise(id: a.exerciseId, name: 'Неизвестно'),
      );
      return SessionEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: ex.id!,
        completed: false,
        weight: a.defaultWeight ?? ex.weight,
        reps: a.defaultReps ?? ex.reps,
        sets: a.defaultSets ?? ex.sets,
        comment: null,
      );
    }).toList();

    _isRest = _entries.isEmpty;
    setState(() {});
  }

  Future<void> _saveDraft() async {
    if (_isEditing) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_draftKey, jsonEncode({
      'isRest': _isRest,
      'comment': _restCtrl.text,
      'entries':
          _entries.map((e) => e.toMap()..['id'] = e.id).toList(),
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _saveDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restCtrl.dispose();
    super.dispose();
  }

  Future<void> _addEntry() async {
    final sel = await showModalBottomSheet<int>(
      context: context,
      builder: (_) {
        final list = ref.read(exerciseListProvider);
        return ListView.separated(
          separatorBuilder: (_, __) => const Divider(),
          itemCount: list.length,
          itemBuilder: (c, i) => ListTile(
            title: Text(list[i].name),
            onTap: () => Navigator.pop(c, list[i].id!),
          ),
        );
      },
    );
    if (sel == null) return;
    setState(() {
      _entries.add(SessionEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: sel,
        completed: false,
      ));
      _isRest = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditing ? 'Редактировать' : 'Новая тренировка')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () async {
          final local = ref.read(sessionRepoProvider);
          final cloud = ref.read(cloudSessionRepoProvider);
          final sess = WorkoutSession(
            id: _editing?.id,
            date: DateTime.now(),
            comment: _isRest ? _restCtrl.text : null,
            entries: _entries,
          );
          if (_isEditing) {
            await local.update(sess);
            await cloud.update(sess);
          } else {
            await local.create(sess);
            await cloud.create(sess);
          }
          SharedPreferences.getInstance().then((p) => p.remove(_draftKey));
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isRest
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _addEntry,
                    child: const Text('Добавить запись'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _restCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Комментарий к отдыху'),
                    maxLines: 3,
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (ctx, i) {
                  final e = _entries[i];
                  final ex = exercises.firstWhere(
                    (x) => x.id == e.exerciseId,
                    orElse: () => Exercise(id: e.exerciseId, name: 'Неизвестно'),
                  );
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
                            Text(ex.name, style: const TextStyle(fontSize: 16)),
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
                              onPressed: () =>
                                  setState(() => e.weight = (e.weight ?? 0) - 0.5),
                            ),
                            Text('${e.weight ?? 0}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  setState(() => e.weight = (e.weight ?? 0) + 0.5),
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
                            controller: TextEditingController(text: e.comment),
                            decoration:
                                const InputDecoration(labelText: 'Комментарий'),
                            onChanged: (v) => e.comment = v,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
