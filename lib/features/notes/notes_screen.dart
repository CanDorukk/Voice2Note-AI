import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:voice_2_note_ai/app/app_navigation.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/features/notes/pending_processing_provider.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_download_section.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/audio_to_note_pipeline.dart';
import 'package:voice_2_note_ai/services/whisper_audio_import.dart';
import 'package:voice_2_note_ai/utils/turkish_text.dart';

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
    final q = normalizeForTurkishSearch(_query.trim());
    if (q.isEmpty) return notes;
    return notes.where((n) {
      return normalizeForTurkishSearch(n.transcript).contains(q) ||
          normalizeForTurkishSearch(n.summary).contains(q);
    }).toList();
  }

  Future<void> _importAudioFromFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    late String workPath;
    final tempDir = await getTemporaryDirectory();
    if (picked.bytes != null) {
      var ext = p.extension(picked.name).toLowerCase();
      if (ext.isEmpty) {
        ext = '.m4a';
      }
      workPath = p.join(
        tempDir.path,
        'pick_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await File(workPath).writeAsBytes(picked.bytes!);
    } else if (picked.path != null && picked.path!.isNotEmpty) {
      workPath = picked.path!;
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya okunamadı.')),
      );
      return;
    }

    final prepared = await prepareLocalAudioForWhisper(workPath);
    if (prepared == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ses dönüştürülemedi. Dosya bozuk olabilir veya biçim desteklenmiyor.',
          ),
        ),
      );
      return;
    }

    final support = await getApplicationSupportDirectory();
    final destPath = p.join(
      support.path,
      'imports',
      'note_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await Directory(p.dirname(destPath)).create(recursive: true);
    await File(prepared.wavPath).copy(destPath);

    if (!context.mounted) return;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);

    ref.read(pendingProcessingProvider.notifier).add(
          audioPath: destPath,
          durationSeconds: prepared.durationSeconds,
          displayLabel: 'Dosyadan',
        );

    unawaited(
      runAudioToNotePipeline(
        container: container,
        messenger: messenger,
        audioPath: destPath,
        durationSeconds: prepared.durationSeconds,
      ),
    );
  }

  Widget _recordFabStack(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'fab_import_audio',
          tooltip: 'Ses dosyası yükle (m4a, wav, …)',
          onPressed: () => _importAudioFromFile(context),
          child: const Icon(Icons.upload_file_rounded),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'fab_record',
          tooltip: 'Yeni ses kaydı',
          onPressed: () => AppNavigation.pushRecording(context),
          icon: const Icon(Icons.mic_rounded),
          label: const Text('Kayıt'),
        ),
      ],
    );
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
            'Kayıtlarınız ve metinler bu telefonda işlenir; '
            'sürekli internet gerekmez.',
          ),
        ),
        const WhisperModelDownloadSection(),
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

  PreferredSizeWidget _notesAppBar(
    BuildContext context, {
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: const Text('Notlar'),
      bottom: bottom,
      actions: [
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
        final pending = ref.watch(pendingProcessingProvider);
        final filtered = _filter(notes);

        if (notes.isEmpty && pending.isEmpty) {
          return Scaffold(
            appBar: _notesAppBar(context),
            floatingActionButton: _recordFabStack(context),
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
                        onPressed: () => AppNavigation.pushRecording(context),
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Ses kaydı'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _importAudioFromFile(context),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Ses dosyası yükle'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Galeriden veya dosyalardan ses seçebilirsiniz '
                      '(örneğin kayıtlı konuşma). Gerekirse uygun forma çevrilir.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final searchBar = PreferredSize(
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
        );

        final listChildren = <Widget>[
          ...pending.map((item) => _PendingProcessingTile(item: item)),
          if (filtered.isEmpty && _query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Text(
                'Bu aramaya uygun not yok.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ...filtered.map((note) => _NoteListTile(note: note)),
        ];

        return Scaffold(
          appBar: _notesAppBar(context, bottom: searchBar),
          floatingActionButton: _recordFabStack(context),
          body: RefreshIndicator(
            onRefresh: () => ref.refresh(notesListProvider.future),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: listChildren,
            ),
          ),
        );
      },
    );
  }
}

class _PendingProcessingTile extends StatelessWidget {
  const _PendingProcessingTile({required this.item});

  final PendingProcessingItem item;

  static String _fmtDur(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dur = _fmtDur(item.durationSeconds);
    return Semantics(
      label: '${item.displayLabel}, transkript hazırlanıyor, süre $dur',
      hint: 'İşlem bitince tam not listede görünür',
      child: ListTile(
        leading: ExcludeSemantics(
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        title: Text(item.displayLabel),
        subtitle: const Text('Transkript hazırlanıyor…'),
        trailing: Text(
          dur,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
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
      onTap: () => AppNavigation.pushNoteDetail(context, note),
    );
  }
}
