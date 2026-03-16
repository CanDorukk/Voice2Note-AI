import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// SQLite altyapısı: DB açma, tablo oluşturma.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbName = 'voice2note.db';
  static const int dbVersion = 1;

  Database? _db;

  Database? get db => _db;

  /// `notes` tablosu şeması (`cursor/database_schema.md` ile uyumlu).
  static String get createNotesTableSql {
    return '''
CREATE TABLE ${NoteModel.tableName} (
  ${NoteModel.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
  ${NoteModel.colAudioPath} TEXT NOT NULL,
  ${NoteModel.colTranscript} TEXT NOT NULL,
  ${NoteModel.colSummary} TEXT NOT NULL,
  ${NoteModel.colDuration} INTEGER NOT NULL,
  ${NoteModel.colCreatedAt} INTEGER NOT NULL
)
''';
  }

  /// DB'yi aç; yoksa oluştur, tabloyu oluştur.
  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, dbName);
    _db = await openDatabase(
      path,
      version: dbVersion,
      onCreate: (db, version) async {
        await db.execute(createNotesTableSql);
      },
    );
  }
}
