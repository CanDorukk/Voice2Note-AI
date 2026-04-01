import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_2_note_ai/app/theme_mode_provider.dart';

void main() {
  group('themeModeFromPreference', () {
    test('null veya bilinmeyen → system', () {
      expect(themeModeFromPreference(null), ThemeMode.system);
      expect(themeModeFromPreference(''), ThemeMode.system);
      expect(themeModeFromPreference('other'), ThemeMode.system);
    });

    test('light / dark / system string', () {
      expect(themeModeFromPreference('light'), ThemeMode.light);
      expect(themeModeFromPreference('dark'), ThemeMode.dark);
      expect(themeModeFromPreference('system'), ThemeMode.system);
    });
  });

  group('themeModeToPreference round-trip', () {
    test('tüm ThemeMode değerleri', () {
      for (final mode in ThemeMode.values) {
        expect(
          themeModeFromPreference(themeModeToPreference(mode)),
          mode,
        );
      }
    });
  });
}
