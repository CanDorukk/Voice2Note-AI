import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:voice_2_note_ai/services/android_content_uri.dart';
import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';

/// Transkript: yalnızca kayıtlı HTTP sunucusu (`RemoteTranscribeSettings`).
///
/// Sunucu `POST /transcribe` yanıtında yalnızca `text` beklenir; isteğe bağlı Ollama
/// düzeltmesi sunucuda zincirlendiyse bu metin nihai (düzeltilmiş) içeriktir — ayrı uç gerekmez.
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

  /// [audioPath] yerel dosya yolu veya Android `content://` URI (geçici dosyaya kopyalanır).
  Future<String> transcribe({
    required String audioPath,
    int? audioDurationSeconds,
  }) async {
    final remoteBase = await RemoteTranscribeSettings.getBaseUrl();
    if (remoteBase == null || remoteBase.isEmpty) {
      return 'Konuşmanızı yazıya dökmek için Hakkında menüsünden bağlantı adresinizi ekleyin.';
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
    var pathForUpload = audioPath;
    if (audioPath.startsWith('content:')) {
      final tempDir = await getTemporaryDirectory();
      pathForUpload = p.join(
        tempDir.path,
        'transcribe_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      final ok = await AndroidContentUri.copyToFile(audioPath, pathForUpload);
      if (!ok) {
        return 'Ses dosyası açılamadı.';
      }
    }
    final file = File(pathForUpload);
    if (!await file.exists()) {
      return 'Ses dosyası bulunamadı. Tekrar deneyin.';
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
          pathForUpload,
          filename: p.basename(pathForUpload),
        ),
      );
      final streamed = await request.send().timeout(timeout);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        return 'Metin alınamadı (${streamed.statusCode}). Bağlantınızı kontrol edip tekrar deneyin.';
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return 'Beklenmeyen bir yanıt alındı. Bir süre sonra tekrar deneyin.';
      }
      final text = decoded['text'];
      if (text is! String) {
        return 'Metin bulunamadı. Tekrar deneyin.';
      }
      final t = text.trim();
      if (t.isEmpty) {
        return 'Boş metin alındı. Kaydı tekrar deneyin.';
      }
      return t;
    } on TimeoutException {
      return 'İşlem çok uzun sürdü (${timeout.inMinutes} dk). '
          'Bağlantınızı kontrol edip tekrar deneyin.';
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('TranscribeService._transcribeViaRemoteHttp: $e\n$st');
        return 'Transkript tamamlanamadı: $e';
      }
      return 'Transkript tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.';
    }
  }
}
