import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_service.dart';

void main() {
  test('transcribeTimeoutForAudioSeconds: ~5 dk ses ~ses×3 sn (tavan 2 saat)', () {
    final t = WhisperService.transcribeTimeoutForAudioSeconds(317);
    expect(t.inSeconds, 317 * 3);
  });

  test('transcribeTimeoutForAudioSeconds: kısa ses min 300 sn', () {
    final t = WhisperService.transcribeTimeoutForAudioSeconds(30);
    expect(t.inSeconds, 300);
  });

  test('transcribeTimeoutForAudioSeconds: bilinmeyen varsayılan 45 dk', () {
    final t = WhisperService.transcribeTimeoutForAudioSeconds(null);
    expect(t.inMinutes, 45);
  });
}
