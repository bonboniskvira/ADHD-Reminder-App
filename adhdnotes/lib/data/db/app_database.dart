import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'adhdnotes.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    final created = await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            raw_transcript TEXT NOT NULL,
            formatted_note_md TEXT NOT NULL,
            created_at TEXT NOT NULL,
            event_title TEXT NULL,
            event_date TEXT NULL,
            event_created INTEGER NOT NULL
          )
        ''');
      },
    );

    _db = created;
    return created;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) {
      await db.close();
    }
  }
}

