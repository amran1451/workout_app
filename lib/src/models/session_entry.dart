// lib/src/models/session_entry.dart
class SessionEntry {
  /// В Firestore — это ID документа в саб-коллекции entries
  final String id;
  final int exerciseId;
  final bool completed;
  final String? comment;
  final double? weight;
  final int? reps;
  final int? sets;

  SessionEntry({
    required this.id,
    required this.exerciseId,
    this.completed = false,
    this.comment,
    this.weight,
    this.reps,
    this.sets,
  });

  factory SessionEntry.fromMap(Map<String, dynamic> map) {
    return SessionEntry(
      id: map['id'].toString(),
      exerciseId: map['exerciseId'] as int,
      completed: map['completed'] as bool,
      comment: map['comment'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      reps: map['reps'] as int?,
      sets: map['sets'] as int?,
    );
  }

  /// Карту для отправки в Firestore
  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'completed': completed,
      if (comment != null) 'comment': comment,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (sets != null) 'sets': sets,
    };
  }

  /// Карту для локальной SQLite (с добавлением session_id)
  Map<String, dynamic> toDbMap(int sessionId) {
    final map = toMap();
    map['session_id'] = sessionId;
    return map;
  }
}


// lib/src/data/cloud_session_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_session.dart' show WorkoutSession;
import '../models/session_entry.dart';
import 'i_session_repository.dart';

/// Облачный (Firestore) репозиторий тренировочных сессий
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
    final old = await docRef.collection('entries').get();
    for (var d in old.docs) await d.reference.delete();
    for (var e in s.entries) {
      await docRef.collection('entries').add(e.toMap());
    }
  }

  @override
  Future<List<WorkoutSession>> getAll() async {
    final snaps = await _col.orderBy('date', descending: true).get();
    final out = <WorkoutSession>[];
    for (var doc in snaps.docs) {
      final m = doc.data();
      final date = DateTime.parse(m['date'] as String);
      final comment = m['comment'] as String?;
      final entriesSnap = await doc.reference.collection('entries').get();
      final entries = entriesSnap.docs
          .map((ed) => SessionEntry.fromMap({'id': ed.id, ...ed.data()}))
          .toList();
      out.add(WorkoutSession(
        id: doc.id,
        date: date,
        comment: comment,
        entries: entries.cast<SessionEntry>(),
      ));
    }
    return out;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final docRef = _col.doc(sessionId);
    final entriesSnap = await docRef.collection('entries').get();
    for (var d in entriesSnap.docs) await d.reference.delete();
    await docRef.delete();
  }
}
