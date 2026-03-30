import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// `ggml-tiny.bin` dosyasını asset'ten uygulama dizinine bir kez kopyalar.
///
/// Yerel geliştirme: `assets/models/ggml-tiny.bin` dosyasını kendi makinenize kopyalayın
/// (Git'e eklenmez; `.gitignore` içindedir).
class WhisperModelService {
  WhisperModelService._();

  static final WhisperModelService instance = WhisperModelService._();

  static const String _assetPath = 'assets/models/ggml-tiny.bin';
  static const String _diskRelativeDir = 'whisper';
  static const String _diskFileName = 'ggml-tiny.bin';

  /// Model dosyası hazırsa tam yol, aksi halde `null` (asset yok / kopya hatası).
  Future<String?> ensureReady() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final target = File(
        p.join(base.path, _diskRelativeDir, _diskFileName),
      );

      if (await target.exists()) {
        final len = await target.length();
        if (len > 0) {
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
      await target.writeAsBytes(bytes, flush: true);
      if (kDebugMode) {
        debugPrint(
          'WhisperModelService: asset kopyalandı ${target.path} (${bytes.length} byte)',
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
