import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_platform_channel.dart';

/// Whisper offline speech-to-text servisi.
///
/// Android: [MethodChannel] ile native `whisper.cpp` transkripti çalışır.
class WhisperService {
  static const MethodChannel _channel =
      MethodChannel(kWhisperMethodChannelName);

  /// Native `whisper_full` takılırsa sonsuz bekleme yerine hata dönmek için üst sınır.
  static const Duration transcribeTimeout = Duration(minutes: 15);

  /// Model dosyasını (varsa) belleğe yükler; ilk kayıttan önce arka planda çağrılabilir.
  Future<void> warmup() async {
    if (!Platform.isAndroid) {
      return;
    }
    final modelPath = await WhisperModelService.instance.ensureReady();
    if (modelPath == null) {
      return;
    }
    try {
      await _channel.invokeMethod<String>('warmup', modelPath);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WhisperService.warmup: $e\n$st');
      }
    }
  }

  /// [audioPath] bir dosya path'i veya MediaStore `content://` uri olabilir.
  Future<String> transcribe({required String audioPath}) async {
    if (kDebugMode) {
      debugPrint('WhisperService.transcribe audioPath: $audioPath');
    }

    final modelPath = await WhisperModelService.instance.ensureReady();
    if (kDebugMode) {
      debugPrint('WhisperService: model path: $modelPath');
    }

    if (modelPath == null || modelPath.isEmpty) {
      if (kDebugMode) {
        debugPrint('WhisperService: model dosyası yok (asset kurulumu kontrol edin).');
      }
      return _fallbackTranscript();
    }

    if (Platform.isAndroid) {
      try {
        final out = await _channel
            .invokeMethod<String>(
              'transcribe',
              <String, String?>{
                'modelPath': modelPath,
                'audioPath': audioPath,
              },
            )
            .timeout(transcribeTimeout);
        if (out != null && out.trim().isNotEmpty) {
          final text = out.trim();
          if (kDebugMode) {
            debugPrint(
              'WhisperService: transkript tamam (${text.length} karakter)',
            );
          }
          return text;
        }
        if (kDebugMode) {
          debugPrint('WhisperService: native boş metin döndü');
        }
      } on TimeoutException {
        if (kDebugMode) {
          debugPrint('WhisperService: transkript zaman aşımı (${transcribeTimeout.inMinutes} dk).');
        }
        return 'Transkript zaman aşımına uğradı. Daha kısa kayıt deneyin veya uygulamayı yeniden başlatın.';
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
    return 'Transkript alınamadı. Uygulamayı yeniden başlatıp tekrar deneyin.';
  }
}

