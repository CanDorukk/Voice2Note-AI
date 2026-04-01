import 'package:flutter/foundation.dart';
import 'package:voice_2_note_ai/features/summary/textrank_algorithm.dart';

/// [compute] ile ayrı isolate'ta çalışır (uzun metinde UI thread'i yormasın).
String _textrankSummarize(String transcript) {
  return TextRankAlgorithm().summarize(transcript);
}

/// Summary servisi.
///
class SummaryService {
  Future<String> summarize(String transcript) async {
    if (kDebugMode) {
      debugPrint('SummaryService.summarize transcript length: ${transcript.length}');
    }

    return compute(_textrankSummarize, transcript);
  }
}
