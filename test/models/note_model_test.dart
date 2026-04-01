import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

void main() {
  group('NoteModel', () {
    test('toMap round-trips with fromMap', () {
      const original = NoteModel(
        id: 42,
        audioPath: '/path/audio.wav',
        transcript: 'merhaba',
        summary: 'özet',
        duration: 11,
        createdAt: 1700000000,
      );
      final map = original.toMap();
      final restored = NoteModel.fromMap(map);

      expect(restored.id, 42);
      expect(restored.audioPath, '/path/audio.wav');
      expect(restored.transcript, 'merhaba');
      expect(restored.summary, 'özet');
      expect(restored.duration, 11);
      expect(restored.createdAt, 1700000000);
    });

    test('fromMap uses defaults for missing keys', () {
      final note = NoteModel.fromMap(<String, Object?>{
        NoteModel.colId: null,
      });
      expect(note.id, isNull);
      expect(note.audioPath, '');
      expect(note.transcript, '');
      expect(note.summary, '');
      expect(note.duration, 0);
      expect(note.createdAt, 0);
    });
  });
}
