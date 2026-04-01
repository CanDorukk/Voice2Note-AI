import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_constants.dart';

void main() {
  test('kWhisperGgmlTinyQ5MinBytes is positive', () {
    expect(kWhisperGgmlTinyQ5MinBytes, greaterThan(0));
    expect(kWhisperGgmlTinyQ5MinBytes, 25 * 1024 * 1024);
  });
}
