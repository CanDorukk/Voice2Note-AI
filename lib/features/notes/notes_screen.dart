import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/features/notes/note_detail_screen.dart';
import 'package:voice_2_note_ai/features/recording/recording_screen.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const RecordingScreen(),
            ),
          );
        },
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Kayıt'),
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

class _NoteListTile extends ConsumerWidget {
  const _NoteListTile({required this.note});

  final NoteModel note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'delete') {
            final id = note.id;
            if (id == null) return;

            final confirm = await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Sil?'),
                  content: const Text('Bu notu silmek istediğine emin misin?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Sil'),
                    ),
                  ],
                );
              },
            );

            if (confirm != true) return;

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Siliniyor...')),
            );

            await ref.read(noteRepositoryProvider).delete(id);

            if (!context.mounted) return;
            ref.invalidate(notesListProvider);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Silindi')),
            );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded),
                SizedBox(width: 8),
                Text('Sil'),
              ],
            ),
          ),
        ],
        child: const Icon(Icons.more_vert_rounded),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => NoteDetailScreen(note: note),
          ),
        );
      },
    );
  }
}
