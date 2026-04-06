import 'package:flutter/material.dart';

/// Görsel dil: [Icons] içinde **`*_rounded`** varyantları (aynı çizgi kalınlığı).
/// Yeni ikon eklerken mümkünse `_rounded` sonekini kullan.
abstract final class AppIcons {
  AppIcons._();

  /// Not listesi / not ile ilişkili yerler
  static const IconData note = Icons.sticky_note_2_rounded;

  /// Kayıt FAB ve mikrofon aksiyonu
  static const IconData record = Icons.mic_rounded;

  /// Paylaşım (metin veya dosya)
  static const IconData share = Icons.share_rounded;

  /// PDF oluşturma / önizleme
  static const IconData pdf = Icons.picture_as_pdf_rounded;

  /// Transkript bölümü (okuma / metin)
  static const IconData transcriptSection = Icons.mic_none_rounded;

  /// Özet bölümü
  static const IconData summarySection = Icons.lightbulb_rounded;
}
