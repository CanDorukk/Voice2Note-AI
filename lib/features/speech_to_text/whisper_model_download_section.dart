import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';

/// Hakkında vb. içinde: Android’de ses tanıma paketinin durumu ve ağdan indirme.
class WhisperModelDownloadSection extends StatefulWidget {
  const WhisperModelDownloadSection({super.key});

  @override
  State<WhisperModelDownloadSection> createState() =>
      _WhisperModelDownloadSectionState();
}

class _WhisperModelDownloadSectionState
    extends State<WhisperModelDownloadSection> {
  bool _checking = true;
  bool _modelReady = false;
  bool _downloading = false;
  int _received = 0;
  int? _total;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || !Platform.isAndroid) {
      _checking = false;
      return;
    }
    _checkModel();
  }

  Future<void> _checkModel() async {
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
    final ok = await WhisperModelService.instance.downloadGgmlBaseQ5FromNetwork(
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
          const SizedBox(height: 6),
          Text(
            _modelReady
                ? 'Kayıt ve transkript için paket hazır. Bozuksa veya silindiyse yeniden indirebilirsiniz.'
                : 'Konuşmayı yazıya dökmek için paketi indirmeniz gerekir (yaklaşık 60 MB; Wi‑Fi önerilir).',
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
        ],
      ),
    );
  }
}
