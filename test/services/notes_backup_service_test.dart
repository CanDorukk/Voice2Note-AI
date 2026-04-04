import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/models/note_model.dart';

void main() {
  test('Not listesi JSON dizisi olarak kodlanabilir', () {
    final notes = [
      NoteModel(
        id: 1,
        audioPath: '/a.wav',
        transcript: 'merhaba',
        summary: 'özet',
        duration: 5,
        createdAt: 1700000000,
      ),
    ];
    final encoded = jsonEncode(notes.map((n) => n.toMap()).toList());
    final decoded = jsonDecode(encoded) as List<dynamic>;
    expect(decoded.length, 1);
    final m = decoded.first as Map<String, dynamic>;
    expect(m['transcript'], 'merhaba');
    expect(m['summary'], 'özet');
  });
}
