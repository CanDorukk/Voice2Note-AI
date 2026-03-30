import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_platform_channel.dart';

/// Whisper offline speech-to-text servisi.
///
/// Android: [MethodChannel] ile native tarafa iletilir (şimdilik stub yanıt).
/// Gerçek whisper.cpp inference sonraki adımda native tarafta bağlanacak.
class WhisperService {
  static const MethodChannel _channel =
      MethodChannel(kWhisperMethodChannelName);

  /// [audioPath] bir dosya path'i veya MediaStore `content://` uri olabilir.
  Future<String> transcribe({required String audioPath}) async {
    if (kDebugMode) {
      debugPrint('WhisperService.transcribe audioPath: $audioPath');
    }

    final modelPath = await WhisperModelService.instance.ensureReady();
    if (kDebugMode) {
      debugPrint('WhisperService: model path: $modelPath');
    }

    if (Platform.isAndroid) {
      try {
        final out = await _channel.invokeMethod<String>(
          'transcribe',
          <String, String?>{
            'modelPath': modelPath,
            'audioPath': audioPath,
          },
        );
        if (out != null && out.trim().isNotEmpty) {
          return out.trim();
        }
      } on PlatformException catch (e, st) {
        if (kDebugMode) {
          debugPrint('WhisperService PlatformException: $e\n$st');
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('WhisperService: $e\n$st');
        }
      }
    }

    return _fallbackTranscript();
  }

  String _fallbackTranscript() {
    return [
      'Bu kayıt sırasında uygulamanın tamamen çevrimdışı çalışması hedefleniyor.',
      'Önce ses notu kaydediliyor, ardından konuşma metne çevriliyor.',
      'Son olarak içerikten önemli cümleler seçilip kısa bir özet oluşturuluyor.',
      'Whisper native köprüsü hazır değilse bu metin kullanılır.'
    ].join(' ');
  }
}

