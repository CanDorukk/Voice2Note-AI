import 'package:flutter/foundation.dart';

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';

/// Whisper offline speech-to-text servisi (iskelet).
///
/// Bu adımda henüz whisper.cpp native entegrasyonu yok.
/// Sonraki adımda burada whisper modelini yükleyip audio'yu transkribe edeceğiz.
class WhisperService {
  /// [audioPath] bir dosya path'i veya MediaStore `content://` uri olabilir.
  Future<String> transcribe({required String audioPath}) async {
    if (kDebugMode) {
      debugPrint('WhisperService.transcribe audioPath: $audioPath');
    }

    final modelPath = await WhisperModelService.instance.ensureReady();
    if (kDebugMode) {
      debugPrint('WhisperService: model path: $modelPath');
    }

    // TODO: whisper.cpp ile gerçek transkript üretilecek.
    // Not: Whisper genellikle wav gerektirir; m4a -> wav dönüşümü gerekebilir.
    return [
      'Bu kayıt sırasında uygulamanın tamamen çevrimdışı çalışması hedefleniyor.',
      'Önce ses notu kaydediliyor, ardından konuşma metne çevriliyor.',
      'Son olarak içerikten önemli cümleler seçilip kısa bir özet oluşturuluyor.',
      'Whisper entegrasyonu eklendiğinde bu metin gerçek transkript olacak.'
    ].join(' ');
  }
}

