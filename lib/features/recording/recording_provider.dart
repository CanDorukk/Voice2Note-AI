import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/services/recording_service.dart';

/// Kayıt ekranı state: boşta / kayıt sırasında süre / son kaydedilen path.
class RecordingState {
  const RecordingState({
    this.isRecording = false,
    this.durationSeconds = 0,
    this.lastSavedPath,
  });

  final bool isRecording;
  final int durationSeconds;
  final String? lastSavedPath;

  RecordingState copyWith({
    bool? isRecording,
    int? durationSeconds,
    String? lastSavedPath,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      lastSavedPath: lastSavedPath ?? this.lastSavedPath,
    );
  }
}

class RecordingNotifier extends StateNotifier<RecordingState> {
  RecordingNotifier(this._service) : super(const RecordingState());

  final RecordingService _service;
  Timer? _timer;

  Future<void> startRecording() async {
    if (state.isRecording) return;
    final ok = await _service.start();
    if (!ok) return;
    state = state.copyWith(isRecording: true, durationSeconds: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });
  }

  Future<String?> stopRecording() async {
    if (!state.isRecording) return null;
    _timer?.cancel();
    _timer = null;
    final path = await _service.stop();
    state = state.copyWith(isRecording: false, durationSeconds: 0, lastSavedPath: path);
    return path;
  }

  void clearLastPath() {
    state = state.copyWith(lastSavedPath: null);
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final service = RecordingService();
  ref.onDispose(service.dispose);
  return service;
});

final recordingProvider =
    StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  return RecordingNotifier(ref.watch(recordingServiceProvider));
});
