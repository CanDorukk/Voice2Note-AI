import 'package:flutter/foundation.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_service.dart';

/// Speech-to-Text: Ayarlarda PC sunucu adresi varsa HTTP; yoksa Android NDK Whisper.
class SpeechToTextService {
  /// [audioPath] yerel dosya yolu veya `content://` URI olabilir.
  /// [audioDurationSeconds] Whisper zaman aşımının ses uzunluğuna göre ayarlanması için.
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
