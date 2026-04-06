import 'package:voice_2_note_ai/utils/turkish_search_synonyms.dart';

/// Türkçe metin normalizasyonu (arama ve özet için).
///
/// Dart `toLowerCase()` Türkçe `İ`/`I` kurallarını tam uygulamaz; sorgu ile metni
/// aynı şekilde katlayarak eşleşmeyi iyileştiririz.
String foldTurkishForSearch(String input) {
  final sb = StringBuffer();
  for (final r in input.runes) {
    final c = String.fromCharCode(r);
    if (c == 'İ') {
      sb.write('i');
    } else if (c == 'I') {
      sb.write('ı');
    } else {
      sb.write(c.toLowerCase());
    }
  }
  return sb.toString();
}

/// Yaygın birleşik yazımları arama için ayıklı biçime çeker (büyük/küçük harf duyarsız).
/// Uzun eşleşmeler önce uygulanır.
String _applyCommonTurkishWordSpacing(String input) {
  var s = input;
  const pairs = <(String, String)>[
    ('birşeyleri', 'bir şeyleri'),
    ('birşeyler', 'bir şeyler'),
    ('birşeyi', 'bir şeyi'),
    ('birşey', 'bir şey'),
    ('herşeyi', 'her şeyi'),
    ('herşey', 'her şey'),
    ('hiçbirşeyde', 'hiçbir şeyde'),
    ('hiçbirşeyi', 'hiçbir şeyi'),
    ('hiçbirşey', 'hiçbir şey'),
    ('herhangibir', 'herhangi bir'),
  ];
  for (final p in pairs) {
    s = s.replaceAll(
      RegExp(RegExp.escape(p.$1), caseSensitive: false),
      p.$2,
    );
  }
  return s;
}

/// Fransızca kökenli bazı harfler (â, ê) aramada eşlenir.
String _foldLatinExtendedForSearch(String foldedLower) {
  return foldedLower
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('à', 'a')
      .replaceAll('á', 'a')
      .replaceAll('ê', 'e')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('û', 'u')
      .replaceAll('ù', 'u');
}

/// Arama ve metin madenciliği için tek giriş noktası.
///
/// Boşlukları sadeleştirir, görünmez karakterleri atar, yaygın birleşik yazımları
/// düzeltir, Türkçe i/I/İ katlaması ve Latin uzantı harflerini eşler.
///
/// [useSearchSynonyms] true ise [synonymLookup] ile tam kelime eş anlamlı kanonik
/// biçime çekilir (not listesi araması için). Özet (TextRank) için varsayılan false.
String normalizeForTurkishSearch(
  String input, {
  bool useSearchSynonyms = false,
  Map<String, String>? synonymLookup,
}) {
  var s = input.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  s = _applyCommonTurkishWordSpacing(s);
  s = foldTurkishForSearch(s);
  s = _foldLatinExtendedForSearch(s);
  if (useSearchSynonyms) {
    final lookup = synonymLookup ?? kBuiltInTurkishSearchSynonymLookup;
    s = applyTurkishSearchSynonyms(s, lookup);
  }
  return s;
}
