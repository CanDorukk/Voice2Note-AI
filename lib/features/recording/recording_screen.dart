import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/features/notes/pending_processing_provider.dart';
import 'package:voice_2_note_ai/features/recording/post_recording_pipeline.dart';
import 'package:voice_2_note_ai/features/recording/recording_provider.dart';

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

                    // RecordingService zaten temp + MediaStore doğruladı; hemen sonra
                    // File.existsSync bazen yanlış false döner (yazım gecikmesi).
                    final hasPath =
                        path != null && path.trim().isNotEmpty;

                    if (hasPath) {
                      await HapticFeedback.mediumImpact();
                      if (!context.mounted) return;
                      ref.read(pendingProcessingProvider.notifier).add(
                            audioPath: path,
                            durationSeconds: durationSeconds,
                          );

                      final messenger = ScaffoldMessenger.of(context);
                      final container = ProviderScope.containerOf(context);

                      Navigator.of(context).pop();

                      unawaited(
                        runPostRecordingPipeline(
                          container: container,
                          messenger: messenger,
                          audioPath: path,
                          durationSeconds: durationSeconds,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kayıt dosyası oluşturulamadı.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    }
                  } else {
                    await notifier.startRecording();
                    if (!context.mounted) return;
                    if (ref.read(recordingProvider).isRecording) {
                      await HapticFeedback.lightImpact();
                    } else {
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
