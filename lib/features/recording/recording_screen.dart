import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/services/speech_to_text_service.dart';
import 'package:voice_2_note_ai/services/summary_service.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/features/recording/recording_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

/// Ses kayıt ekranı. Kayıt başlat/durdur, süre gösterimi.
class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key});

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingProvider);
    final notifier = ref.read(recordingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ses kaydı'),
        actions: const [
          ThemeModeMenuButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Geçen süre',
                value: _formatDuration(state.durationSeconds),
                child: Text(
                  _formatDuration(state.durationSeconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              _RecordButton(
                isRecording: state.isRecording,
                onPressed: () async {
                  if (state.isRecording) {
                    final durationSeconds = state.durationSeconds;
                    final path = await notifier.stopRecording();
                    if (!context.mounted) return;
                    final exists =
                        path != null && (path.startsWith('content://') || File(path).existsSync());
                    if (exists) {
                      final stt = SpeechToTextService();
                      final summarizer = SummaryService();

                      String? transcript;
                      String? summary;

                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) {
                          final navigator = Navigator.of(dialogContext);
                          var started = false;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              String stepText = 'Transkript alınıyor...';
                              if (!started) {
                                started = true;
                                Future<void>(() async {
                                  final minVisibleUntil = DateTime.now().add(
                                    const Duration(seconds: 1),
                                  );
                                  try {
                                    setState(() => stepText = 'Transkript alınıyor...');
                                    // İlk karede metnin görünmesi için kısa gecikme.
                                    await Future<void>.delayed(const Duration(milliseconds: 250));
                                    if (!context.mounted) return;
                                    transcript = await stt.transcribe(audioPath: path);

                                    if (!context.mounted) return;
                                    setState(() => stepText = 'Özet hazırlanıyor...');
                                    await Future<void>.delayed(const Duration(milliseconds: 150));
                                    if (!context.mounted) return;
                                    summary = await summarizer.summarize(transcript ?? '');

                                    if (!context.mounted) return;
                                    await ref.read(noteRepositoryProvider).insert(
                                          NoteModel(
                                            audioPath: path,
                                            transcript: transcript ?? '',
                                            summary: summary ?? '',
                                            duration: durationSeconds,
                                            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                                          ),
                                        );

                                    ref.invalidate(notesListProvider);
                                  } catch (e, st) {
                                    if (kDebugMode) {
                                      debugPrint('RecordingScreen işleme hatası: $e\n$st');
                                    }
                                    transcript ??= 'İşlem tamamlanamadı.';
                                    summary ??= '';
                                    if (!context.mounted) return;
                                    try {
                                      await ref.read(noteRepositoryProvider).insert(
                                            NoteModel(
                                              audioPath: path,
                                              transcript: transcript ?? '',
                                              summary: summary ?? '',
                                              duration: durationSeconds,
                                              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                                            ),
                                          );
                                      ref.invalidate(notesListProvider);
                                    } catch (_) {}
                                  } finally {
                                    final now = DateTime.now();
                                    if (now.isBefore(minVisibleUntil)) {
                                      await Future<void>.delayed(minVisibleUntil.difference(now));
                                    }
                                  }
                                  if (!context.mounted) return;
                                  if (navigator.canPop()) navigator.pop();
                                });
                              }

                              return AlertDialog(
                                title: const Text('İşleniyor'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const CircularProgressIndicator(),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            stepText,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Çevrimdışı transkript bu cihazda kayıt süresinin birkaç katı zaman alabilir.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Not kaydedildi'),
                          duration: const Duration(seconds: 3),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kayıt dosyası oluşturulamadı.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } else {
                    await notifier.startRecording();
                    if (!context.mounted) return;
                    if (!ref.read(recordingProvider).isRecording) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mikrofon izni gerekli'),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                state.isRecording ? 'Durdurmak için dokunun' : 'Kayda başlamak için dokunun',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hint = isRecording ? 'Kaydı durdur' : 'Kayda başla';

    return Tooltip(
      message: hint,
      child: Semantics(
        button: true,
        label: hint,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.errorContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.error,
                  width: 4,
                ),
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 40,
                color: isRecording
                    ? Theme.of(context).colorScheme.onError
                    : Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
