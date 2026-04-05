import 'dart:io';
import 'dart:math' show min;
import 'dart:typed_data';

/// Whisper NDK yolunun beklediği: 16 kHz, mono, 16-bit PCM WAV.
class WavPcmInfo {
  const WavPcmInfo({
    required this.ok,
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.dataBytes,
    this.error,
  });

  final bool ok;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final int dataBytes;
  final String? error;

  int get durationSeconds {
    if (!ok || sampleRate <= 0 || channels <= 0 || bitsPerSample <= 0) {
      return 0;
    }
    final bytesPerSec = sampleRate * channels * (bitsPerSample ~/ 8);
    if (bytesPerSec <= 0) return 0;
    return (dataBytes / bytesPerSec).ceil();
  }
}

/// İlk [maxRead] bayt ile başlığı okur.
Future<WavPcmInfo> readWavPcmInfo(String path, {int maxRead = 512 * 1024}) async {
  final f = File(path);
  if (!await f.exists()) {
    return const WavPcmInfo(
      ok: false,
      sampleRate: 0,
      channels: 0,
      bitsPerSample: 0,
      dataBytes: 0,
      error: 'Dosya yok',
    );
  }

  final raf = await f.open();
  try {
    final len = await raf.length();
    final n = len < maxRead ? len : maxRead;
    await raf.setPosition(0);
    final buffer = await raf.read(n);
    return _parseWavBuffer(buffer, fileSize: len);
  } finally {
    await raf.close();
  }
}

WavPcmInfo _parseWavBuffer(Uint8List buffer, {required int fileSize}) {
  if (buffer.length < 12) {
    return const WavPcmInfo(
      ok: false,
      sampleRate: 0,
      channels: 0,
      bitsPerSample: 0,
      dataBytes: 0,
      error: 'Dosya çok kısa',
    );
  }

  if (String.fromCharCodes(buffer.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(buffer.sublist(8, 12)) != 'WAVE') {
    return const WavPcmInfo(
      ok: false,
      sampleRate: 0,
      channels: 0,
      bitsPerSample: 0,
      dataBytes: 0,
      error: 'Geçerli WAV başlığı yok',
    );
  }

  int? sampleRate;
  int? channels;
  int? bitsPerSample;
  int? audioFormat;
  var dataBytes = 0;

  var p = 12;
  while (p + 8 <= buffer.length) {
    final id = String.fromCharCodes(buffer.sublist(p, p + 4));
    final size = ByteData.sublistView(buffer, p + 4, p + 8)
        .getUint32(0, Endian.little);
    p += 8;
    final chunkEnd = min(p + size, buffer.length);

    if (id == 'fmt ' && p + 16 <= chunkEnd) {
      final bd = ByteData.sublistView(buffer, p, min(p + 32, chunkEnd));
      audioFormat = bd.getUint16(0, Endian.little);
      channels = bd.getUint16(2, Endian.little);
      sampleRate = bd.getUint32(4, Endian.little);
      if (bd.lengthInBytes >= 16) {
        bitsPerSample = bd.getUint16(14, Endian.little);
      }
    } else if (id == 'data') {
      dataBytes = size;
    }

    p += size;
    if (size.isOdd) p++;
  }

  if (dataBytes <= 0 && fileSize > 44) {
    dataBytes = fileSize - 44;
  }

  if (audioFormat == null) {
    return const WavPcmInfo(
      ok: false,
      sampleRate: 0,
      channels: 0,
      bitsPerSample: 0,
      dataBytes: 0,
      error: 'fmt chunk bulunamadı',
    );
  }

  if (audioFormat != 1) {
    return WavPcmInfo(
      ok: false,
      sampleRate: sampleRate ?? 0,
      channels: channels ?? 0,
      bitsPerSample: bitsPerSample ?? 0,
      dataBytes: dataBytes,
      error: 'Yalnızca PCM WAV desteklenir',
    );
  }

  if (sampleRate != 16000 || channels != 1 || bitsPerSample != 16) {
    return WavPcmInfo(
      ok: false,
      sampleRate: sampleRate ?? 0,
      channels: channels ?? 0,
      bitsPerSample: bitsPerSample ?? 0,
      dataBytes: dataBytes,
      error:
          'Beklenen: 16 kHz, mono, 16 bit. Bulunan: ${sampleRate ?? "?"} Hz, '
          '${channels ?? "?"} kanal, ${bitsPerSample ?? "?"} bit',
    );
  }

  return WavPcmInfo(
    ok: true,
    sampleRate: sampleRate!,
    channels: channels!,
    bitsPerSample: bitsPerSample!,
    dataBytes: dataBytes,
  );
}
