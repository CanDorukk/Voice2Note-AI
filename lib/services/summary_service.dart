import 'package:flutter/foundation.dart';
import 'package:voice_2_note_ai/features/summary/textrank_algorithm.dart';

/// Summary servisi.
///
class SummaryService {
  Future<String> summarize(String transcript) async {
    if (kDebugMode) {
      debugPrint('SummaryService.summarize transcript length: ${transcript.length}');
    }

    // TextRank algoritması (offline, saf Dart).
    final algo = TextRankAlgorithm();
    final summary = algo.summarize(transcript);
    return summary;
  }
}
