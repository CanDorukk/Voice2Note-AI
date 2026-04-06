import 'package:flutter/material.dart';

import 'package:voice_2_note_ai/app/theme_tokens.dart';

/// Hakkında diyaloglarında bölüm başlığı ve ince ayırıcı.
class AboutSectionHeader extends StatelessWidget {
  const AboutSectionHeader(
    this.title, {
    super.key,
    this.compactTop = false,
  });

  final String title;

  /// İlk bölümde üst boşluğu azaltır (giriş paragrafının hemen altı).
  final bool compactTop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        top: compactTop ? AppSpacing.md : AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withAlphaFactor(0.55),
          ),
        ],
      ),
    );
  }
}
