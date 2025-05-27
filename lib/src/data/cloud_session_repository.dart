// lib/src/data/cloud_session_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_session.dart';
import '../models/session_entry.dart';

/// Облачный репозиторий тренировочных сессий
class CloudSessionRepository {
  final CollectionReference<Map<String, dynamic>> _col;
  CloudSessionRepository(String uid)
      : _col = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions');

  Future<WorkoutSession> create(WorkoutSession s) async {
    final docRef = await _col.add(s.toMap());
    for (var e in s.entries) {
      await docRef
          .collection('entries')
          .doc(e.id.toString())
          .set(e.toMap());
    }
    return WorkoutSession(
      id: docRef.id,
      date: s.date,
      comment: s.comment,
      entries: s.entries,
    );
  }

  Future<void> update(WorkoutSession s) async {
    final docRef = _col.doc(s.id);
    await docRef.set(s.toMap());
    final old = await docRef.collection('entries').get();
    for (var d in old.docs) await d.reference.delete();
    for (var e in s.entries) {
      await docRef
          .collection('entries')
          .doc(e.id.toString())
          .set(e.toMap());
    }
  }

  Future<void> delete(String id) async {
    final docRef = _col.doc(id);
    final entries = await docRef.collection('entries').get();
    for (var d in entries.docs) await d.reference.delete();
    await docRef.delete();
  }

  Future<List<WorkoutSession>> getAll() async {
    final snaps =
        await _col.orderBy('date', descending: true).get();
    final out = <WorkoutSession>[];
    for (var doc in snaps.docs) {
      final m = doc.data();
      final entSnap = await doc.reference.collection('entries').get();
      final entries = entSnap.docs.map((ed) {
        final d = ed.data();
        return SessionEntry.fromMap({
          'id': ed.id,
          ...d,
        });
      }).toList();
      out.add(WorkoutSession(
        id: doc.id,
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return out;
  }
}
