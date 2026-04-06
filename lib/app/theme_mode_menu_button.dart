import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/app/theme_mode_provider.dart';

/// Notlar ve kayıt gibi ekranlarda tekrar kullanılan tema seçim menüsü.
class ThemeModeMenuButton extends ConsumerWidget {
  const ThemeModeMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Tema',
      icon: Icon(_themeMenuIcon(themeMode)),
      onSelected: (mode) {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: _themeMenuRow(
            themeMode == ThemeMode.system,
            Icons.brightness_auto_rounded,
            'Sistem',
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: _themeMenuRow(
            themeMode == ThemeMode.light,
            Icons.light_mode_rounded,
            'Açık',
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: _themeMenuRow(
            themeMode == ThemeMode.dark,
            Icons.dark_mode_rounded,
            'Koyu',
          ),
        ),
      ],
    );
  }
}

IconData _themeMenuIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return Icons.light_mode_rounded;
    case ThemeMode.dark:
      return Icons.dark_mode_rounded;
    case ThemeMode.system:
      return Icons.brightness_auto_rounded;
  }
}

Widget _themeMenuRow(bool selected, IconData icon, String label) {
  return Row(
    children: [
      SizedBox(
        width: 28,
        child: selected ? const Icon(Icons.check_rounded, size: 20) : null,
      ),
      Icon(icon, size: 20),
      const SizedBox(width: 10),
      Text(label),
    ],
  );
}
