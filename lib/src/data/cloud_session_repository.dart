import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_session.dart';
import '../models/session_entry.dart';
import 'i_session_repository.dart';

/// Firestore-репозиторий тренировочных сессий
class CloudSessionRepository implements ISessionRepository {
  final CollectionReference<Map<String, dynamic>> _col;

  CloudSessionRepository(String uid)
      : _col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions');

  @override
  Future<WorkoutSession> create(WorkoutSession s) async {
    final docRef = await _col.add(s.toMap());
    // сохраняем все записи
    for (var e in s.entries) {
      await docRef.collection('entries').add(e.toMap());
    }
    return WorkoutSession(
      id: docRef.id,
      date: s.date,
      comment: s.comment,
      entries: s.entries,
    );
  }

  @override
  Future<void> update(WorkoutSession s) async {
    final docRef = _col.doc(s.id);
    await docRef.set(s.toMap());
    // удаляем старые записи
    final old = await docRef.collection('entries').get();
    for (var d in old.docs) {
      await d.reference.delete();
    }
    // вставляем новые
    for (var e in s.entries) {
      await docRef.collection('entries').add(e.toMap());
    }
  }

  @override
  Future<List<WorkoutSession>> getAll() async {
    final snaps =
        await _col.orderBy('date', descending: true).get(); // по дате
    final out = <WorkoutSession>[];
    for (var doc in snaps.docs) {
      final m = doc.data();
      final entriesSnap = await doc.reference.collection('entries').get();
      final entries = entriesSnap.docs
          .map((ed) => SessionEntry.fromMap({'id': ed.id, ...ed.data()}))
          .toList();
      out.add(WorkoutSession(
        id: doc.id,
        date: DateTime.parse(m['date'] as String),
        comment: m['comment'] as String?,
        entries: entries,
      ));
    }
    return out;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final docRef = _col.doc(sessionId);
    final entriesSnap = await docRef.collection('entries').get();
    for (var d in entriesSnap.docs) {
      await d.reference.delete();
    }
    await docRef.delete();
  }
}
