import 'package:adhdnotes/data/db/app_database.dart';
import 'package:adhdnotes/data/models/note.dart';
import 'package:sqflite/sqflite.dart';

class NotesRepository {
  NotesRepository({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<List<Note>> getRecentNotes({int limit = 50}) async {
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Note.fromDbMap).toList(growable: false);
  }

  Future<Note?> getById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromDbMap(rows.first);
  }

  Future<int> insert(Note note) async {
    final db = await _database.database;
    return db.insert(
      'notes',
      note.toDbMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}

