import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // ---------------- version 1 tables ----------------
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        weight REAL,
        reps INTEGER,
        sets INTEGER,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        comment TEXT,
        weight REAL,
        reps INTEGER,
        sets INTEGER,
        FOREIGN KEY(session_id) REFERENCES sessions(id),
        FOREIGN KEY(exercise_id) REFERENCES exercises(id)
      )
    ''');
    // ---------------- version 2 tables ----------------
    await db.execute('''
      CREATE TABLE assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        day INTEGER NOT NULL
      )
    ''');
    // ---------------- version 3 migration --------------
    await db.execute('''
      ALTER TABLE sessions ADD COLUMN comment TEXT
    ''');
    // ---------------- version 4 tables ----------------
    await db.execute('''
      CREATE TABLE week_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startDate INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE week_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weekPlanId INTEGER NOT NULL,
        exerciseId INTEGER NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        defaultWeight REAL,
        defaultReps INTEGER,
        defaultSets INTEGER,
        FOREIGN KEY(weekPlanId) REFERENCES week_plans(id),
        FOREIGN KEY(exerciseId) REFERENCES exercises(id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_id INTEGER NOT NULL,
          day INTEGER NOT NULL
        )
      ''');
    }
    if (oldV < 3) {
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN comment TEXT
      ''');
    }
    if (oldV < 4) {
      await db.execute('''
        CREATE TABLE week_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          startDate INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE week_assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weekPlanId INTEGER NOT NULL,
          exerciseId INTEGER NOT NULL,
          dayOfWeek INTEGER NOT NULL,
          defaultWeight REAL,
          defaultReps INTEGER,
          defaultSets INTEGER,
          FOREIGN KEY(weekPlanId) REFERENCES week_plans(id),
          FOREIGN KEY(exerciseId) REFERENCES exercises(id)
        )
      ''');
    }
  }
}
