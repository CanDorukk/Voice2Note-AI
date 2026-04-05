import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_constants.dart';

/// `ggml-base-q5_1.bin` (quantize) dosyasını asset'ten uygulama dizinine kopyalar.
///
/// Diskteki dosya çok küçükse (bozuk/kısmi kopya) silinip asset'ten yeniden yazılır.
///
/// Yerel geliştirme: `assets/models/ggml-base-q5_1.bin` dosyasını
/// Hugging Face `ggerganov/whisper.cpp` üzerinden indirip koyun
/// (Git'e eklenmez; `.gitignore` içindedir).
class WhisperModelService {
  WhisperModelService._();

  static final WhisperModelService instance = WhisperModelService._();

  static const String _assetPath = 'assets/models/ggml-base-q5_1.bin';
  static const String _diskRelativeDir = 'whisper';
  static const String _diskFileName = 'ggml-base-q5_1.bin';

  /// Eski sürüm dosya adları (tek seferlik temizlik).
  static const List<String> _legacyDiskFileNames = [
    'ggml-tiny.bin',
    'ggml-tiny-q5_1.bin',
  ];

  Future<File> _targetModelFile() async {
    final base = await getApplicationDocumentsDirectory();
    return File(p.join(base.path, _diskRelativeDir, _diskFileName));
  }

  /// Hugging Face üzerinden doğrudan indirir (HTTPS). İndirilen dosya [ensureReady] ile kullanılır.
  Future<bool> downloadGgmlBaseQ5FromNetwork({
    void Function(int received, int? total)? onProgress,
  }) async {
    final uri = Uri.parse(
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin',
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 8;
      request.headers.set('User-Agent', 'Voice2NoteAI/1.0 (Flutter)');
      final response = await request.close();
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            'WhisperModelService: HTTP ${response.statusCode} indirme',
          );
        }
        return false;
      }
      final total = response.contentLength >= 0 ? response.contentLength : null;
      final target = await _targetModelFile();
      await target.parent.create(recursive: true);
      final partPath = '${target.path}.part';
      final part = File(partPath);
      if (await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
      var received = 0;
      final sink = part.openWrite();
      try {
        await for (final chunk in response) {
          received += chunk.length;
          sink.add(chunk);
          onProgress?.call(received, total);
        }
      } finally {
        await sink.close();
      }
      if (received < kWhisperGgmlBaseQ5MinBytes) {
        try {
          await part.delete();
        } catch (_) {}
        return false;
      }
      if (await target.exists()) {
        try {
          await target.delete();
        } catch (_) {}
      }
      await part.rename(target.path);
      if (kDebugMode) {
        debugPrint(
          'WhisperModelService: ağdan indirildi ${target.path} ($received byte)',
        );
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WhisperModelService.downloadGgmlBaseQ5FromNetwork: $e\n$st');
      }
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _deleteLegacyModelsIfPresent(String basePath) async {
    final dir = p.join(basePath, _diskRelativeDir);
    for (final name in _legacyDiskFileNames) {
      final f = File(p.join(dir, name));
      if (!await f.exists()) continue;
      try {
        await f.delete();
        if (kDebugMode) {
          debugPrint('WhisperModelService: eski model silindi: $name');
        }
      } catch (_) {}
    }
  }

  /// Model dosyası hazırsa tam yol, aksi halde `null` (asset yok / kopya hatası).
  Future<String?> ensureReady() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      await _deleteLegacyModelsIfPresent(base.path);
      final target = await _targetModelFile();

      Future<void> removeIfInvalid() async {
        if (!await target.exists()) return;
        final len = await target.length();
        if (len >= kWhisperGgmlBaseQ5MinBytes) return;
        if (kDebugMode) {
          debugPrint(
            'WhisperModelService: model geçersiz boyut ($len byte), yeniden kopyalanacak',
          );
        }
        try {
          await target.delete();
        } catch (_) {}
      }

      await removeIfInvalid();

      if (await target.exists()) {
        final len = await target.length();
        if (len >= kWhisperGgmlBaseQ5MinBytes) {
          if (kDebugMode) {
            debugPrint(
              'WhisperModelService: mevcut model ${target.path} ($len byte)',
            );
          }
          return target.path;
        }
      }

      await target.parent.create(recursive: true);
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List();
      if (bytes.length < kWhisperGgmlBaseQ5MinBytes) {
        if (kDebugMode) {
          debugPrint(
            'WhisperModelService: asset model çok küçük (${bytes.length} byte). '
            'Gerçek ggml-base-q5_1.bin dosyasını Hugging Face’den indirip '
            'assets/models/ altına koyun; boş/placeholder dosya ile Whisper çalışmaz.',
          );
        }
        return null;
      }
      await target.writeAsBytes(bytes, flush: true);
      final written = await target.length();
      if (written < kWhisperGgmlBaseQ5MinBytes) {
        try {
          await target.delete();
        } catch (_) {}
        return null;
      }
      if (kDebugMode) {
        debugPrint(
          'WhisperModelService: asset kopyalandı ${target.path} ($written byte)',
        );
      }
      return target.path;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WhisperModelService.ensureReady: $e\n$st');
      }
      return null;
    }
  }
}
