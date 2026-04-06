import 'package:flutter/material.dart';

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_constants.dart';

/// İndirilebilir Whisper ggml quantize varyantı (`ggerganov/whisper.cpp` ana dal).
enum WhisperGgmlModel {
  /// `ggml-base-q5_1.bin` — daha az yer, daha hızlı.
  base,

  /// `ggml-small-q5_1.bin` — daha doğru, çok daha büyük dosya.
  small,
}

extension WhisperGgmlModelX on WhisperGgmlModel {
  String get storageFileName => switch (this) {
        WhisperGgmlModel.base => 'ggml-base-q5_1.bin',
        WhisperGgmlModel.small => 'ggml-small-q5_1.bin',
      };

  /// Hugging Face `resolve/main/` dosya adı.
  String get huggingFaceFileName => storageFileName;

  int get minValidBytes => switch (this) {
        WhisperGgmlModel.base => kWhisperGgmlBaseQ5MinBytes,
        WhisperGgmlModel.small => kWhisperGgmlSmallQ5MinBytes,
      };

  /// Yerel geliştirme için yalnızca base asset olarak paketlenebilir.
  String? get bundledAssetPath => switch (this) {
        WhisperGgmlModel.base => 'assets/models/ggml-base-q5_1.bin',
        WhisperGgmlModel.small => null,
      };

  String get huggingFaceUrl =>
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$huggingFaceFileName';

  /// Kullanıcıya gösterilecek yaklaşık indirme boyutu (MB).
  int get approxDownloadMegabytes => switch (this) {
        WhisperGgmlModel.base => 60,
        WhisperGgmlModel.small => 190,
      };
}

/// Tanıtım / Hakkında: model ailesi seçimi (Base vs Small).
class WhisperGgmlModelSegmentedButton extends StatelessWidget {
  const WhisperGgmlModelSegmentedButton({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final WhisperGgmlModel selected;
  final ValueChanged<WhisperGgmlModel> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<WhisperGgmlModel>(
        segments: const [
          ButtonSegment<WhisperGgmlModel>(
            value: WhisperGgmlModel.base,
            label: Text('Base'),
            tooltip: 'Daha küçük paket, genelde daha hızlı',
          ),
          ButtonSegment<WhisperGgmlModel>(
            value: WhisperGgmlModel.small,
            label: Text('Small'),
            tooltip: 'Daha büyük paket, genelde daha doğru',
          ),
        ],
        selected: {selected},
        emptySelectionAllowed: false,
        showSelectedIcon: false,
        onSelectionChanged: enabled
            ? (Set<WhisperGgmlModel> next) {
                if (next.isEmpty) return;
                onChanged(next.single);
              }
            : null,
      ),
    );
  }
}
