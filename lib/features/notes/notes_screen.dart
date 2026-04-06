import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:voice_2_note_ai/app/app_navigation.dart';
import 'package:voice_2_note_ai/app/show_app_about_dialog.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/features/notes/pending_processing_provider.dart';
import 'package:voice_2_note_ai/features/notes/user_search_synonyms_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/android_content_uri.dart';
import 'package:voice_2_note_ai/services/audio_to_note_pipeline.dart';
import 'package:voice_2_note_ai/utils/audio_duration_probe.dart';
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

  List<NoteModel> _filter(
    List<NoteModel> notes,
    Map<String, String> searchLookup,
  ) {
    final q = normalizeForTurkishSearch(
      _query.trim(),
      useSearchSynonyms: true,
      synonymLookup: searchLookup,
    );
    if (q.isEmpty) return notes;
    return notes.where((n) {
      final t = normalizeForTurkishSearch(
        n.transcript,
        useSearchSynonyms: true,
        synonymLookup: searchLookup,
      );
      final s = normalizeForTurkishSearch(
        n.summary,
        useSearchSynonyms: true,
        synonymLookup: searchLookup,
      );
      return t.contains(q) || s.contains(q);
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

    var ext = p.extension(picked.name).toLowerCase();
    if (ext.isEmpty) {
      ext = p.extension(workPath).toLowerCase();
    }
    if (ext.isEmpty) {
      ext = '.m4a';
    }

    final support = await getApplicationSupportDirectory();
    final destPath = p.join(
      support.path,
      'imports',
      'note_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await Directory(p.dirname(destPath)).create(recursive: true);

    if (picked.bytes != null) {
      await File(workPath).copy(destPath);
    } else if (workPath.startsWith('content:')) {
      final ok = await AndroidContentUri.copyToFile(workPath, destPath);
      if (!ok) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya bu cihazdan okunamadı.')),
        );
        return;
      }
    } else {
      await File(workPath).copy(destPath);
    }

    final durationSeconds = await probeAudioDurationSeconds(destPath);

    if (!context.mounted) return;
    final container = ProviderScope.containerOf(context);
    final messenger = ScaffoldMessenger.of(context);

    ref.read(pendingProcessingProvider.notifier).add(
          audioPath: destPath,
          durationSeconds: durationSeconds,
          displayLabel: 'Dosyadan',
        );

    unawaited(
      runAudioToNotePipeline(
        container: container,
        messenger: messenger,
        audioPath: destPath,
        durationSeconds: durationSeconds,
      ),
    );
  }

  Widget _recordFabStack(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'fab_import_audio',
          tooltip: 'Ses dosyası yükle (m4a, wav, …)',
          elevation: 2,
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          onPressed: () => _importAudioFromFile(context),
          child: const Icon(Icons.upload_file_rounded),
        ),
        const SizedBox(height: AppSpacing.md),
        FloatingActionButton.extended(
          heroTag: 'fab_record',
          tooltip: 'Yeni ses kaydı',
          elevation: 3,
          icon: const Icon(Icons.mic_rounded),
          label: const Text('Kayıt'),
          onPressed: () => AppNavigation.pushRecording(context),
        ),
      ],
    );
  }

  Future<void> _showAbout(BuildContext context) => showAppAboutDialog(context);

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
        final searchLookup = ref.watch(turkishSearchLookupProvider);
        final filtered = _filter(notes, searchLookup);

        if (notes.isEmpty && pending.isEmpty) {
          final cs = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: _notesAppBar(context),
            floatingActionButton: _recordFabStack(context),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: cs.primaryContainer,
                          child: Icon(
                            Icons.mic_none_rounded,
                            size: 40,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Henüz not yok',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sesli not için Kayıt veya ses dosyası yükleyerek başlayın.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Tooltip(
                          message: 'Ses kaydı ekranına git',
                          child: FilledButton.icon(
                            onPressed: () => AppNavigation.pushRecording(context),
                            icon: const Icon(Icons.mic_rounded),
                            label: const Text('Ses kaydı'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () => _importAudioFromFile(context),
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Ses dosyası yükle'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Dosyalardan veya galeriden ses seçebilirsiniz; '
                          'transkript bilgisayarınızdaki sunucuda yapılır.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final searchBar = PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              children: listChildren,
            ),
          ),
        );
      },
    );
  }
}

class _PendingProcessingTile extends StatefulWidget {
  const _PendingProcessingTile({required this.item});

  final PendingProcessingItem item;

  @override
  State<_PendingProcessingTile> createState() => _PendingProcessingTileState();
}

class _PendingProcessingTileState extends State<_PendingProcessingTile> {
  Timer? _elapsedTicker;

  @override
  void initState() {
    super.initState();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    super.dispose();
  }

  static String _fmtDur(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtElapsed() {
    final start = DateTime.fromMillisecondsSinceEpoch(widget.item.startedAtMs);
    final d = DateTime.now().difference(start);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m dk ${s.toString().padLeft(2, '0')} sn';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dur = _fmtDur(item.durationSeconds);
    final cs = Theme.of(context).colorScheme;
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    return Semantics(
      label:
          '${item.displayLabel}, transkript sunucuda çalışıyor, kayıt süresi $dur, geçen ${_fmtElapsed()}',
      hint: 'İşlem bitince tam not listede görünür',
      child: ListTile(
        isThreeLine: true,
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
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ),
        title: Text(item.displayLabel),
        subtitle: Text(
          'Transkript kayıtlı sunucuda çalışıyor (bilgisayarınız açık ve aynı ağda olmalı).\n'
          'Geçen: ${_fmtElapsed()} · Uzun kayıtlar birkaç–on dakika sürebilir; uygulama donmadı.\n'
          'Ses süresi: $dur',
          style: bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        trailing: Text(
          dur,
          style: bodySmall?.copyWith(color: cs.onSurfaceVariant),
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

    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Icon(
          Icons.note_outlined,
          color: cs.onPrimaryContainer,
        ),
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
