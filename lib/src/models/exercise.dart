class Exercise {
  int? id;
  String name;
  double? weight;
  int? reps;
  int? sets;
  String? notes;

  Exercise({this.id, required this.name, this.weight, this.reps, this.sets, this.notes});

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as int?,
        name: map['name'] as String,
        weight: map['weight'] != null ? map['weight'] as double : null,
        reps: map['reps'] as int?,
        sets: map['sets'] as int?,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'weight': weight,
        'reps': reps,
        'sets': sets,
        'notes': notes,
      };
}