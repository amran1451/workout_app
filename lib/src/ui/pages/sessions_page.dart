import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../routes.dart';
import '../../models/workout_session.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../providers/exercise_provider.dart';

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage>
    with WidgetsBindingObserver {
  DateTimeRange? _selectedRange;
  List<WorkoutSession> _filtered = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAndLoad();
    }
  }

  Future<void> _syncAndLoad() async {
    final local = ref.read(sessionRepoProvider);
    final cloud = ref.read(cloudSessionRepoProvider);
    await local.syncPending(cloud);
    final sessions = await local.getAll();
    setState(() => _filtered = sessions);
  }

  Future<void> _filterRange(DateTimeRange range) async {
    final sessions = await ref.read(sessionRepoProvider).getAll();
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    setState(() {
      _selectedRange = range;
      _filtered = sessions.where((s) {
        final d = DateTime(s.date.year, s.date.month, s.date.day);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    });
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _exportText() {
    if (_selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите период')),
      );
      return;
    }

    final start = _selectedRange!.start;
    final end = _selectedRange!.end;
    final dfDate = DateFormat('dd.MM');
    final startStr = dfDate.format(start);
    final endStr = dfDate.format(end);

    final sb = StringBuffer()..writeln('Отчёт за $startStr–$endStr')..writeln();

    final dayNameFmt = DateFormat('EEEE', 'ru');
    final exercises = ref.read(exerciseListProvider);

    for (var date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
      final raw = dayNameFmt.format(date);
      final dayName = raw[0].toUpperCase() + raw.substring(1);
      final session = _filtered.firstWhere(
        (s) => _isSameDate(s.date, date),
        orElse: () => WorkoutSession(date: date, entries: [], comment: null),
      );
      if (session.entries.isEmpty) {
        final note = session.comment != null ? ' (${session.comment})' : '';
        sb.writeln('$dayName: отдых$note\n');
      } else {
        sb.writeln('$dayName:');
        for (var e in session.entries) {
          final exName = exercises
              .firstWhere((ex) => ex.id == e.exerciseId,
                  orElse: () => Exercise(id: e.exerciseId, name: 'Неизвестно'))
              .name;
          final weightStr = e.weight != null ? ' ${e.weight} кг' : '';
          final repsSets = (e.reps != null && e.sets != null) ? ' ${e.reps}×${e.sets}' : '';
          final commentStr = e.comment != null ? ' ${e.comment}' : '';
          sb.writeln('- $exName$weightStr$repsSets$commentStr');
        }
        sb.writeln();
      }
    }

    final exportText = sb.toString().trimRight();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Отчёт за $startStr–$endStr'),
        content: SingleChildScrollView(child: Text(exportText)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportText));
              Navigator.pop(context);
            },
            child: const Text('Скопировать'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои тренировки')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedRange,
                      locale: const Locale('ru'),
                    );
                    if (range != null) await _filterRange(range);
                  },
                  child: const Text('Выбрать период'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _exportText,
                  child: const Text('Экспорт'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('Нет тренировок за выбранный период'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final s = _filtered[i];
                      final dateStr = DateFormat('yyyy-MM-dd').format(s.date);
                      final subtitle = s.entries.isEmpty
                          ? (s.comment != null ? 'Отдых (${s.comment})' : 'Отдых')
                          : '${s.entries.length} упражнений';
                      return ListTile(
                        title: Text('Тренировка: $dateStr'),
                        subtitle: Text(subtitle),
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            Routes.workout,
                            arguments: s,
                          );
                          await _syncAndLoad();
                          if (_selectedRange != null) await _filterRange(_selectedRange!);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                          onPressed: () async {
                            await ref
                                .read(sessionRepoProvider)
                                .deleteSession(int.parse(s.id!));
                            await _syncAndLoad();
                            if (_selectedRange != null) await _filterRange(_selectedRange!);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
