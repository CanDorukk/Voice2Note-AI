import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voice_2_note_ai/services/share_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşım'),
        actions: const [
          ThemeModeMenuButton(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Transcript',
              icon: Icons.mic_none_rounded,
              child: Text(
                note.transcript.trim().isEmpty
                    ? 'Transcript henüz hazır değil.'
                    : note.transcript,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Özet',
              icon: Icons.lightbulb_outline_rounded,
              child: Text(
                note.summary.trim().isEmpty ? 'Özet henüz hazır değil.' : note.summary,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
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
                        SnackBar(content: Text('PDF paylaşılamadı: $e')),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

