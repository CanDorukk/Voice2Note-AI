import 'package:flutter/foundation.dart';

/// Summary servisi.
///
/// Bu adımda TextRank entegrasyonu henüz yok; dönen değer dummy'dir.
/// Sonraki adımda bu sınıfın içini TextRank ile dolduracağız.
class SummaryService {
  Future<String> summarize(String transcript) async {
    if (kDebugMode) {
      debugPrint('SummaryService.summarize transcript length: ${transcript.length}');
    }
    final trimmed = transcript.trim();
    if (trimmed.isEmpty) return 'Dummy summary (TextRank eklenecek)';
    return 'Dummy summary (TextRank eklenecek): ${trimmed.length > 60 ? trimmed.substring(0, 60) : trimmed}';
  }
}
