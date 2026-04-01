import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_2_note_ai/app/theme_mode_menu_button.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Tema menüsü Sistem, Açık, Koyu seçeneklerini gösterir', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                ThemeModeMenuButton(),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tema'));
    await tester.pumpAndSettle();

    expect(find.text('Sistem'), findsOneWidget);
    expect(find.text('Açık'), findsOneWidget);
    expect(find.text('Koyu'), findsOneWidget);
  });
}
