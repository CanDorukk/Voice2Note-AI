import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/app/app.dart';
import 'package:voice_2_note_ai/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
