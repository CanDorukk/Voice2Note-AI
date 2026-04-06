import 'package:flutter/material.dart';

import 'package:voice_2_note_ai/app/theme_tokens.dart';

/// PDF / paylaşım önizleme ekranlarında transkript ve özet blokları.
class NotePreviewSectionCard extends StatelessWidget {
  const NotePreviewSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: tt.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DefaultTextStyle.merge(
              style: tt.bodyMedium?.copyWith(height: 1.4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
