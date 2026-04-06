import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/pdf_service.dart';
import 'package:voice_2_note_ai/services/share_service.dart';
import 'package:voice_2_note_ai/widgets/note_preview_section_card.dart';

/// Transkript, özet veya PDF paylaşımı.
class SharePreviewScreen extends StatelessWidget {
  const SharePreviewScreen({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    final shareService = ShareService();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşım önizlemesi'),
        actions: const [
          ThemeModeMenuButton(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            NotePreviewSectionCard(
              title: 'Transkript',
              icon: Icons.mic_none_rounded,
              child: Text(
                note.transcript.trim().isEmpty
                    ? 'Transkript henüz hazır değil.'
                    : note.transcript,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            NotePreviewSectionCard(
              title: 'Özet',
              icon: Icons.lightbulb_outline_rounded,
              child: Text(
                note.summary.trim().isEmpty
                    ? 'Özet henüz hazır değil.'
                    : note.summary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => shareService.shareTranscript(note.transcript),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Transkripti paylaş'),
                ),
                OutlinedButton.icon(
                  onPressed: () => shareService.shareSummary(note.summary),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Özeti paylaş'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final pdfService = PdfService();
                      final file = await pdfService.generateNotePdfFile(note);
                      if (!context.mounted) return;

                      await Share.shareXFiles(
                        [XFile(file.path)],
                        text: 'Voice2 Note AI PDF',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: cs.error,
                          content: Text(
                            'PDF paylaşılamadı: $e',
                            style: TextStyle(color: cs.onError),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('PDF paylaş'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
