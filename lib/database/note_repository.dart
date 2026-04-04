import 'package:voice_2_note_ai/models/note_model.dart';

/// Not kayıtları için repository arayüzü.
abstract class NoteRepository {
  Future<int> insert(NoteModel note);
  Future<List<NoteModel>> getAll();
  Future<NoteModel?> getById(int id);
  Future<int> update(NoteModel note);
  Future<int> delete(int id);
}
