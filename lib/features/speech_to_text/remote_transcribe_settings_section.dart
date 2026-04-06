import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:voice_2_note_ai/app/about_section_header.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';

/// Hakkında: transkript sunucusu (PC / VPS) adresi ve isteğe bağlı API anahtarı.
class RemoteTranscribeSettingsSection extends StatefulWidget {
  const RemoteTranscribeSettingsSection({super.key});

  @override
  State<RemoteTranscribeSettingsSection> createState() =>
      _RemoteTranscribeSettingsSectionState();
}

class _RemoteTranscribeSettingsSectionState
    extends State<RemoteTranscribeSettingsSection> {
  bool _loading = true;
  bool _savedHint = false;
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kIsWeb || !Platform.isAndroid) {
      _loading = false;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final url = await RemoteTranscribeSettings.getBaseUrl();
    final key = await RemoteTranscribeSettings.getApiKey();
    if (!mounted) return;
    setState(() {
      if (url != null) {
        _urlCtrl.text = url;
      }
      if (key != null) {
        _apiKeyCtrl.text = key;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await RemoteTranscribeSettings.setBaseUrl(_urlCtrl.text);
    await RemoteTranscribeSettings.setApiKey(_apiKeyCtrl.text);
    if (!mounted) return;
    setState(() => _savedHint = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _savedHint = false);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ayarlar yükleniyor…',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AboutSectionHeader('Transkript sunucusu', compactTop: true),
        Text(
          'Ses metne bilgisayarınızda veya VPS’te çalışan API ile dönüştürülür. '
          'Kök adresi girin (örn. http://192.168.1.10:8787). Kurulum: docs/pc_whisper_sunucu.md',
          style: textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _urlCtrl,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Sunucu kök adresi',
            hintText: 'http://192.168.1.10:8787',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _apiKeyCtrl,
          obscureText: true,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'API anahtarı (isteğe bağlı)',
            hintText: 'Sunucuda V2N_API_KEY ayarlıysa',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            FilledButton.tonal(
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
            if (_savedHint) ...[
              Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
              Text(
                'Kaydedildi',
                style: textTheme.labelMedium?.copyWith(color: cs.primary),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
