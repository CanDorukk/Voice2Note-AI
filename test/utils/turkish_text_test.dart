import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/utils/turkish_text.dart';

void main() {
  group('normalizeForTurkishSearch', () {
    test('İ/I/ı fold', () {
      expect(normalizeForTurkishSearch('İSTANBUL'), 'istanbul');
      expect(normalizeForTurkishSearch('ISTANBUL'), 'ıstanbul');
    });

    test('birleşik yazım ayrıştırma', () {
      expect(
        normalizeForTurkishSearch('birşey söyledi'),
        contains('bir şey'),
      );
      expect(
        normalizeForTurkishSearch('HerŞey tamam'),
        contains('her şey'),
      );
    });

    test('Latin uzantı', () {
      expect(normalizeForTurkishSearch('café'), 'cafe');
      expect(normalizeForTurkishSearch('Âli'), 'ali');
    });
  });
}
