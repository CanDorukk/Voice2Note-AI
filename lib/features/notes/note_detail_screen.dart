import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/features/export/pdf_preview_screen.dart';
import 'package:voice_2_note_ai/features/share/share_preview_screen.dart';

/// Tek bir notun detay ekranı: transkript, özet, ses oynatma, PDF, paylaşım.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
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

  Future<void> _togglePlay() async {
    final audioPath = widget.note.audioPath.trim();
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

  @override
  Widget build(BuildContext context) {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(widget.note.createdAt * 1000);
    final dateStr = '${createdAt.day}.${createdAt.month}.${createdAt.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Not ${widget.note.id ?? ''}'.trim()),
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
              titleAction: widget.note.transcript.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Transkripti kopyala',
                      icon: const Icon(Icons.copy_rounded, size: 22),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.note.transcript),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transkript kopyalandı')),
                        );
                      },
                    ),
              child: Text(
                widget.note.transcript.trim().isEmpty
                    ? 'Transcript henüz hazır değil.'
                    : widget.note.transcript,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Özet',
              icon: Icons.lightbulb_outline_rounded,
              child: Text(
                widget.note.summary.trim().isEmpty
                    ? 'Özet henüz hazır değil.'
                    : widget.note.summary,
              ),
            ),
            const SizedBox(height: 18),
            _AudioPlaybackCard(
              audioPath: widget.note.audioPath,
              position: _position,
              duration: _duration,
              isPlaying: _isPlaying,
              onPlayPause: _togglePlay,
              onSeek: _seekTo,
            ),
            const SizedBox(height: 14),
            _ActionsPlaceholder(
              note: widget.note,
              onPlay: _togglePlay,
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
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded),
                const SizedBox(width: 8),
                Text(
                  'Oynatma',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: onPlayPause,
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: duration.inMilliseconds.toDouble().clamp(0, 1e12),
                    value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble()),
                    onChanged: duration == Duration.zero
                        ? null
                        : (v) => onSeek(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_fmt(position)} / ${_fmt(duration)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Dosya: ${audioPath.split('/').last}',
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

class _ActionsPlaceholder extends StatelessWidget {
  const _ActionsPlaceholder({
    required this.note,
    required this.onPlay,
  });

  final NoteModel note;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: onPlay,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Oynat'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => PdfPreviewScreen(note: note),
              ),
            );
          },
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text('PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => SharePreviewScreen(note: note),
              ),
            );
          },
          icon: const Icon(Icons.share_rounded),
          label: const Text('Paylaş'),
        ),
      ],
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (titleAction != null) titleAction!,
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
