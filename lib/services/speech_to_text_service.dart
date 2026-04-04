import 'package:flutter/foundation.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_service.dart';

/// Speech-to-Text: Android üzerinde `WhisperService` (whisper.cpp) ile transkript.
class SpeechToTextService {
  /// [audioPath] yerel dosya yolu veya `content://` URI olabilir.
  Future<String> transcribe({
    required String audioPath,
  }) async {
    if (kDebugMode) {
      debugPrint('SpeechToTextService.transcribe audioPath: $audioPath');
    }

    final whisper = WhisperService();
    return whisper.transcribe(audioPath: audioPath);
  }
}
