import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/features/export/pdf_preview_screen.dart';
import 'package:voice_2_note_ai/features/notes/note_detail_screen.dart';
import 'package:voice_2_note_ai/features/notes/notes_screen.dart';
import 'package:voice_2_note_ai/features/recording/recording_screen.dart';
import 'package:voice_2_note_ai/features/share/share_preview_screen.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// Navigator geçişleri tek yerden; ileride go_router ile değiştirilebilir.
class AppNavigation {
  AppNavigation._();

  static Future<void> pushNotesReplace(BuildContext context) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const NotesScreen()),
    );
  }

  static Future<void> pushRecording(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const RecordingScreen()),
    );
  }

  static Future<void> pushNoteDetail(BuildContext context, NoteModel note) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => NoteDetailScreen(note: note)),
    );
  }

  static Future<void> pushPdfPreview(BuildContext context, NoteModel note) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => PdfPreviewScreen(note: note)),
    );
  }

  static Future<void> pushSharePreview(BuildContext context, NoteModel note) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => SharePreviewScreen(note: note)),
    );
  }
}
