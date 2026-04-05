// ignore_for_file: avoid_print

import 'dart:math';

import 'package:voice_2_note_ai/utils/turkish_text.dart';

/// Offline extractive summarization using TextRank.
///
/// Not: Bu implementasyon saf Dart ile çalışır (ekstra AI/API gerektirmez).
class TextRankAlgorithm {
  /// Türkçe bağlaç/zamir vb. — skorda gürültüyü azaltır.
  static const Set<String> _trStopwords = {
    've', 'veya', 'ile', 'için', 'gibi', 'kadar', 'bir', 'bu', 'şu', 'o',
    'ben', 'sen', 'biz', 'siz', 'onlar', 'de', 'da', 'ki', 'mi', 'mı', 'mu',
    'mü', 'çok', 'daha', 'en', 'her', 'hiç', 'ne', 'neden', 'nasıl', 'var',
    'yok', 'ise', 'ama', 'fakat', 'ancak', 'hem', 'sonra', 'önce', 'şimdi',
    'böyle', 'şöyle', 'öyle', 'burada', 'orada', 'kendi', 'kendine', 'bazı',
    'tüm', 'bütün', 'herhangi', 'birkaç', 'değil', 'olan', 'olarak', 'üzere',
    'rağmen', 'karşı', 'göre', 'önceki', 'şey', 'biri', 'bunu',
    'buna', 'onu', 'ona', 'şunu',
  };

  /// Transkript içinden en önemli cümleleri seçip özet döndürür.
  ///
  /// [maxSentences] null ise otomatik bir değer hesaplanır.
  String summarize(
    String transcript, {
    int? maxSentences,
  }) {
    final text = transcript.trim();
    if (text.isEmpty) return '';

    final sentences = _splitSentences(text);
    if (sentences.isEmpty) return text;
    if (sentences.length <= 1) return sentences.first;

    final autoCap = min(10, sentences.length);
    final normalizedMaxSentences = maxSentences ??
        max(1, (sentences.length / 4).ceil()).clamp(1, autoCap);

    // Çok kısa metinlerde aşırı işlem yapma.
    if (normalizedMaxSentences >= sentences.length) {
      return sentences.join(' ');
    }

    // TF-IDF vektörlerini üret.
    final vocab = <String>{};
    final tokenized = <List<String>>[];
    for (final s in sentences) {
      final tokens = _tokenize(s);
      tokenized.add(tokens);
      vocab.addAll(tokens);
    }
    if (vocab.isEmpty) return text;

    final df = <String, int>{};
    for (final tokens in tokenized) {
      final seen = <String>{};
      for (final t in tokens) {
        if (seen.add(t)) {
          df[t] = (df[t] ?? 0) + 1;
        }
      }
    }

    final n = sentences.length;
    final idf = <String, double>{};
    for (final term in vocab) {
      final dfi = df[term] ?? 0;
      idf[term] = log((n + 1) / (dfi + 1)) + 1.0;
    }

    // TF-IDF matrisini (sparse) oluştur.
    final tfidf = <Map<String, double>>[];
    final norms = <double>[];
    for (final tokens in tokenized) {
      final tf = <String, int>{};
      for (final t in tokens) {
        tf[t] = (tf[t] ?? 0) + 1;
      }

      final total = tokens.length;
      final vec = <String, double>{};
      double normSq = 0.0;
      for (final entry in tf.entries) {
        final term = entry.key;
        final freq = entry.value;
        final weight = (freq / total) * (idf[term] ?? 0);
        vec[term] = weight;
        normSq += weight * weight;
      }
      tfidf.add(vec);
      norms.add(sqrt(normSq));
    }

    // Benzerlik matrisi (cosine) + PageRank.
    final sim = List.generate(n, (_) => List<double>.filled(n, 0.0));
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        sim[i][j] = _cosineSimilarity(
          tfidf[i],
          tfidf[j],
          norms[i],
          norms[j],
        );
      }
    }

    const damping = 0.85;
    final scores = List<double>.filled(n, 1.0 / n);

    // İterasyon.
    for (var iter = 0; iter < 60; iter++) {
      final next = List<double>.filled(n, (1.0 - damping) / n);
      for (var i = 0; i < n; i++) {
        final outSum = sim[i].fold<double>(0.0, (acc, w) => acc + w);
        if (outSum == 0) continue;

        for (var j = 0; j < n; j++) {
          final weight = sim[i][j];
          if (weight == 0) continue;
          next[j] += damping * scores[i] * (weight / outSum);
        }
      }

      var maxDelta = 0.0;
      for (var i = 0; i < n; i++) {
        maxDelta = max(maxDelta, (next[i] - scores[i]).abs());
        scores[i] = next[i];
      }
      if (maxDelta < 0.0001) break;
    }

    // En yüksek skorlu cümleleri seç (orijinal sırayı koru).
    final indexed = <int, double>{};
    for (var i = 0; i < n; i++) {
      indexed[i] = scores[i];
    }
    final sortedByScore = indexed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final selected = sortedByScore
        .take(normalizedMaxSentences)
        .map((e) => e.key)
        .toSet();

    final ordered = <String>[];
    for (var i = 0; i < n; i++) {
      if (selected.contains(i)) ordered.add(sentences[i].trim());
    }

    return ordered.join(' ');
  }

  List<String> _splitSentences(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = normalized
        .split(RegExp(r'(?:\.{3,}|[.!?…;]+)\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return parts.where((s) {
      final t = _tokenize(s);
      return t.length >= 2 || s.runes.length >= 24;
    }).toList();
  }

  List<String> _tokenize(String sentence) {
    final lower = normalizeForTurkishSearch(sentence);
    final raw = RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(lower)
        .map((m) => m.group(0)!)
        .toList();
    final filtered = raw.where((t) => !_trStopwords.contains(t)).toList();
    return filtered.isNotEmpty ? filtered : raw;
  }

  double _cosineSimilarity(
    Map<String, double> a,
    Map<String, double> b,
    double normA,
    double normB,
  ) {
    if (normA == 0 || normB == 0) return 0;

    // Sparse dot product:
    // Küçük olan map’te dolaş.
    final small = a.length <= b.length ? a : b;
    final large = a.length <= b.length ? b : a;
    double dot = 0.0;
    for (final entry in small.entries) {
      final w = large[entry.key];
      if (w != null) dot += entry.value * w;
    }
    return dot / (normA * normB);
  }
}

