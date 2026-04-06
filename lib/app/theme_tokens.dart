import 'package:flutter/material.dart';

/// Eski [Color.withOpacity] ile aynı mantık: son alfa ≈ `alpha * opacity` (0–255).
extension AppColorAlpha on Color {
  Color withAlphaFactor(double opacity) {
    final int newAlpha = (alpha * opacity).round().clamp(0, 255);
    return withAlpha(newAlpha);
  }
}

/// Görsel tutarlılık için köşe ve boşluk ölçeği (UI backlog ile uyumlu).
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
