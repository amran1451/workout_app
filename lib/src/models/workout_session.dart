class SessionEntry {
  int? id;
  int exerciseId;
  bool completed;
  String? comment;
  double? weight;
  int? reps;
  int? sets;

  SessionEntry({
    this.id,
    required this.exerciseId,
    this.completed = false,
    this.comment,
    this.weight,
    this.reps,
    this.sets,
  });

  factory SessionEntry.fromMap(Map<String, dynamic> map) => SessionEntry(
        id: map['id'] as int?,
        exerciseId: map['exercise_id'] as int,
        completed: map['completed'] == 1,
        comment: map['comment'] as String?,
        weight: map['weight'] != null ? map['weight'] as double : null,
        reps: map['reps'] as int?,
        sets: map['sets'] as int?,
      );

  Map<String, dynamic> toMap(int sessionId) => {
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'completed': completed ? 1 : 0,
        'comment': comment,
        'weight': weight,
        'reps': reps,
        'sets': sets,
      };
}

class WorkoutSession {
  /// В Firestore — это ID документа в коллекции sessions
  final String? id;
  final DateTime date;
  final String? comment;
  final List<SessionEntry> entries;

  WorkoutSession({
    this.id,
    required this.date,
    this.comment,
    required this.entries,
  });

  factory WorkoutSession.fromMap(
    Map<String, dynamic> m,
    List<SessionEntry> entries,
  ) {
    return WorkoutSession(
      id: m['id'] as String?,
      date: DateTime.parse(m['date'] as String),
      comment: m['comment'] as String?,
      entries: entries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'comment': comment,
    };
  }
}
