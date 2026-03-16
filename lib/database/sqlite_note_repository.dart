import 'package:voice_2_note_ai/database/database_helper.dart';
import 'package:voice_2_note_ai/database/note_repository.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// SQLite ile NoteRepository implementasyonu.
class SqliteNoteRepository implements NoteRepository {
  SqliteNoteRepository(this._helper);

  final DatabaseHelper _helper;

  @override
  Future<int> insert(NoteModel note) async {
    final db = _helper.db;
    if (db == null) return 0;
    final map = note.toMap();
    map.remove(NoteModel.colId);
    return db.insert(NoteModel.tableName, map);
  }

  @override
  Future<List<NoteModel>> getAll() async {
    final db = _helper.db;
    if (db == null) return [];
    final list = await db.query(NoteModel.tableName, orderBy: '${NoteModel.colCreatedAt} DESC');
    return list.map((m) => NoteModel.fromMap(m)).toList();
  }

  @override
  Future<NoteModel?> getById(int id) async {
    final db = _helper.db;
    if (db == null) return null;
    final list = await db.query(
      NoteModel.tableName,
      where: '${NoteModel.colId} = ?',
      whereArgs: [id],
    );
    if (list.isEmpty) return null;
    return NoteModel.fromMap(list.first);
  }

  @override
  Future<int> delete(int id) async {
    final db = _helper.db;
    if (db == null) return 0;
    return db.delete(
      NoteModel.tableName,
      where: '${NoteModel.colId} = ?',
      whereArgs: [id],
    );
  }
}
