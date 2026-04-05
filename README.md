# Voice2 Note AI

Flutter tabanlı ses kaydı → çevrimdışı Whisper transkript → özet (TextRank) → SQLite notlar.

## Özellikler (özet)

- **Tema:** Sistem, açık veya koyu; tercih cihazda saklanır ve ana ekranlarda menüden değiştirilebilir.
- **Notlar:** Liste; transkript/özet araması; detayda **düzenleme** (kaydet), kopyalama, ses oynatma; silmeden sonra SnackBar ile **geri al**.
- **Kayıt / dosya:** Mikrofon kaydı veya dosya seçicide **yalnızca ses** (ör. m4a, wav); Android’de gerekirse `AudioToWav16kMono` ile 16 kHz mono PCM WAV’a dönüştürülür. Arka planda aynı işlem (`audio_to_note_pipeline.dart`) transkript + özet + veritabanı. Bekleyen satırlar `pending_processing_provider.dart`.
- **Gezinme:** Ana `MaterialPageRoute` geçişleri `lib/app/app_navigation.dart` içinde toplanır.
- **PDF:** Önizleme/yazdırma (`printing`) ve dosyaya kaydetme; paylaşım ekranında transkript/özet/PDF paylaşımı.
- **Hakkında:** Uygulama sürümü ve `showLicensePage` ile lisanslar; ilk açılış tanıtım ekranında sürüm satırı.

## Gereksinimler

- Flutter SDK (pubspec içindeki sürüm aralığı)
- **Android:** NDK ile `whisper.cpp` native modülü; ayrıntı için `android/app/src/main/cpp/third_party/README.md`

## Ses tanıma paketi (Android)

**Uygulama içi:** İlk açılışta tanıtım ekranında, sesinizi yazıya çevirmek için gerekli paket **bir kez** indirilir (yaklaşık 60 MB; Wi‑Fi önerilir). İndirme bitmeden **Başla** düğmesi açılmaz.

**Kaynak kodu / geliştirici:** Paket dosyası repoda yoktur. Yerel derleme veya CI için `assets/models/ggml-base-q5_1.bin` yolunda gerçek dosya gerekir ([ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp/tree/main) üzerinden `ggml-base-q5_1.bin`). Boş veya 0 baytlık dosya ile çalışmaz; analiz uyarısı `analysis_options.yaml` ile kapatılır, CI’da boş dosya oluşturulur.

## Çalıştırma

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
flutter analyze
```

Push ve pull request’lerde GitHub Actions aynı komutları çalıştırır (`.github/workflows/flutter_ci.yml`). Tam **APK/NDK** derlemesi CI’da yoktur; yerelde `flutter build apk` ile deneyebilirsiniz.

## Yapılacaklar (ileride)

1. **Model:** İsteğe bağlı `small` ggml quantize veya uygulama içi model seçimi.
2. **İçe aktarma:** iOS veya ek biçimler için dönüştürme / net hata mesajları (Android’de m4a vb. MediaCodec ile).
3. **Türkçe:** Ek normalizasyon (birleşik/ayrık yazım, kullanıcı sözlüğü) ve arama eş anlamlılığı.

## Platform notu

Çevrimdışı Whisper şu an **Android** hedefi için yapılandırılmıştır; iOS tarafı bu aşamada öncelikli değildir.
