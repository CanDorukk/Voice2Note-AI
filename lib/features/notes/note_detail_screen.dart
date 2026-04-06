import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voice_2_note_ai/app/app_navigation.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// Tek bir notun detay ekranı: transkript, özet, ses oynatma, PDF, paylaşım.
class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late NoteModel _note;
  late TextEditingController _transcriptController;
  late TextEditingController _summaryController;
  bool _editing = false;

  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<ProcessingState>? _processingSub;

  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _transcriptController = TextEditingController(text: _note.transcript);
    _summaryController = TextEditingController(text: _note.summary);

    _positionSub = _player.positionStream.listen((d) {
      if (!mounted) return;
      setState(() => _position = d);
    });
    _durationSub = _player.durationStream.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d ?? Duration.zero);
    });
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });

    // Parça bittiğinde otomatik başa saralım.
    _processingSub = _player.processingStateStream.listen((state) async {
      if (!mounted) return;
      if (state == ProcessingState.completed) {
        try {
          await _player.pause();
          await _player.seek(Duration.zero);
        } catch (_) {
          // some platforms may throw if completed transitions quickly.
        }
      }
    });
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _summaryController.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _processingSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _saveEdits() async {
    final id = _note.id;
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu not kayıtlı değil; düzenlenemez.')),
      );
      return;
    }

    final updated = NoteModel(
      id: id,
      audioPath: _note.audioPath,
      transcript: _transcriptController.text,
      summary: _summaryController.text,
      duration: _note.duration,
      createdAt: _note.createdAt,
    );

    final rows = await ref.read(noteRepositoryProvider).update(updated);
    if (!mounted) return;
    if (rows == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilemedi.')),
      );
      return;
    }

    setState(() {
      _note = updated;
      _editing = false;
    });
    ref.invalidate(notesListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not güncellendi')),
    );
  }

  Future<void> _togglePlay() async {
    final audioPath = _note.audioPath.trim();
    if (audioPath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses dosyası yolu yok.')),
      );
      return;
    }

    try {
      if (_loadedPath != audioPath) {
        await _player.stop();
        if (audioPath.startsWith('content://')) {
          await _player.setAudioSource(
            AudioSource.uri(Uri.parse(audioPath)),
          );
        } else {
          await _player.setFilePath(audioPath);
        }
        _loadedPath = audioPath;
      }

      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oynatma hatası: $e')),
      );
    }
  }

  Future<void> _seekTo(double value) async {
    if (_duration == Duration.zero) return;
    final ms = value.round().clamp(0, _duration.inMilliseconds);
    await _player.seek(Duration(milliseconds: ms));
  }

  /// Transkript/özet başlığında kopyala ikonu; metin boşsa null.
  Widget? _copyTitleAction(String text, String tooltip, String snackMessage) {
    if (text.trim().isEmpty) return null;
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.copy_rounded, size: 22),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackMessage)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(_note.createdAt * 1000);
    final dateStr = '${createdAt.day}.${createdAt.month}.${createdAt.year}';

    final transcriptCopy =
        _editing ? _transcriptController.text : _note.transcript;
    final summaryCopy = _editing ? _summaryController.text : _note.summary;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Not ${_note.id ?? ''}'.trim()),
        actions: [
          if (_note.id != null) ...[
            if (_editing) ...[
              IconButton(
                tooltip: 'İptal',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _editing = false;
                    _transcriptController.text = _note.transcript;
                    _summaryController.text = _note.summary;
                  });
                },
              ),
              IconButton(
                tooltip: 'Kaydet',
                icon: const Icon(Icons.check_rounded),
                onPressed: _saveEdits,
              ),
            ] else ...[
              IconButton(
                tooltip: 'Düzenle',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _editing = true),
              ),
              IconButton(
                tooltip: 'PDF önizleme',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => AppNavigation.pushPdfPreview(context, _note),
              ),
              IconButton(
                tooltip: 'Paylaş',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => AppNavigation.pushSharePreview(context, _note),
              ),
            ],
          ],
          const ThemeModeMenuButton(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            Text(
              'Oluşturulma: $dateStr',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Transkript',
              icon: Icons.mic_none_rounded,
              titleAction: _editing
                  ? null
                  : _copyTitleAction(
                      transcriptCopy,
                      'Transkripti kopyala',
                      'Transkript kopyalandı',
                    ),
              child: _editing
                  ? TextField(
                      controller: _transcriptController,
                      minLines: 4,
                      maxLines: 12,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        hintText: 'Transkript metni',
                      ),
                    )
                  : SelectableText(
                      _note.transcript.trim().isEmpty
                          ? 'Transkript henüz hazır değil.'
                          : _note.transcript,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                            color: _note.transcript.trim().isEmpty
                                ? cs.onSurfaceVariant
                                : null,
                          ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Özet',
              icon: Icons.lightbulb_outline_rounded,
              titleAction: _editing
                  ? null
                  : _copyTitleAction(
                      summaryCopy,
                      'Özeti kopyala',
                      'Özet kopyalandı',
                    ),
              child: _editing
                  ? TextField(
                      controller: _summaryController,
                      minLines: 3,
                      maxLines: 10,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        hintText: 'Özet',
                      ),
                    )
                  : SelectableText(
                      _note.summary.trim().isEmpty
                          ? 'Özet henüz hazır değil.'
                          : _note.summary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                            color: _note.summary.trim().isEmpty
                                ? cs.onSurfaceVariant
                                : null,
                          ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AudioPlaybackCard(
              audioPath: _note.audioPath,
              position: _position,
              duration: _duration,
              isPlaying: _isPlaying,
              onPlayPause: _togglePlay,
              onSeek: _seekTo,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlaybackCard extends StatelessWidget {
  const _AudioPlaybackCard({
    required this.audioPath,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
  });

  final String audioPath;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;

  static String _fmt(Duration d) => _NoteDetailScreenState._fmt(d);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 22,
                  color: cs.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Ses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: onPlayPause,
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: duration.inMilliseconds.toDouble().clamp(0, 1e12),
                    value: position.inMilliseconds
                        .toDouble()
                        .clamp(0, duration.inMilliseconds.toDouble()),
                    semanticFormatterCallback: (value) {
                      return _fmt(Duration(milliseconds: value.round()));
                    },
                    onChanged: duration == Duration.zero
                        ? null
                        : (v) => onSeek(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              label: 'Geçen ve toplam süre',
              value: '${_fmt(position)} / ${_fmt(duration)}',
              child: Text(
                '${_fmt(position)} / ${_fmt(duration)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              audioPath.contains('/')
                  ? 'Dosya: ${audioPath.split('/').last}'
                  : audioPath,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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
    this.titleAction,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? titleAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (titleAction != null) titleAction!,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}
