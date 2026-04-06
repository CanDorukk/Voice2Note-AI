import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_ggml_model.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_constants.dart';

void main() {
  test('WhisperGgmlModel dosya adları ve HF URL', () {
    expect(WhisperGgmlModel.base.storageFileName, 'ggml-base-q5_1.bin');
    expect(WhisperGgmlModel.small.storageFileName, 'ggml-small-q5_1.bin');
    expect(
      WhisperGgmlModel.base.huggingFaceUrl,
      contains('ggml-base-q5_1.bin'),
    );
    expect(
      WhisperGgmlModel.small.huggingFaceUrl,
      contains('ggml-small-q5_1.bin'),
    );
  });

  test('minValidBytes sıralaması', () {
    expect(
      WhisperGgmlModel.small.minValidBytes,
      greaterThan(WhisperGgmlModel.base.minValidBytes),
    );
    expect(WhisperGgmlModel.base.minValidBytes, kWhisperGgmlBaseQ5MinBytes);
  });

  test('Small modelin asset yolu yok', () {
    expect(WhisperGgmlModel.base.bundledAssetPath, isNotNull);
    expect(WhisperGgmlModel.small.bundledAssetPath, isNull);
  });
}
