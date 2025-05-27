class SessionEntry {
  final String id;
  final int exerciseId;
  bool completed;
  String? comment;
  double? weight;
  int? reps;
  int? sets;

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
      completed: map['completed'] is int
          ? (map['completed'] as int) == 1
          : map['completed'] as bool,
      comment: map['comment'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      reps: map['reps'] as int?,
      sets: map['sets'] as int?,
    );
  }

  /// Для Firestore
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

  /// Для SQLite — ключи snake_case под вашу схему
  Map<String, dynamic> toDbMap(int sessionId) {
    return {
      'exercise_id': exerciseId,
      'completed': completed ? 1 : 0,
      'comment': comment,
      'weight': weight,
      'reps': reps,
      'sets': sets,
      'session_id': sessionId,
    };
  }
}
