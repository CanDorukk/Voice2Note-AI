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

  /// Sonsuz beklemeyi önlemek için üst sınır; asıl hız model + native ayardan gelir.
  /// ~ses süresinin 12 katı, en az 15 dk en çok 45 dk.
  static Duration transcribeTimeoutForAudioSeconds(int? audioDurationSeconds) {
    final d = audioDurationSeconds;
    if (d == null || d <= 0) {
      return const Duration(minutes: 30);
    }
    final sec = (d * 12).clamp(900, 2700);
    return Duration(seconds: sec.toInt());
  }

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
  /// [audioDurationSeconds] verilirse transkript zaman aşımı buna göre uzatılır.
  Future<String> transcribe({
    required String audioPath,
    int? audioDurationSeconds,
  }) async {
    if (kDebugMode) {
      debugPrint('WhisperService.transcribe audioPath: $audioPath');
    }

    final timeout = transcribeTimeoutForAudioSeconds(audioDurationSeconds);
    if (kDebugMode) {
      debugPrint(
        'WhisperService: transkript zaman aşımı ${timeout.inMinutes} dk '
        '(ses ~${audioDurationSeconds ?? "?"} sn)',
      );
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
            .timeout(timeout);
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
          debugPrint(
            'WhisperService: transkript zaman aşımı (${timeout.inMinutes} dk).',
          );
        }
        return 'Transkript zaman aşımına uğradı (${timeout.inMinutes} dk). '
            'Uzun kayıtlar veya yavaş cihazda daha da sürebilir; daha kısa ses deneyin '
            'veya uygulamayı yeniden başlatıp tekrar deneyin.';
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
    return 'Konuşma metne çevrilemedi. Uygulamayı kapatıp açmayı deneyin.';
  }
}

