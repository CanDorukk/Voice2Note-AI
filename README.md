# Voice2 Note AI

Flutter tabanlı ses kaydı → çevrimdışı Whisper transkript → özet (TextRank) → SQLite notlar.

## Özellikler (özet)

- **Tema:** Sistem, açık veya koyu; tercih cihazda saklanır ve ana ekranlarda menüden değiştirilebilir.
- **Notlar:** Liste; transkript ve özet metninde arama; detayda metin kopyalama, ses oynatma, PDF ve paylaşım akışları (önizleme ekranları mevcut).
- **Hakkında:** Uygulama sürümü ve `showLicensePage` ile lisanslar; ilk açılış tanıtım ekranında sürüm satırı.

## Gereksinimler

- Flutter SDK (pubspec içindeki sürüm aralığı)
- **Android:** NDK ile `whisper.cpp` native modülü; ayrıntı için `android/app/src/main/cpp/third_party/README.md`

## Model dosyası (Whisper)

`assets/models/ggml-tiny-q5_1.bin` dosyasını [Hugging Face `ggerganov/whisper.cpp`](https://huggingface.co/ggerganov/whisper.cpp/tree/main) üzerinden indirip `assets/models/` altına koyun. `*.bin` repoda yok (`.gitignore`); analiz uyarısı `analysis_options.yaml` ile kapatıldı, CI’da boş dosya oluşturulur. **Uygulamayı çalıştırmak için** gerçek model dosyası şarttır.

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

Push ve pull request’lerde GitHub Actions aynı komutları çalıştırır (`.github/workflows/flutter_ci.yml`). Tam APK/NDK derlemesi CI’da yoktur.

## Platform notu

Çevrimdışı Whisper şu an **Android** hedefi için yapılandırılmıştır; iOS tarafı bu aşamada öncelikli değildir.
