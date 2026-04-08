// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:voice_2_note_ai/models/note_model.dart';

/// PDF export service.
class PdfService {
  /// Önizleme/yazdırma için ham PDF baytları.
  Future<Uint8List> buildNotePdfBytes(NoteModel note) async {
    final notoSansData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final notoSansFont = pw.Font.ttf(notoSansData.buffer.asByteData());

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final createdAt =
              DateTime.fromMillisecondsSinceEpoch(note.createdAt * 1000);
          final dateStr = '${createdAt.day}.${createdAt.month}.${createdAt.year}';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Voice2 Note AI',
                style: pw.TextStyle(font: notoSansFont, fontSize: 20),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Not ID: ${note.id ?? '-'}', style: pw.TextStyle(font: notoSansFont)),
              pw.Text('Oluşturulma: $dateStr', style: pw.TextStyle(font: notoSansFont)),
              pw.SizedBox(height: 18),
              pw.Text(
                'Özet',
                style: pw.TextStyle(font: notoSansFont, fontSize: 14),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                note.summary.trim().isEmpty ? '-' : note.summary,
                style: pw.TextStyle(font: notoSansFont),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                'Transkript',
                style: pw.TextStyle(font: notoSansFont, fontSize: 14),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                note.transcript.trim().isEmpty ? '-' : note.transcript,
                style: pw.TextStyle(font: notoSansFont),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<File> generateNotePdfFile(NoteModel note) async {
    final bytes = await buildNotePdfBytes(note);

    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(dir.path, 'pdf'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'note_${note.id ?? ts}.pdf';
    final file = File(p.join(pdfDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);

    // Ek olarak kullanıcının Dosyalar uygulamasında görünen bir klasöre de kaydedelim:
    // Download/Voice2 Note AI/PDF/
    try {
      final mediaStore = MediaStore();
      final saveInfo = await mediaStore.saveFile(
        tempFilePath: file.path,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: p.posix.join('Voice2 Note AI', 'PDF'),
      );

      final uri = saveInfo?.uri;
      if (uri != null) {
        final savedPath = await mediaStore.getFilePathFromUri(
          uriString: uri.toString(),
        );
        if (savedPath != null && savedPath.isNotEmpty) {
          if (kDebugMode) debugPrint('PdfService: saved external to: $savedPath');
          return File(savedPath);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('PdfService: external save failed: $e');
    }

    // Dış kaydetme başarısızsa en azından dahili dosyayı dönelim.
    return file;
  }
}
