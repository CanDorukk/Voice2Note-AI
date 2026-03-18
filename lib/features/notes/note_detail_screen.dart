import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// Tek bir notun detay ekranı (UI iskeleti).
///
/// Şimdilik amaç:
/// - transcript ve summary'ı göstermek
/// - Ses/Paylaş/PDF gibi butonları UI olarak hazırlamak
/// - Oynatma / PDF / paylaşım fonksiyonelliği sonraki adımda eklenecek
class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(note.createdAt * 1000);
    final dateStr = '${createdAt.day}.${createdAt.month}.${createdAt.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Not ${note.id ?? ''}'.trim()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Oluşturulma: $dateStr',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
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
                  onPressed: null, // UI-only (fonksiyon bir sonraki adımda)
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Oynat'),
                ),
                OutlinedButton.icon(
                  onPressed: null, // UI-only
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: null, // UI-only
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Paylaş'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Audio: ${note.audioPath}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
