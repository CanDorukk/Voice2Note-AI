import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/features/notes/pending_processing_provider.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';
import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
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
    final useRemote = await RemoteTranscribeSettings.isRemoteEnabled();
    final String? modelPath = useRemote
        ? null
        : await WhisperModelService.instance.ensureReady();
    if (!useRemote && (modelPath == null || modelPath.isEmpty)) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Ses tanıma paketi bulunamadı. İlk açılışta indirmeniz gerekir. '
            'Gerekirse uygulama verilerini temizleyip uygulamayı yeniden açarak '
            'tanıtım ekranına dönebilirsiniz (Ayarlar > Uygulamalar > bu uygulama > Depolama). '
            'Alternatif: Hakkında bölümünden PC sunucu adresi girerek transkripti bilgisayarda çalıştırabilirsiniz.',
          ),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              transcript: 'İşlem tamamlanamadı.',
              summary: '',
              duration: durationSeconds,
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ),
          );
      container.invalidate(notesListProvider);
    } catch (_) {}

    messenger.showSnackBar(
      SnackBar(
        content: Text('Kayıt işlenemedi: $e'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    container.read(pendingProcessingProvider.notifier).removeByAudioPath(audioPath);
  }
}
