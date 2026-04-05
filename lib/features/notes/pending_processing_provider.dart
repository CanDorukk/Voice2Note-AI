import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arka planda transkript bekleyen kayıtlar (henüz DB satırı yok).
class PendingProcessingItem {
  const PendingProcessingItem({
    required this.id,
    required this.audioPath,
    required this.durationSeconds,
    required this.startedAtMs,
    this.displayLabel = 'Ses kaydı',
  });

  final String id;
  final String audioPath;
  final int durationSeconds;
  final int startedAtMs;

  /// Liste satırında gösterilir (ör. dosya içe aktarma).
  final String displayLabel;
}

class PendingProcessingNotifier extends StateNotifier<List<PendingProcessingItem>> {
  PendingProcessingNotifier() : super(const []);

  void add({
    required String audioPath,
    required int durationSeconds,
    String displayLabel = 'Ses kaydı',
  }) {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${audioPath.hashCode}';
    state = [
      PendingProcessingItem(
        id: id,
        audioPath: audioPath,
        durationSeconds: durationSeconds,
        startedAtMs: DateTime.now().millisecondsSinceEpoch,
        displayLabel: displayLabel,
      ),
      ...state,
    ];
  }

  void removeByAudioPath(String audioPath) {
    state = state.where((e) => e.audioPath != audioPath).toList();
  }
}

final pendingProcessingProvider =
    StateNotifierProvider<PendingProcessingNotifier, List<PendingProcessingItem>>((ref) {
  return PendingProcessingNotifier();
});
