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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // -- упражнения, сессии и записи (v1–v3) не трогаем, оставляем как есть
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

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        comment TEXT,
        cloud_id TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      );
    ''');

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

    // -- НОВАЯ СХЕМА v4 для множества планов на неделю:
    await db.execute('''
      CREATE TABLE week_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startDate INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE week_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weekPlanId INTEGER NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        exerciseId INTEGER NOT NULL,
        defaultWeight REAL,
        defaultReps INTEGER,
        defaultSets INTEGER,
        FOREIGN KEY(weekPlanId) REFERENCES week_plans(id)
      );
    ''');
  }

  Future _upgradeDB(Database db, int oldV, int newV) async {
    // Если у вас уже есть старые БД и вы не хотите удалять приложение,
    // вам нужно правильно мигрировать. Здесь кратко:
    if (oldV < 4) {
      await db.execute('''
        CREATE TABLE week_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          startDate INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE week_assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weekPlanId INTEGER NOT NULL,
          dayOfWeek INTEGER NOT NULL,
          exerciseId INTEGER NOT NULL,
          defaultWeight REAL,
          defaultReps INTEGER,
          defaultSets INTEGER,
          FOREIGN KEY(weekPlanId) REFERENCES week_plans(id)
        );
      ''');
    }
  }
}
