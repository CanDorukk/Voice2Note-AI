import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:voice_2_note_ai/utils/wav_pcm_info.dart';

/// Sunucuya gönderilecek ses: 16 kHz mono PCM WAV yolu ve süre.
class WhisperAudioPrepared {
  const WhisperAudioPrepared({
    required this.wavPath,
    required this.durationSeconds,
  });

  final String wavPath;
  final int durationSeconds;
}

const MethodChannel _kAudioChannel =
    MethodChannel('com.example.voice_2_note_ai/audio');

/// Yerel ses dosyasını transkript API’sinin beklediği formata getirir.
///
/// Uygun WAV ise yeniden kodlamaz. Diğer biçimlerde Android’de yerel
/// MediaExtractor/MediaCodec ile 16 kHz mono WAV üretilir.
Future<WhisperAudioPrepared?> prepareLocalAudioForWhisper(String sourcePath) async {
  final ext = p.extension(sourcePath).toLowerCase();

  if (ext == '.wav') {
    final info = await readWavPcmInfo(sourcePath);
    if (info.ok) {
      return WhisperAudioPrepared(
        wavPath: sourcePath,
        durationSeconds: info.durationSeconds,
      );
    }
    if (kDebugMode) {
      debugPrint(
        'prepareLocalAudioForWhisper: WAV uyumsuz, dönüştürme denenecek: ${info.error}',
      );
    }
  }

  if (!Platform.isAndroid) {
    if (kDebugMode) {
      debugPrint('prepareLocalAudioForWhisper: dönüştürme yalnızca Android');
    }
    return null;
  }

  final tempDir = await getTemporaryDirectory();
  final outPath = p.join(
    tempDir.path,
    'whisper_${DateTime.now().millisecondsSinceEpoch}.wav',
  );

  final ok = await _kAudioChannel.invokeMethod<bool>(
    'convertAudioToWhisperWav',
    <String, String>{
      'inputPath': sourcePath,
      'outputPath': outPath,
    },
  );

  if (ok != true) {
    return null;
  }

  final outInfo = await readWavPcmInfo(outPath);
  if (!outInfo.ok) {
    if (kDebugMode) {
      debugPrint(
        'prepareLocalAudioForWhisper: çıktı doğrulanamadı: ${outInfo.error}',
      );
    }
    return null;
  }

  return WhisperAudioPrepared(
    wavPath: outPath,
    durationSeconds: outInfo.durationSeconds,
  );
}
