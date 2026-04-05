/// Türkçe metin normalizasyonu (arama ve metin madenciliği için).
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
