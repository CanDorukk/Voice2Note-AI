import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_ggml_model.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';
import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';

/// Hakkında vb. içinde: Android’de ses tanıma paketinin durumu ve ağdan indirme.
class WhisperModelDownloadSection extends StatefulWidget {
  const WhisperModelDownloadSection({super.key});

  @override
  State<WhisperModelDownloadSection> createState() =>
      _WhisperModelDownloadSectionState();
}

class _WhisperModelDownloadSectionState
    extends State<WhisperModelDownloadSection> {
  WhisperGgmlModel _kind = WhisperGgmlModel.small;
  bool _checking = true;
  bool _modelReady = false;
  bool _downloading = false;
  int _received = 0;
  int? _total;
  String? _downloadError;

  final TextEditingController _remoteUrlCtrl = TextEditingController();
  final TextEditingController _remoteApiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kIsWeb || !Platform.isAndroid) {
      _checking = false;
      return;
    }
    _bootstrap();
  }

  @override
  void dispose() {
    _remoteUrlCtrl.dispose();
    _remoteApiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final kind = await WhisperModelService.instance.getSelectedModel();
    final remoteUrl = await RemoteTranscribeSettings.getBaseUrl();
    final remoteKey = await RemoteTranscribeSettings.getApiKey();
    if (!mounted) return;
    setState(() {
      _kind = kind;
      if (remoteUrl != null) {
        _remoteUrlCtrl.text = remoteUrl;
      }
      if (remoteKey != null) {
        _remoteApiKeyCtrl.text = remoteKey;
      }
    });
    await _recheck();
  }

  Future<void> _saveRemoteSettings() async {
    await RemoteTranscribeSettings.setBaseUrl(_remoteUrlCtrl.text);
    await RemoteTranscribeSettings.setApiKey(_remoteApiKeyCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PC sunucu ayarı kaydedildi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onModelKindChanged(WhisperGgmlModel next) async {
    if (_downloading) return;
    await WhisperModelService.instance.setSelectedModel(next);
    if (!mounted) return;
    setState(() {
      _kind = next;
      _downloadError = null;
    });
    await _recheck();
  }

  Future<void> _recheck() async {
    setState(() => _checking = true);
    final path = await WhisperModelService.instance.ensureReady();
    if (!mounted) return;
    setState(() {
      _modelReady = path != null && path.isNotEmpty;
      _checking = false;
    });
  }

  Future<void> _downloadModel() async {
    setState(() {
      _downloadError = null;
      _downloading = true;
      _received = 0;
      _total = null;
    });
    final ok = await WhisperModelService.instance.downloadSelectedModelFromNetwork(
      onProgress: (received, total) {
        if (!mounted) return;
        setState(() {
          _received = received;
          _total = total;
        });
      },
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _downloading = false;
        _downloadError =
            'İndirilemedi. İnternet bağlantınızı kontrol edip yeniden deneyin.';
      });
      return;
    }
    final path = await WhisperModelService.instance.ensureReady();
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _modelReady = path != null && path.isNotEmpty;
      if (!_modelReady) {
        _downloadError = 'Paket doğrulanamadı. Yeniden indirmeyi deneyin.';
      }
    });
  }

  double? get _progressFraction {
    final t = _total;
    if (t == null || t <= 0) return null;
    return (_received / t).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_checking) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
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
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ses paketi kontrol ediliyor…',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _modelReady ? Icons.verified_rounded : Icons.warning_amber_rounded,
                size: 20,
                color: _modelReady ? cs.primary : cs.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _modelReady
                      ? 'Ses tanıma paketi yüklü'
                      : 'Ses tanıma paketi eksik',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          WhisperGgmlModelSegmentedButton(
            selected: _kind,
            enabled: !_downloading,
            onChanged: _onModelKindChanged,
          ),
          const SizedBox(height: 6),
          Text(
            _modelReady
                ? 'Kayıt ve transkript için paket hazır. Bozuksa veya silindiyse yeniden indirebilirsiniz.'
                : 'Konuşmayı yazıya dökmek için paketi indirmeniz gerekir '
                    '(yaklaşık ${_kind.approxDownloadMegabytes} MB; Wi‑Fi önerilir).',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (_downloadError != null) ...[
            const SizedBox(height: 8),
            Text(
              _downloadError!,
              style: textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ],
          if (_downloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: _progressFraction,
                backgroundColor: cs.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _total != null && _total! > 0
                  ? '${(_received / (1024 * 1024)).toStringAsFixed(1)} / '
                      '${(_total! / (1024 * 1024)).toStringAsFixed(1)} MB'
                  : 'İndiriliyor…',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (!_downloading) ...[
            const SizedBox(height: 10),
            if (!_modelReady)
              FilledButton.tonalIcon(
                onPressed: _downloadModel,
                icon: const Icon(Icons.cloud_download_rounded, size: 20),
                label: const Text('Ses paketini indir'),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Paketi yeniden indir'),
                ),
              ),
          ],
          const SizedBox(height: 20),
          Text(
            'PC sunucu (isteğe bağlı)',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Transkripti bilgisayarda çalıştırmak için aşağıya adresi yazın '
            '(örn. http://192.168.1.5:8787). Boş bırakırsanız yalnızca telefonda '
            'çevrimdışı model kullanılır. Kurulum: docs/pc_whisper_sunucu.md',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _remoteUrlCtrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Sunucu kök adresi',
              hintText: 'http://192.168.1.10:8787',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _remoteApiKeyCtrl,
            obscureText: true,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'API anahtarı (isteğe bağlı)',
              hintText: 'PC tarafında V2N_API_KEY ayarlıysa',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: _saveRemoteSettings,
              child: const Text('Sunucu ayarını kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
