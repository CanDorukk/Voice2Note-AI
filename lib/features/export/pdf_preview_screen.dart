import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// PDF preview ekranı (UI iskeleti).
///
/// Bu adımda gerçek PDF üretimi yapılmıyor; transcript/summary gösteriliyor.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Önizleme (yakında)'),
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
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Gerçek PDF üretimi bir sonraki adımda eklenecek.',
                ),
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

