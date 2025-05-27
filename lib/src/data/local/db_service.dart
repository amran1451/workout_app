// lib/src/data/local/db_service.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(
      path,
      version: 4,                 // подняли до 4
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1) exercises
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        weight REAL,
        reps INTEGER,
        sets INTEGER,
        notes TEXT,
        cloud_id TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // 2) sessions
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        comment TEXT,
        cloud_id TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // 3) entries
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        comment TEXT,
        weight REAL,
        reps INTEGER,
        sets INTEGER,
        session_id INTEGER NOT NULL,
        FOREIGN KEY(session_id) REFERENCES sessions(id)
      );
    ''');

    // 4) week_plans
    await db.execute('''
      CREATE TABLE week_plans (
        id TEXT PRIMARY KEY,
        startDate INTEGER NOT NULL
      );
    ''');

    // 5) week_assignments
    await db.execute('''
      CREATE TABLE week_assignments (
        id TEXT PRIMARY KEY,
        planId TEXT NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        exerciseId INTEGER NOT NULL,
        defaultWeight REAL,
        defaultReps INTEGER,
        defaultSets INTEGER,
        FOREIGN KEY(planId) REFERENCES week_plans(id)
      );
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // миграция v1→v2: колонки cloud_id, is_synced для sessions
      await db.execute('ALTER TABLE sessions ADD COLUMN cloud_id TEXT;');
      await db.execute(
        'ALTER TABLE sessions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0;'
      );
    }
    if (oldVersion < 3) {
      // миграция v2→v3: таблица exercises
      await db.execute('''
        CREATE TABLE exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          weight REAL,
          reps INTEGER,
          sets INTEGER,
          notes TEXT,
          cloud_id TEXT,
          is_synced INTEGER NOT NULL DEFAULT 0
        );
      ''');
    }
    if (oldVersion < 4) {
      // миграция v3→v4: таблицы week_plans и week_assignments
      await db.execute('''
        CREATE TABLE week_plans (
          id TEXT PRIMARY KEY,
          startDate INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE week_assignments (
          id TEXT PRIMARY KEY,
          planId TEXT NOT NULL,
          dayOfWeek INTEGER NOT NULL,
          exerciseId INTEGER NOT NULL,
          defaultWeight REAL,
          defaultReps INTEGER,
          defaultSets INTEGER,
          FOREIGN KEY(planId) REFERENCES week_plans(id)
        );
      ''');
    }
  }
}
