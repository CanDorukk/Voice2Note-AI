import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';

/// Transkript: yalnızca kayıtlı HTTP sunucusu (`RemoteTranscribeSettings`).
class TranscribeService {
  /// Uzun sesler için üst sınır (sunucu hızına bağlı).
  static Duration transcribeTimeoutForAudioSeconds(int? audioDurationSeconds) {
    final d = audioDurationSeconds;
    if (d == null || d <= 0) {
      return const Duration(minutes: 45);
    }
    final sec = (d * 3).clamp(300, 7200);
    return Duration(seconds: sec.toInt());
  }

  /// [audioPath] yerel dosya yolu; `content://` desteklenmez.
  Future<String> transcribe({
    required String audioPath,
    int? audioDurationSeconds,
  }) async {
    final remoteBase = await RemoteTranscribeSettings.getBaseUrl();
    if (remoteBase == null || remoteBase.isEmpty) {
      return 'Transkript için Hakkında’dan sunucu adresini kaydedin. '
          'Bilgisayarınızda API’yi çalıştırın (docs/pc_whisper_sunucu.md).';
    }
    return _transcribeViaRemoteHttp(
      baseUrl: remoteBase,
      audioPath: audioPath,
      audioDurationSeconds: audioDurationSeconds,
    );
  }

  Future<String> _transcribeViaRemoteHttp({
    required String baseUrl,
    required String audioPath,
    int? audioDurationSeconds,
  }) async {
    final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root/transcribe');
    if (audioPath.startsWith('content:')) {
      return 'Bu sürümde transkript için dosya yolu gerekir. '
          'Dosyayı yeniden içe aktarın veya uygulama içi kayıt kullanın.';
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
        'TranscribeService: POST $uri (zaman aşımı ${timeout.inMinutes} dk)',
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
      return 'Transkript zaman aşımı (${timeout.inMinutes} dk). '
          'Sunucunun açık ve aynı ağda olduğundan emin olun.';
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('TranscribeService._transcribeViaRemoteHttp: $e\n$st');
      }
      return 'Transkript başarısız: $e';
    }
  }
}
