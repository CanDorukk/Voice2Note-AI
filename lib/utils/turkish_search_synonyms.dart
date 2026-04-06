// Türkçe not araması: eş anlamlı kanonik kelime eşlemesi ([normalizeForTurkishSearch] sonrası tam kelime).

/// (kanonik kelime, eş anlamlı biçimler — hepsi küçük harf / fold ile uyumlu).
const List<(String, Set<String>)> kBuiltInTurkishSearchSynonymGroups = [
  ('doktor', {'doktor', 'hekim', 'dr'}),
  ('araba', {'araba', 'otomobil', 'araç'}),
  ('not', {'not', 'kayıt'}),
  ('telefon', {'telefon', 'cep', 'mobil'}),
  ('ev', {'ev', 'konut'}),
  ('para', {'para', 'ücret', 'bedel'}),
  ('hastane', {'hastane', 'hospital'}),
  ('türkçe', {'türkçe', 'turkce'}),
  ('üniversite', {'üniversite', 'universite'}),
];

/// Her grupta [kBuiltInTurkishSearchSynonymGroups] içindeki kanonik kelimeye eşler.
Map<String, String> buildBuiltInTurkishSearchSynonymLookup() {
  final out = <String, String>{};
  for (final row in kBuiltInTurkishSearchSynonymGroups) {
    final canon = row.$1;
    for (final w in row.$2) {
      out[w] = canon;
    }
  }
  return out;
}

/// Uygulama açılışında bir kez; kullanıcı sözlüğü ile birleştirmek için.
final Map<String, String> kBuiltInTurkishSearchSynonymLookup =
    buildBuiltInTurkishSearchSynonymLookup();

/// Kullanıcı eşlemeleri yerleşik üzerine yazar (aynı anahtar için).
Map<String, String> mergeTurkishSearchSynonymMaps(
  Map<String, String> user,
) {
  return {...kBuiltInTurkishSearchSynonymLookup, ...user};
}

/// [normalized] zaten [normalizeForTurkishSearch] ile üretilmiş olmalı.
/// [lookup] birleştirilmiş sözlük (yerleşik + kullanıcı).
String applyTurkishSearchSynonyms(
  String normalized,
  Map<String, String> lookup,
) {
  if (lookup.isEmpty) return normalized;
  final buf = StringBuffer();
  var last = 0;
  for (final m in RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(normalized)) {
    buf.write(normalized.substring(last, m.start));
    final tok = m.group(0)!;
    buf.write(lookup[tok] ?? tok);
    last = m.end;
  }
  buf.write(normalized.substring(last));
  return buf.toString();
}
