/// Модель одной записи в сессии
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

  /// Для отправки в Firestore (убираем поле `id`, оно будет взято из doc.id)
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

  /// Для локальной БД SQflite: добавляем session_id
  Map<String, dynamic> toDbMap(int sessionId) {
    final m = toMap();
    m['session_id'] = sessionId;
    return m;
  }
}
