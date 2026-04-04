import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/features/notes/notes_provider.dart';
import 'package:voice_2_note_ai/features/notes/pending_processing_provider.dart';
import 'package:voice_2_note_ai/models/note_model.dart';
import 'package:voice_2_note_ai/services/speech_to_text_service.dart';
import 'package:voice_2_note_ai/services/summary_service.dart';

/// Kayıt durduktan sonra transkript + özet + DB; çağıran route kapansa bile çalışır.
Future<void> runPostRecordingPipeline({
  required ProviderContainer container,
  required ScaffoldMessengerState messenger,
  required String audioPath,
  required int durationSeconds,
}) async {
  final stt = SpeechToTextService();
  final summarizer = SummaryService();

  try {
    final transcript = await stt.transcribe(audioPath: audioPath);
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
      debugPrint('PostRecordingPipeline: not kaydedildi');
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
      debugPrint('PostRecordingPipeline hatası: $e\n$st');
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
