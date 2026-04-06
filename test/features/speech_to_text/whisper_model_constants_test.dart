import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_constants.dart';

void main() {
  test('kWhisperGgmlBaseQ5MinBytes is positive', () {
    expect(kWhisperGgmlBaseQ5MinBytes, greaterThan(0));
    expect(kWhisperGgmlBaseQ5MinBytes, 50 * 1024 * 1024);
  });

  test('kWhisperGgmlSmallQ5MinBytes base’den büyük', () {
    expect(kWhisperGgmlSmallQ5MinBytes, greaterThan(kWhisperGgmlBaseQ5MinBytes));
    expect(kWhisperGgmlSmallQ5MinBytes, 160 * 1024 * 1024);
  });

  test('kWhisperGgmlTinyQ5MinBytes en küçük eşik', () {
    expect(kWhisperGgmlTinyQ5MinBytes, lessThan(kWhisperGgmlBaseQ5MinBytes));
    expect(kWhisperGgmlTinyQ5MinBytes, 22 * 1024 * 1024);
  });
}
