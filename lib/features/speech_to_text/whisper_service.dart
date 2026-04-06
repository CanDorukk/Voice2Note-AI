import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_platform_channel.dart';
import 'package:path/path.dart' as p;
import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';

/// Whisper speech-to-text: önce kayıtlı PC URL varsa HTTP; yoksa Android NDK `whisper.cpp`.
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
  /// Uzak transkript etkinse yerel model yüklenmez.
  Future<void> warmup() async {
    if (!Platform.isAndroid) {
      return;
    }
    if (await RemoteTranscribeSettings.isRemoteEnabled()) {
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
    final remoteBase = await RemoteTranscribeSettings.getBaseUrl();
    if (remoteBase != null && remoteBase.isNotEmpty) {
      return _transcribeViaRemoteHttp(
        baseUrl: remoteBase,
        audioPath: audioPath,
        audioDurationSeconds: audioDurationSeconds,
      );
    }

    if (kDebugMode) {
      debugPrint('WhisperService.transcribe (yerel NDK) audioPath: $audioPath');
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

  /// PC / VPS üzerindeki FastAPI sunucusu (`docs/pc_whisper_sunucu.md`).
  Future<String> _transcribeViaRemoteHttp({
    required String baseUrl,
    required String audioPath,
    int? audioDurationSeconds,
  }) async {
    final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root/transcribe');
    if (audioPath.startsWith('content:')) {
      return 'PC sunucusu ile transkript şimdilik dosya yolu gerektiriyor. '
          'Ses dosyasını tekrar içe aktarın veya uygulama içi kayıt kullanın.';
    }
    final file = File(audioPath);
    if (!await file.exists()) {
      return 'Ses dosyası bulunamadı.';
    }
    final timeoutMin = (audioDurationSeconds != null && audioDurationSeconds > 0)
        ? ((audioDurationSeconds * 3) / 60).ceil().clamp(5, 120)
        : 45;
    final timeout = Duration(minutes: timeoutMin);
    if (kDebugMode) {
      debugPrint(
        'WhisperService: uzak transkript POST $uri (zaman aşımı ${timeout.inMinutes} dk)',
      );
    }
    try {
      final request = http.MultipartRequest('POST', uri);
      final apiKey = await RemoteTranscribeSettings.getApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        request.headers['X-Api-Key'] = apiKey;
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioPath,
          filename: p.basename(audioPath),
        ),
      );
      final streamed = await request.send().timeout(timeout);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        return 'Sunucu yanıtı (${streamed.statusCode}): ${body.length > 500 ? "${body.substring(0, 500)}…" : body}';
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return 'Sunucu yanıtı beklenen JSON değil.';
      }
      final text = decoded['text'];
      if (text is! String) {
        return 'Sunucu yanıtında metin yok.';
      }
      final t = text.trim();
      if (t.isEmpty) {
        return 'Sunucu boş metin döndü.';
      }
      return t;
    } on TimeoutException {
      return 'Uzak transkript zaman aşımı (${timeout.inMinutes} dk). '
          'PC sunucusunun açık ve aynı ağda olduğundan emin olun.';
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WhisperService._transcribeViaRemoteHttp: $e\n$st');
      }
      return 'Uzak transkript başarısız: $e';
    }
  }

  String _fallbackTranscript() {
    return 'Konuşma metne çevrilemedi. Uygulamayı kapatıp açmayı deneyin.';
  }
}

