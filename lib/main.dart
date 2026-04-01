import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:voice_2_note_ai/app/app.dart';
import 'package:voice_2_note_ai/database/database_helper.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
  await WhisperModelService.instance.ensureReady();
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = 'Voice2 Note AI';
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await WhisperService().warmup();
  });
}
