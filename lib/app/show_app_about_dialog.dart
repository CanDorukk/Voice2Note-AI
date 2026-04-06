import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:voice_2_note_ai/features/notes/turkish_search_synonyms_section.dart';
import 'package:voice_2_note_ai/features/speech_to_text/remote_transcribe_settings_section.dart';

/// Hakkında iletişim kutusu (Notlar AppBar ve sunucu yönlendirmesi için ortak).
Future<void> showAppAboutDialog(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  final rootContext = context;
  showAboutDialog(
    context: rootContext,
    applicationName: 'Voice2 Note AI',
    applicationVersion: '${info.version} (${info.buildNumber})',
    applicationLegalese: 'Özet cihazda; transkript sunucuda',
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'Özet bu cihazda üretilir. Transkript için kayıtlı sunucuya '
          'bağlanılır (aynı Wi‑Fi veya erişilebilir ağ).',
        ),
      ),
      const RemoteTranscribeSettingsSection(),
      const TurkishSearchSynonymsSection(),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            Navigator.of(rootContext).pop();
            showLicensePage(
              context: rootContext,
              applicationName: 'Voice2 Note AI',
              applicationVersion: '${info.version}+${info.buildNumber}',
            );
          },
          child: const Text('Lisanslar'),
        ),
      ),
    ],
  );
}
