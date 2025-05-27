class WeekPlan {
  /// В Firestore используем ISO-строку понедельника как ID
  final String id;
  final DateTime startDate;

  WeekPlan({
    required this.id,
    required this.startDate,
  });

  factory WeekPlan.fromMap(Map<String, dynamic> map) {
    return WeekPlan(
      id: map['id'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // не включаем id — он уже в ключе документа
      'startDate': startDate.toIso8601String(),
    };
  }
}
