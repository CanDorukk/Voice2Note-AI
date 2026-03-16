import 'package:voice_2_note_ai/models/note_model.dart';

/// Not kayıtları için repository arayüzü.
///
/// Bu commit'te sadece method imzaları var.
/// DB entegrasyonu (sqflite) sonraki adımda implement edilecek.
abstract class NoteRepository {
  Future<int> insert(NoteModel note);
  Future<List<NoteModel>> getAll();
  Future<NoteModel?> getById(int id);
  Future<int> delete(int id);
}
