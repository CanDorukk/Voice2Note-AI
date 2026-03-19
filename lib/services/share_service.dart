import 'package:share_plus/share_plus.dart';

/// Paylaşım servisi (share_plus).
class ShareService {
  Future<void> _shareText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await Share.share(trimmed);
  }

  /// Transcript metnini paylaş.
  Future<void> shareTranscript(String transcript) async {
    await _shareText(transcript);
  }

  /// Özet metnini paylaş.
  Future<void> shareSummary(String summary) async {
    await _shareText(summary);
  }

  /// Transcript + Özet birlikte paylaş.
  Future<void> shareTranscriptAndSummary({
    required String transcript,
    required String summary,
  }) async {
    final t = transcript.trim();
    final s = summary.trim();
    final buffer = StringBuffer();
    if (t.isNotEmpty) buffer.writeln(t);
    if (s.isNotEmpty) buffer.writeln('\n---\n$s');
    final text = buffer.toString().trim();
    await _shareText(text);
  }
}
