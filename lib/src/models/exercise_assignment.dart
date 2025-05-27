class ExerciseAssignment {
  final int? id;
  int exerciseId;
  int dayOfWeek; // 1–7

  ExerciseAssignment({this.id, required this.exerciseId, required this.dayOfWeek});

  factory ExerciseAssignment.fromMap(Map<String, dynamic> map) => ExerciseAssignment(
        id: map['id'] as int?,
        exerciseId: map['exercise_id'] as int,
        dayOfWeek: map['day'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_id': exerciseId,
        'day': dayOfWeek,
      };
}