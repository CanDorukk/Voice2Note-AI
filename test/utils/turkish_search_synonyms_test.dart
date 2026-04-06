import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/services/turkish_search_synonym_prefs.dart';
import 'package:voice_2_note_ai/utils/turkish_search_synonyms.dart';
import 'package:voice_2_note_ai/utils/turkish_text.dart';

void main() {
  group('mergeTurkishSearchSynonymMaps', () {
    test('kullanıcı yerleşik üzerine yazar', () {
      final m = mergeTurkishSearchSynonymMaps({'doktor': 'hekim'});
      expect(m['doktor'], 'hekim');
    });
  });

  group('applyTurkishSearchSynonyms', () {
    test('tam kelime eşlenir', () {
      final lookup = mergeTurkishSearchSynonymMaps({});
      final s = applyTurkishSearchSynonyms('randevu hekim ile', lookup);
      expect(s, contains('doktor'));
      expect(s, isNot(contains('hekim')));
    });
  });

  group('normalizeForTurkishSearch + synonyms', () {
    test('hekim araması doktor geçen metinde bulunur', () {
      final lookup = mergeTurkishSearchSynonymMaps({});
      final note = normalizeForTurkishSearch(
        'Bugün doktor ile görüştüm',
        useSearchSynonyms: true,
        synonymLookup: lookup,
      );
      final q = normalizeForTurkishSearch(
        'hekim',
        useSearchSynonyms: true,
        synonymLookup: lookup,
      );
      expect(note.contains(q), isTrue);
    });
  });

  group('parseUserTurkishSearchSynonymLines', () {
    test('satır ve yorum', () {
      final m = parseUserTurkishSearchSynonymLines('''
# yorum
foo=bar
  a  =  b  
''');
      expect(m['foo'], 'bar');
      expect(m['a'], 'b');
    });
  });
}
