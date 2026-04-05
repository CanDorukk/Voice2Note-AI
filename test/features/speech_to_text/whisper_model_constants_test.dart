import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_constants.dart';

void main() {
  test('kWhisperGgmlBaseQ5MinBytes is positive', () {
    expect(kWhisperGgmlBaseQ5MinBytes, greaterThan(0));
    expect(kWhisperGgmlBaseQ5MinBytes, 50 * 1024 * 1024);
  });
}
