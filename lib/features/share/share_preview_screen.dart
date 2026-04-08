import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voice_2_note_ai/app/app_icons.dart';
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
        title: const Text('Paylaşım'),
        actions: const [
          ThemeModeMenuButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => shareService.shareSummary(note.summary),
                    icon: const Icon(AppIcons.share),
                    label: const Text('Özeti paylaş'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        shareService.shareTranscript(note.transcript),
                    icon: const Icon(AppIcons.share),
                    label: const Text('Transkripti paylaş'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final pdfService = PdfService();
                        final file = await pdfService.generateNotePdfFile(note);
                        if (!context.mounted) return;

                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'Voice2 Note AI',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: cs.error,
                            content: Text(
                              'PDF paylaşılamadı. Tekrar deneyin.',
                              style: TextStyle(color: cs.onError),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(AppIcons.pdf),
                    label: const Text('PDF paylaş'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
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
          ],
        ),
      ),
    );
  }
}
