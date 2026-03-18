import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// Share (paylaşım) ekranı (UI iskeleti).
///
/// Bu adımda gerçek paylaşım (share_plus / PDF) henüz yok.
class SharePreviewScreen extends StatelessWidget {
  const SharePreviewScreen({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşım (yakında)'),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transcript paylasim yakinda')),
                    );
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text("Transcript paylas"),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ozet paylasim yakinda')),
                    );
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text("Ozet paylas"),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF paylasim yakinda')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text("PDF paylas"),
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

