import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voice_2_note_ai/core/constants/app_constants.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_ggml_model.dart';

/// Seçilen ggml quantize dosyasını asset veya ağdan uygulama dizinine getirir.
class WhisperModelService {
  WhisperModelService._();

  static final WhisperModelService instance = WhisperModelService._();

  static const String _diskRelativeDir = 'whisper';

  /// Eski sürüm dosya adları (tek seferlik temizlik). `ggml-tiny-q5_1.bin` burada
  /// olmamalı — seçilen model dosyası silinir.
  static const List<String> _legacyDiskFileNames = [
    'ggml-tiny.bin',
  ];

  /// Tercih kaydı yokken diskte hangi modelin hazır olduğunu bulur (Small > Base > Tiny).
  Future<WhisperGgmlModel?> _firstCompleteModelOnDisk() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = p.join(base.path, _diskRelativeDir);
    const order = [
      WhisperGgmlModel.small,
      WhisperGgmlModel.base,
      WhisperGgmlModel.tiny,
    ];
    for (final model in order) {
      final f = File(p.join(dir, model.storageFileName));
      if (!await f.exists()) continue;
      final len = await f.length();
      if (len >= model.minValidBytes) {
        return model;
      }
    }
    return null;
  }

  Future<WhisperGgmlModel> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.whisperGgmlModelKey);
    if (raw != null) {
      switch (raw) {
        case 'small':
          return WhisperGgmlModel.small;
        case 'base':
          return WhisperGgmlModel.base;
        case 'tiny':
          return WhisperGgmlModel.tiny;
        default:
          return WhisperGgmlModel.small;
      }
    }
    // Kayıtlı tercih yok: önce mevcut dosya (yükseltmede yalnızca Tiny varken takılmayı önle).
    final onDisk = await _firstCompleteModelOnDisk();
    if (onDisk != null) {
      return onDisk;
    }
    // Yeni kurulum: en iyi doğruluk (Small); kullanıcı splash’tan indirir.
    return WhisperGgmlModel.small;
  }

  Future<void> setSelectedModel(WhisperGgmlModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.whisperGgmlModelKey, model.name);
  }

  Future<File> _targetModelFile(WhisperGgmlModel model) async {
    final base = await getApplicationDocumentsDirectory();
    return File(p.join(base.path, _diskRelativeDir, model.storageFileName));
  }

  /// Seçili modele göre Hugging Face’den indirir.
  Future<bool> downloadSelectedModelFromNetwork({
    void Function(int received, int? total)? onProgress,
  }) async {
    final model = await getSelectedModel();
    final uri = Uri.parse(model.huggingFaceUrl);
    final minBytes = model.minValidBytes;
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
      final target = await _targetModelFile(model);
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
      if (received < minBytes) {
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
        debugPrint(
          'WhisperModelService.downloadSelectedModelFromNetwork: $e\n$st',
        );
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

  /// Seçilen model dosyası hazırsa tam yol, aksi halde `null`.
  Future<String?> ensureReady() async {
    try {
      final model = await getSelectedModel();
      final base = await getApplicationDocumentsDirectory();
      await _deleteLegacyModelsIfPresent(base.path);
      final target = await _targetModelFile(model);
      final minBytes = model.minValidBytes;

      Future<void> removeIfInvalid() async {
        if (!await target.exists()) return;
        final len = await target.length();
        if (len >= minBytes) return;
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
        if (len >= minBytes) {
          if (kDebugMode) {
            debugPrint(
              'WhisperModelService: mevcut model ${target.path} ($len byte)',
            );
          }
          return target.path;
        }
      }

      final assetPath = model.bundledAssetPath;
      if (assetPath == null) {
        return null;
      }

      await target.parent.create(recursive: true);
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      if (bytes.length < minBytes) {
        if (kDebugMode) {
          debugPrint(
            'WhisperModelService: asset model çok küçük (${bytes.length} byte). '
            'Gerçek ${model.storageFileName} dosyasını Hugging Face’den indirip '
            'assets/models/ altına koyun; boş/placeholder dosya ile Whisper çalışmaz.',
          );
        }
        return null;
      }
      await target.writeAsBytes(bytes, flush: true);
      final written = await target.length();
      if (written < minBytes) {
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
