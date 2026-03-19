import 'package:flutter/foundation.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_service.dart';

/// Speech-to-Text servisi.
///
/// Bu adımda Whisper entegrasyonu henüz yok; dönen değer "dummy" amaçlıdır.
/// Sonraki adımda bu sınıfın içini whisper.cpp ile dolduracağız.
class SpeechToTextService {
  /// [audioPath] bir cihaz path'i veya MediaStore content-uri olabilir.
  /// Şimdilik sadece debug amaçlı loglar ve dummy metin döndürür.
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
