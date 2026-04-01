import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_constants.dart';

/// `ggml-tiny-q5_1.bin` (quantize) dosyasını asset'ten uygulama dizinine kopyalar.
///
/// Diskteki dosya çok küçükse (bozuk/kısmi kopya) silinip asset'ten yeniden yazılır.
///
/// Yerel geliştirme: `assets/models/ggml-tiny-q5_1.bin` dosyasını
/// Hugging Face `ggerganov/whisper.cpp` üzerinden indirip koyun
/// (Git'e eklenmez; `.gitignore` içindedir).
class WhisperModelService {
  WhisperModelService._();

  static final WhisperModelService instance = WhisperModelService._();

  static const String _assetPath = 'assets/models/ggml-tiny-q5_1.bin';
  static const String _diskRelativeDir = 'whisper';
  static const String _diskFileName = 'ggml-tiny-q5_1.bin';
  static const String _legacyDiskFileName = 'ggml-tiny.bin';

  Future<void> _deleteLegacyModelIfPresent(String basePath) async {
    final legacy = File(p.join(basePath, _diskRelativeDir, _legacyDiskFileName));
    if (!await legacy.exists()) return;
    try {
      await legacy.delete();
      if (kDebugMode) {
        debugPrint(
          'WhisperModelService: eski $_legacyDiskFileName silindi (quantize modele geçiş)',
        );
      }
    } catch (_) {}
  }

  /// Model dosyası hazırsa tam yol, aksi halde `null` (asset yok / kopya hatası).
  Future<String?> ensureReady() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      await _deleteLegacyModelIfPresent(base.path);
      final target = File(
        p.join(base.path, _diskRelativeDir, _diskFileName),
      );

      Future<void> removeIfInvalid() async {
        if (!await target.exists()) return;
        final len = await target.length();
        if (len >= kWhisperGgmlTinyQ5MinBytes) return;
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
        if (len >= kWhisperGgmlTinyQ5MinBytes) {
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
      if (bytes.length < kWhisperGgmlTinyQ5MinBytes) {
        if (kDebugMode) {
          debugPrint(
            'WhisperModelService: asset model çok küçük (${bytes.length} byte)',
          );
        }
        return null;
      }
      await target.writeAsBytes(bytes, flush: true);
      final written = await target.length();
      if (written < kWhisperGgmlTinyQ5MinBytes) {
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
