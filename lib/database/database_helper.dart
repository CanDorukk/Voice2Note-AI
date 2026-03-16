import 'package:voice_2_note_ai/models/note_model.dart';

/// SQLite altyapısı için yardımcı sınıf.
///
/// Bu commit'te sadece şema ve iskelet var.
/// Bir sonraki adımda `sqflite` ile gerçek DB açma/oluşturma eklenecek.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbName = 'voice2note.db';
  static const int dbVersion = 1;

  /// `notes` tablosu şeması (`cursor/database_schema.md` ile uyumlu).
  static String get createNotesTableSql {
    return '''
CREATE TABLE ${NoteModel.tableName} (
  ${NoteModel.colId} INTEGER PRIMARY KEY,
  ${NoteModel.colAudioPath} TEXT,
  ${NoteModel.colTranscript} TEXT,
  ${NoteModel.colSummary} TEXT,
  ${NoteModel.colDuration} INTEGER,
  ${NoteModel.colCreatedAt} INTEGER
)
''';
  }

  /// DB'yi açma/oluşturma (sqflite ile eklenecek).
  Future<void> init() async {
    // TODO: openDatabase + onCreate(createNotesTableSql)
  }
}
