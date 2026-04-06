import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voice_2_note_ai/features/notes/user_search_synonyms_provider.dart';
import 'package:voice_2_note_ai/services/turkish_search_synonym_prefs.dart';

/// Hakkında: not araması için isteğe bağlı eş anlamlı satırları (`kelime=kanonik`).
class TurkishSearchSynonymsSection extends ConsumerStatefulWidget {
  const TurkishSearchSynonymsSection({super.key});

  @override
  ConsumerState<TurkishSearchSynonymsSection> createState() =>
      _TurkishSearchSynonymsSectionState();
}

class _TurkishSearchSynonymsSectionState
    extends ConsumerState<TurkishSearchSynonymsSection> {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await TurkishSearchSynonymPrefs.loadRaw();
    if (!mounted) return;
    setState(() {
      _ctrl.text = raw;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await TurkishSearchSynonymPrefs.saveRaw(_ctrl.text);
    ref.invalidate(userSearchSynonymsBundleProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arama sözlüğü kaydedildi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
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
            Text('Arama sözlüğü yükleniyor…', style: textTheme.bodySmall),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not araması (eş anlamlı)',
            style: textTheme.titleSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Her satırda bir eşleme: aranacak kelime = nottaki kanonik kelime. '
            'Yerleşik gruplar (doktor/hekim, araba/otomobil vb.) zaten vardır; buradan ekleyebilirsin. '
            '# ile başlayan satırlar yorum sayılır.',
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'örnek:\nmuayene=doktor\nşirket=firma',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _save,
              child: const Text('Sözlüğü kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
