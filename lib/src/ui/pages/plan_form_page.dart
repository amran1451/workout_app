import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/week_assignment.dart';
import '../../models/exercise.dart';
import '../../providers/week_providers.dart';
import '../../providers/exercise_provider.dart';
import '../../utils/id_utils.dart';

class PlanFormPage extends ConsumerStatefulWidget {
  const PlanFormPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends ConsumerState<PlanFormPage> {
  late DateTime _monday;
  List<WeekAssignment>? _editable;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _monday = ref.read(currentWeekStartProvider);
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _loading = true);
    ref.read(currentWeekStartProvider.notifier).state = _monday;
    final plan = await ref.read(weekPlanRepoProvider).getOrCreateForDate(_monday);
    final planId = toIntId(plan.id);
    final assignments =
        await ref.read(weekAssignmentRepoProvider).getByWeekPlan(planId);
    setState(() {
      _editable = assignments.toList();
      _loading = false;
    });
  }

  void _changeWeek(int weeks) {
    _monday = _monday.add(Duration(days: 7 * weeks));
    _loadAssignments();
  }

  Future<void> _addAssignment(int day) async {
    final exercises = ref.read(exerciseListProvider);
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (_, __) => const Divider(),
          itemCount: exercises.length,
          itemBuilder: (c, i) {
            final e = exercises[i];
            return ListTile(
              title: Text(e.name),
              onTap: () => Navigator.pop(c, e.id),
            );
          },
        ),
      ),
    );
    if (selected == null) return;
    final ex = exercises.firstWhere((e) => e.id == selected);
    setState(() {
      _editable!.add(WeekAssignment(
        id: 0,
        weekPlanId: 0,
        exerciseId: ex.id!,
        dayOfWeek: day,
        defaultWeight: ex.weight,
        defaultReps: ex.reps,
        defaultSets: ex.sets,
      ));
    });
  }

  Future<void> _savePlan() async {
    final plan = await ref.read(weekPlanRepoProvider).getOrCreateForDate(_monday);
    final planId = toIntId(plan.id);
    await ref
        .read(weekAssignmentRepoProvider)
        .saveForWeekPlan(planId, _editable!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'План за ${DateFormat('dd.MM.yyyy').format(_monday)} – '
          '${DateFormat('dd.MM.yyyy').format(_monday.add(Duration(days: 6)))} сохранён',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseListProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('План на неделю')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('План тренировки'),
            Text(
              '${DateFormat('dd.MM.yyyy').format(_monday)} – '
              '${DateFormat('dd.MM.yyyy').format(_monday.add(Duration(days: 6)))}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _changeWeek(-1)),
          IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => _changeWeek(1)),
          IconButton(icon: const Icon(Icons.save), onPressed: _savePlan),
        ],
      ),
      body: ListView.builder(
        itemCount: 7,
        itemBuilder: (ctx, i) {
          final day = i + 1;
          final date = _monday.add(Duration(days: i));
          final entries = _editable!.where((a) => a.dayOfWeek == day).toList();
          return ExpansionTile(
            title: Text(
              '${DateFormat('EEEE', 'ru').format(date)}, ${DateFormat('dd.MM').format(date)}',
            ),
            children: [
              ...entries.map((a) {
                final ex = exercises.firstWhere(
                  (e) => e.id == a.exerciseId,
                  orElse: () => Exercise(id: a.exerciseId, name: 'Неизвестно'),
                );
                return ListTile(
                  title: Text(ex.name),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: a.defaultWeight?.toString() ?? '',
                          decoration: const InputDecoration(labelText: 'Вес'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => a.defaultWeight = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: a.defaultReps?.toString() ?? '',
                          decoration: const InputDecoration(labelText: 'Повт'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => a.defaultReps = int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: a.defaultSets?.toString() ?? '',
                          decoration: const InputDecoration(labelText: 'Под'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => a.defaultSets = int.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => setState(() => _editable!.remove(a)),
                  ),
                );
              }),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Добавить упражнение'),
                onTap: () => _addAssignment(day),
              ),
            ],
          );
        },
      ),
    );
  }
}
