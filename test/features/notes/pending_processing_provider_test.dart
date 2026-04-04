import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/features/notes/pending_processing_provider.dart';

void main() {
  test('add sonrası liste dolu; removeByAudioPath ile boşalır', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pendingProcessingProvider), isEmpty);

    container.read(pendingProcessingProvider.notifier).add(
          audioPath: '/tmp/test.wav',
          durationSeconds: 12,
        );

    final list = container.read(pendingProcessingProvider);
    expect(list.length, 1);
    expect(list.first.audioPath, '/tmp/test.wav');
    expect(list.first.durationSeconds, 12);

    container.read(pendingProcessingProvider.notifier).removeByAudioPath('/tmp/test.wav');
    expect(container.read(pendingProcessingProvider), isEmpty);
  });

  test('aynı path iki kez remove güvenli', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(pendingProcessingProvider.notifier).add(
          audioPath: '/a.wav',
          durationSeconds: 1,
        );
    container.read(pendingProcessingProvider.notifier).removeByAudioPath('/a.wav');
    container.read(pendingProcessingProvider.notifier).removeByAudioPath('/a.wav');
    expect(container.read(pendingProcessingProvider), isEmpty);
  });
}
