// lib/src/models/exercise.dart

class Exercise {
  int? id;
  String name;
  double? weight;
  int? reps;
  int? sets;
  String? notes;

  Exercise({
    this.id,
    required this.name,
    this.weight,
    this.reps,
    this.sets,
    this.notes,
  });

  factory Exercise.fromMap(Map<String, dynamic> m) {
    return Exercise(
      id: m['id'] as int?,
      name: m['name'] as String,
      weight: (m['weight'] as num?)?.toDouble(),
      reps: m['reps'] as int?,
      sets: m['sets'] as int?,
      notes: m['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    // for Firestore
    return {
      'name': name,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (sets != null) 'sets': sets,
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toDbMap() {
    // for SQLite; id omitted (AUTOINCREMENT)
    return {
      'name': name,
      'weight': weight,
      'reps': reps,
      'sets': sets,
      'notes': notes,
    };
  }
}
