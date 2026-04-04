import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/features/notes/note_detail_screen.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/features/recording/recording_screen.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/notes_backup_service.dart';

/// Not listesi ekranı. DB'den notları çeker; boşsa boş durum; arama transkript/özet içinde.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NoteModel> _filter(List<NoteModel> notes) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return notes;
    return notes.where((n) {
      return n.transcript.toLowerCase().contains(q) ||
          n.summary.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    final rootContext = context;
    showAboutDialog(
      context: rootContext,
      applicationName: 'Voice2 Note AI',
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationLegalese: 'Çevrimdışı ses notları',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Ses kaydı, Whisper transkript ve özet bu cihazda çalışır; '
            'internet zorunlu değildir.',
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(rootContext).pop();
              showLicensePage(
                context: rootContext,
                applicationName: 'Voice2 Note AI',
                applicationVersion: '${info.version}+${info.buildNumber}',
              );
            },
            child: const Text('Lisanslar'),
          ),
        ),
      ],
    );
  }

  Future<void> _exportAllNotes(BuildContext context) async {
    try {
      final notes = await ref.read(noteRepositoryProvider).getAll();
      final file = await NotesBackupService.writeJsonExport(notes);
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Voice2 Note AI not yedeği',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dışa aktarılamadı: $e')),
      );
    }
  }

  PreferredSizeWidget _notesAppBar(
    BuildContext context, {
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: const Text('Notlar'),
      bottom: bottom,
      actions: [
        IconButton(
          tooltip: 'Tüm notları JSON olarak dışa aktar',
          icon: const Icon(Icons.save_alt_rounded),
          onPressed: () => _exportAllNotes(context),
        ),
        const ThemeModeMenuButton(),
        IconButton(
          tooltip: 'Hakkında',
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () => _showAbout(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesListProvider);

    return notesAsync.when(
      loading: () => Scaffold(
        appBar: _notesAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: _notesAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Yüklenemedi: $err', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return Scaffold(
            appBar: _notesAppBar(context),
            floatingActionButton: FloatingActionButton.extended(
              tooltip: 'Yeni ses kaydı',
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
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mic_none_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz not yok',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sesli not için alttaki Kayıt düğmesine dokunun veya aşağıdan kayda başlayın.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Tooltip(
                      message: 'Ses kaydı ekranına git',
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const RecordingScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Ses kaydı'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final filtered = _filter(notes);

        return Scaffold(
          appBar: _notesAppBar(
            context,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Semantics(
                  label: 'Transkript veya özette ara',
                  textField: true,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Transkript veya özette ara',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              tooltip: 'Aramayı temizle',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            tooltip: 'Yeni ses kaydı',
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
          body: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Bu aramaya uygun not yok.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(notesListProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final note = filtered[index];
                      return _NoteListTile(note: note);
                    },
                  ),
                ),
        );
      },
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
        tooltip: 'Not seçenekleri',
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
            final backup = note;

            await ref.read(noteRepositoryProvider).delete(id);

            if (!context.mounted) return;
            ref.invalidate(notesListProvider);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Not silindi'),
                action: SnackBarAction(
                  label: 'Geri al',
                  onPressed: () async {
                    await ref.read(noteRepositoryProvider).insert(
                          NoteModel(
                            id: null,
                            audioPath: backup.audioPath,
                            transcript: backup.transcript,
                            summary: backup.summary,
                            duration: backup.duration,
                            createdAt: backup.createdAt,
                          ),
                        );
                    ref.invalidate(notesListProvider);
                  },
                ),
              ),
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
