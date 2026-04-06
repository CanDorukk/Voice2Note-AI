import 'dart:math' show max;

import 'package:just_audio/just_audio.dart';

/// Yerel ses dosyası süresi (saniye). Okunamazsa en az [fallbackSeconds] döner.
Future<int> probeAudioDurationSeconds(
  String path, {
  int fallbackSeconds = 60,
}) async {
  final player = AudioPlayer();
  try {
    final d = await player.setFilePath(path);
    if (d != null && d > Duration.zero) {
      return max(1, d.inSeconds);
    }
    return max(1, fallbackSeconds);
  } catch (_) {
    return max(1, fallbackSeconds);
  } finally {
    await player.dispose();
  }
}
