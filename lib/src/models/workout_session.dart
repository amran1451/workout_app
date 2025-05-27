import 'session_entry.dart';

/// Сессия тренировки: дата, комментарий и список записей
class WorkoutSession {
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
      Map<String, dynamic> map, List<SessionEntry> entries) {
    return WorkoutSession(
      id: map['id']?.toString(),
      date: DateTime.parse(map['date'] as String),
      comment: map['comment'] as String?,
      entries: entries,
    );
  }

  /// Общая карта: для Firestore и для SQLite таблицы sessions
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      if (comment != null) 'comment': comment,
    };
  }
}
