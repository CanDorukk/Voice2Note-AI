import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
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

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ses kaydı'),
        actions: const [
          ThemeModeMenuButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Geçen süre',
                value: _formatDuration(state.durationSeconds),
                child: Column(
                  children: [
                    Text(
                      'Geçen süre',
                      style: textTheme.labelLarge?.copyWith(
                        color: state.isRecording ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: textTheme.displaySmall!.copyWith(
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: state.isRecording ? cs.primary : cs.onSurface,
                      ),
                      child: Text(_formatDuration(state.durationSeconds)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
                        runAudioToNotePipeline(
                          container: container,
                          messenger: messenger,
                          audioPath: path,
                          durationSeconds: durationSeconds,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Kayıt dosyası oluşturulamadı.'),
                          backgroundColor: Theme.of(context).colorScheme.error,
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
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Column(
                  children: [
                    Text(
                      state.isRecording
                          ? 'Durdurmak için aşağıdaki düğmeye dokunun'
                          : 'Kayda başlamak için kırmızı düğmeye dokunun',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Kayıt bitince notlar listesinde işlenir; transkript için '
                      'Hakkında’da sunucu adresi kayıtlı olmalıdır.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
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
    final cs = Theme.of(context).colorScheme;
    final hint = isRecording ? 'Kaydı durdur' : 'Kayda başla';

    return Tooltip(
      message: hint,
      child: Semantics(
        button: true,
        label: hint,
        child: Material(
          color: Colors.transparent,
          elevation: isRecording ? 6 : 2,
          shadowColor: cs.shadow.withOpacity(0.35),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            splashColor: cs.error.withOpacity(0.25),
            highlightColor: cs.error.withOpacity(0.12),
            child: Ink(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? cs.error : cs.errorContainer,
                border: Border.all(
                  color: cs.error,
                  width: isRecording ? 5 : 4,
                ),
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 44,
                color: isRecording ? cs.onError : cs.onErrorContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
