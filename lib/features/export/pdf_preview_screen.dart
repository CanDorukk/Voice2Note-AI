import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:voice_2_note_ai/app/app_icons.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/pdf_service.dart';
import 'package:voice_2_note_ai/widgets/note_preview_section_card.dart';

/// PDF önizleme ve dosyaya kaydetme.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    final pdfService = PdfService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF önizleme'),
        actions: const [
          ThemeModeMenuButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                children: [
                  NotePreviewSectionCard(
                    title: 'Özet',
                    icon: AppIcons.summarySection,
                    child: Text(
                      note.summary.trim().isEmpty
                          ? 'Özet henüz yok.'
                          : note.summary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  NotePreviewSectionCard(
                    title: 'Transkript',
                    icon: AppIcons.transcriptSection,
                    child: Text(
                      note.transcript.trim().isEmpty
                          ? 'Konuşma metni henüz yok.'
                          : note.transcript,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              elevation: 3,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await Printing.layoutPdf(
                          onLayout: (_) => pdfService.buildNotePdfBytes(note),
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Önizle ve yazdır'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () async {
                        final scaffold = ScaffoldMessenger.of(context);
                        scaffold.clearSnackBars();

                        final file = await pdfService.generateNotePdfFile(note);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(
                              'PDF kaydedildi: ${file.path.split('/').last}\n${file.path}',
                            ),
                            duration: const Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(AppIcons.pdf),
                      label: const Text('PDF dosyası oluştur'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
