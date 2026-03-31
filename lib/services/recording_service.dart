import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Telefonun "müzik" klasöründe oluşturacağımız uygulama klasörü adı.
const String appRecordingsFolderName = 'Voice2 Note AI';

/// Ses kaydı: önce temp'e kaydeder, sonra MediaStore ile Music klasörüne taşır.
///
/// Böylece Android 10+ (scoped storage) yüzünden doğrudan `/storage/emulated/0/...` yazma
/// başarısız olunca bile dosya yine de hedef klasöre kaydedilir.
class RecordingService {
  RecordingService() : _recorder = Record();

  final Record _recorder;
  String? _tempPath;

  /// Mikrofon izni var mı / isteyebilir miyiz?
  Future<bool> hasPermission() async => _recorder.hasPermission();

  /// Kaydı başlat.
  Future<bool> start() async {
    if (!await hasPermission()) return false;
    final tempDir = await getTemporaryDirectory();
    _tempPath = join(
      tempDir.path,
      'note_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    if (kDebugMode) {
      debugPrint('RecordingService.start temp: $_tempPath');
    }
    await _recorder.start(
      path: _tempPath!,
      encoder: AudioEncoder.wav,
      samplingRate: 16000,
      numChannels: 1,
    );
    return true;
  }

  /// Kaydı durdur; kaydı MediaStore üzerinden Music klasörüne kaydeder.
  ///
  /// Başarılıysa dosyanın public path'ini döndürür (sonradan playback için kullanılacak).
  Future<String?> stop() async {
    final returned = await _recorder.stop();

    final tempPath = _tempPath ?? returned;
    _tempPath = null;

    if (tempPath == null) return null;
    if (!File(tempPath).existsSync()) {
      if (kDebugMode) {
        debugPrint('RecordingService.stop: temp file missing: $tempPath');
      }
      return null;
    }

    final mediaStore = MediaStore();
    final saveInfo = await mediaStore.saveFile(
      tempFilePath: tempPath,
      dirType: DirType.audio,
      dirName: DirName.music,
      // Hedef: Music/Recordings/<appName>/...
      relativePath: join('Recordings', appRecordingsFolderName),
    );

    final uri = saveInfo?.uri;
    if (uri == null) return null;

    final savedPath = await mediaStore.getFilePathFromUri(
      uriString: uri.toString(),
    );
    if (kDebugMode) {
      debugPrint('RecordingService.saved: $savedPath (uri: $uri)');
    }
    return savedPath ?? uri.toString();
  }

  void dispose() {
    _recorder.dispose();
  }
}
