import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_service.dart';

void main() {
  test('transcribeTimeoutForAudioSeconds: ~5 dk ses yaklaşık 45 dk tavan', () {
    final t = WhisperService.transcribeTimeoutForAudioSeconds(317);
    expect(t.inMinutes, 45);
  });

  test('transcribeTimeoutForAudioSeconds: kısa ses min 15 dk', () {
    final t = WhisperService.transcribeTimeoutForAudioSeconds(30);
    expect(t.inMinutes, 15);
  });

  test('transcribeTimeoutForAudioSeconds: uzun ses max 45 dk', () {
    final t = WhisperService.transcribeTimeoutForAudioSeconds(3600);
    expect(t.inMinutes, 45);
  });
}
