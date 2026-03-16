import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// Not listesi ekranı. DB'den notları çeker; boşsa boş durum gösterir.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar'),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Yüklenemedi: $err', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_none_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz not yok',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kayıt ekranı eklenecek.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(notesListProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _NoteListTile(note: note);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NoteListTile extends StatelessWidget {
  const _NoteListTile({required this.note});

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(note.createdAt * 1000);
    final dateStr = '${date.day}.${date.month}.${date.year}';
    final title = note.summary.trim().isEmpty
        ? (note.transcript.length > 40 ? '${note.transcript.substring(0, 40)}...' : note.transcript)
        : (note.summary.length > 40 ? '${note.summary.substring(0, 40)}...' : note.summary);

    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.note_outlined),
      ),
      title: Text(title.isEmpty ? 'Not ${note.id}' : title),
      subtitle: Text(dateStr),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Detay ekranı sonraki adımda eklenecek.
      },
    );
  }
}
