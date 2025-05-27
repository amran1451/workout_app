// lib/src/local/db_service.dart

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
    return await openDatabase(
      path,
      version: 2,                       // bumped from 1 → 2
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // версия 2 сразу с нужными колонками
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
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sessions ADD COLUMN cloud_id TEXT;');
      await db.execute(
        'ALTER TABLE sessions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0;'
      );
    }
  }
}
