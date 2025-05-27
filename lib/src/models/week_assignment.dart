class WeekAssignment {
  int id;
  int weekPlanId;
  int exerciseId;
  int dayOfWeek;
  double? defaultWeight;
  int? defaultReps;
  int? defaultSets;

  WeekAssignment({
    required this.id,
    required this.weekPlanId,
    required this.exerciseId,
    required this.dayOfWeek,
    this.defaultWeight,
    this.defaultReps,
    this.defaultSets,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'weekPlanId': weekPlanId,
        'exerciseId': exerciseId,
        'dayOfWeek': dayOfWeek,
        'defaultWeight': defaultWeight,
        'defaultReps': defaultReps,
        'defaultSets': defaultSets,
      };

  factory WeekAssignment.fromMap(Map<String, dynamic> m) =>
      WeekAssignment(
        id: m['id'] as int,
        weekPlanId: m['weekPlanId'] as int,
        exerciseId: m['exerciseId'] as int,
        dayOfWeek: m['dayOfWeek'] as int,
        defaultWeight: (m['defaultWeight'] as num?)?.toDouble(),
        defaultReps: m['defaultReps'] as int?,
        defaultSets: m['defaultSets'] as int?,
      );
}
