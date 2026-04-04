import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// Tüm notları JSON dosyasına yazar (paylaşım / yedek).
class NotesBackupService {
  NotesBackupService._();

  static Future<File> writeJsonExport(List<NoteModel> notes) async {
    final dir = await getTemporaryDirectory();
    final name = 'voice2note_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$name');
    final list = notes.map((n) => n.toMap()).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(list),
      flush: true,
    );
    return file;
  }
}
