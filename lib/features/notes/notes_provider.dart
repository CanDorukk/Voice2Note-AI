import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/database/database_helper.dart';
import 'package:voice_2_note_ai/database/note_repository.dart';
import 'package:voice_2_note_ai/database/sqlite_note_repository.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return SqliteNoteRepository(DatabaseHelper.instance);
});

/// Not listesi; DB'den en yeniden eskiye sıralı.
final notesListProvider = FutureProvider<List<NoteModel>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getAll();
});
