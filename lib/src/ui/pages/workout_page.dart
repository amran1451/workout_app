// lib/src/ui/pages/workout_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/session_entry.dart';
import '../../models/workout_session.dart';
import '../../providers/app_providers.dart';
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

    // По умолчанию берем пустой список
    setState(() {});
  }

  Future<void> _saveDraft() async {
    if (_isEditing) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_draftKey, jsonEncode({
      'isRest': _isRest,
      'comment': _restCtrl.text,
      'entries': _entries.map((e) => e.toMap()..['id'] = e.id).toList(),
    }));
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
        return ListView.builder(
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

          // сбросить черновик
          SharedPreferences.getInstance()
              .then((p) => p.remove(_draftKey));

          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
                onPressed: _addEntry, child: const Text('Добавить запись')),
            if (_isRest)
              TextField(
                controller: _restCtrl,
                decoration: const InputDecoration(labelText: 'Комментарий'),
                maxLines: 3,
                onChanged: (_) => _isRest = true,
              ),
            if (!_isRest)
              Expanded(
                child: ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text('Упр. ${_entries[i].exerciseId}'),
                    subtitle: Text(
                        'Вес: ${_entries[i].weight ?? '-'}  Повт: ${_entries[i].reps ?? '-'}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
