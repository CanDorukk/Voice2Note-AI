import 'package:flutter/foundation.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_service.dart';

/// Speech-to-Text: kayıtlı HTTP sunucusu ile transkript.
class SpeechToTextService {
  /// [audioPath] yerel dosya yolu veya `content://` URI olabilir.
  /// [audioDurationSeconds] zaman aşımı için tahmini süre.
  Future<String> transcribe({
    required String audioPath,
    int? audioDurationSeconds,
  }) async {
    if (kDebugMode) {
      debugPrint('SpeechToTextService.transcribe audioPath: $audioPath');
    }

    final whisper = WhisperService();
    return whisper.transcribe(
      audioPath: audioPath,
      audioDurationSeconds: audioDurationSeconds,
    );
  }
}
