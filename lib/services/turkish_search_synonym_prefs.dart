import 'package:shared_preferences/shared_preferences.dart';

import 'package:voice_2_note_ai/core/constants/app_constants.dart';
import 'package:voice_2_note_ai/utils/turkish_text.dart';

/// Hakkında’da saklanan çok satırlı `sol=sağ` eşleşmelerini ayrıştırır.
/// `#` ile başlayan satırlar ve boş satırlar yok sayılır.
Map<String, String> parseUserTurkishSearchSynonymLines(String raw) {
  final out = <String, String>{};
  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final eq = t.indexOf('=');
    if (eq <= 0) continue;
    final left = t.substring(0, eq).trim();
    final right = t.substring(eq + 1).trim();
    if (left.isEmpty || right.isEmpty) continue;
    final key = _firstWordTokenForSynonym(left);
    final val = _firstWordTokenForSynonym(right);
    if (key == null || val == null) continue;
    out[key] = val;
  }
  return out;
}

String? _firstWordTokenForSynonym(String s) {
  final n = normalizeForTurkishSearch(s, useSearchSynonyms: false);
  final m = RegExp(r'[\p{L}\p{N}]+', unicode: true).firstMatch(n);
  return m?.group(0);
}

class TurkishSearchSynonymPrefs {
  TurkishSearchSynonymPrefs._();

  static Future<String> loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.turkishSearchUserSynonymsRawKey) ?? '';
  }

  static Future<void> saveRaw(String raw) async {
    final prefs = await SharedPreferences.getInstance();
    final t = raw.trim();
    if (t.isEmpty) {
      await prefs.remove(AppConstants.turkishSearchUserSynonymsRawKey);
    } else {
      await prefs.setString(AppConstants.turkishSearchUserSynonymsRawKey, raw);
    }
  }
}
