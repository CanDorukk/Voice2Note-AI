import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voice_2_note_ai/services/turkish_search_synonym_prefs.dart';
import 'package:voice_2_note_ai/utils/turkish_search_synonyms.dart';

/// Hakkında’dan kaydedilen ham metin + ayrıştırılmış eşlemeler.
final userSearchSynonymsBundleProvider =
    FutureProvider<({String raw, Map<String, String> map})>((ref) async {
  final raw = await TurkishSearchSynonymPrefs.loadRaw();
  final map = parseUserTurkishSearchSynonymLines(raw);
  return (raw: raw, map: map);
});

/// Not aramasında kullanılacak birleşik sözlük (yerleşik + kullanıcı).
final turkishSearchLookupProvider = Provider<Map<String, String>>((ref) {
  final user = ref.watch(userSearchSynonymsBundleProvider).maybeWhen(
        data: (b) => b.map,
        orElse: () => <String, String>{},
      );
  return mergeTurkishSearchSynonymMaps(user);
});
