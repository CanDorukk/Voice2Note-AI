import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/app/app.dart';
import 'package:voice_2_note_ai/app/show_app_about_dialog.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/features/notes/pending_processing_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';
import 'package:voice_2_note_ai/services/server_url_nudge_prefs.dart';
import 'package:voice_2_note_ai/services/speech_to_text_service.dart';
import 'package:voice_2_note_ai/services/summary_service.dart';

/// Ses dosyasından transkript + özet + DB; kayıt veya dosya içe aktarma sonrası kullanılır.
Future<void> runAudioToNotePipeline({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required String audioPath,
  required int durationSeconds,
}) async {
  final stt = SpeechToTextService();
  final summarizer = SummaryService();

  try {
    final hasServer = await RemoteTranscribeSettings.isRemoteEnabled();
    if (!hasServer) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Konuşmanızı yazıya dökmek için önce Hakkında bölümünden bağlantı adresinizi kaydedin.',
          ),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      final showNudge = await ServerUrlNudgePrefs.shouldShowSetupNudge();
      if (showNudge) {
        final navCtx = appRootNavigatorKey.currentContext;
        if (navCtx != null && navCtx.mounted) {
          await showDialog<void>(
            context: navCtx,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Bağlantı adresi gerekli'),
                content: const Text(
                  'Konuşma metnini oluşturmak için bir adres tanımlamanız gerekiyor. '
                  'Hakkında menüsünden ekleyebilirsiniz.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Tamam'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      final c = appRootNavigatorKey.currentContext;
                      if (c != null && c.mounted) {
                        unawaited(showAppAboutDialog(c));
                      }
                    },
                    child: const Text('Hakkında'),
                  ),
                ],
              );
            },
          );
          await ServerUrlNudgePrefs.markSetupNudgeSeen();
        }
      }
      return;
    }

    final transcript = await stt.transcribe(
      audioPath: audioPath,
      audioDurationSeconds: durationSeconds,
    );
    final summary = await summarizer.summarize(transcript);

    await container.read(noteRepositoryProvider).insert(
          NoteModel(
            audioPath: audioPath,
            transcript: transcript,
            summary: summary,
            duration: durationSeconds,
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );
    container.invalidate(notesListProvider);

    if (kDebugMode) {
      debugPrint('AudioToNotePipeline: not kaydedildi');
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Not hazır'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('AudioToNotePipeline hatası: $e\n$st');
    }
    try {
      await container.read(noteRepositoryProvider).insert(
            NoteModel(
              audioPath: audioPath,
              transcript: 'Not hazırlanamadı.',
              summary: '',
              duration: durationSeconds,
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
      container.invalidate(notesListProvider);
    } catch (_) {}

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          kDebugMode
              ? 'Not oluşturulamadı: $e'
              : 'Not oluşturulamadı. Bağlantınızı kontrol edip tekrar deneyin.',
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    container.read(pendingProcessingProvider.notifier).removeByAudioPath(audioPath);
  }
}
