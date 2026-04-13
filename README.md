# Voice2 Note AI

Ses kaydını metne çevirip nota dönüştüren, özetleyen ve PDF olarak dışa aktarabilen Flutter tabanlı Android uygulaması.

## Sürüm ve Durum

- **Ürün çizgisi:** v1
- **Paket sürümü:** `0.1.0` (`pubspec.yaml`)
- **Platform odağı:** Android
- **Transkript mimarisi:** Mobil uygulama + ayrı Whisper sunucusu

## Neler Yapabilirsiniz?

- Ses kaydı veya dosyadan içe aktarma ile not oluşturma
- Transkript alma (sunucu üzerinden)
- TextRank tabanlı özet oluşturma
- Not listesinde arama (transkript + özet)
- Ses oynatma, metin düzenleme ve kopyalama
- PDF önizleme, yazdırma, dosyaya kaydetme
- Notu metin/PDF olarak paylaşma
- Tema seçimi (sistem / açık / koyu)

## Mimari Özet

```text
[Android Uygulaması] -- HTTP --> [PC/VPS Whisper Sunucusu]
       |                              |
  kayıt / dosya                   faster-whisper + ffmpeg
       |                              |
       +-------- POST /transcribe ----+
       +<------ JSON { "text": "..." } +
```

> Uygulamanın içinde Whisper modeli yoktur. Model sunucu tarafında çalışır.

## Teknoloji Yığını

### Mobil (Flutter)

- Flutter, Dart
- Riverpod
- SQLite (`sqflite`), `shared_preferences`
- `record`, `just_audio`, `file_picker`
- `http`
- `pdf`, `printing`, `share_plus`
- Material 3

### Sunucu (Whisper API)

- Python 3.10+
- FastAPI
- faster-whisper
- ffmpeg
- Ollama (transkript sonrası metin düzeltme senaryoları için)

## Mobil Kurulum ve Çalıştırma (Android)

### Gereksinimler

- Flutter SDK
- Dart SDK (`>=3.4.3 <4.0.0`)
- Android Studio veya Android SDK + Android cihaz/emülatör

### Adımlar

```bash
git clone <repo-url>
cd voice_2_note_ai
flutter pub get
flutter run
```

### Uygulama İçinde Son Ayar

Uygulama açıldıktan sonra **Hakkında** ekranından transkript sunucu adresini girin.

Örnek:

- `http://192.168.1.10:8787` (aynı Wi-Fi ağında yerel PC)
- `https://api.senin-domainin.com` (uzak sunucu)

## Server Kurulum (PC Whisper Sunucusu)

Sunucu kodu: `server/pc_whisper_server`  
Detaylı dokümantasyon: [`docs/pc_whisper_sunucu.md`](docs/pc_whisper_sunucu.md)

### Gereksinimler

- Python 3.10+
- ffmpeg (PATH üzerinde olmalı)
- (Opsiyonel) NVIDIA GPU + CUDA

### Windows (PowerShell)

```powershell
cd server\pc_whisper_server
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8787
```

Sunucu ayağa kalkınca mobil uygulamada taban adresi olarak bu host/port bilgisini kullanın.

## Geliştirme Komutları

```bash
flutter analyze
flutter test
```

CI akışı: [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)

## Dizin Özeti

```text
lib/                      # Flutter uygulaması
server/pc_whisper_server/ # Whisper HTTP API
docs/                     # Kurulum ve teknik dokümanlar
```

## Lisans

Bu proje `LICENSE` dosyasında belirtilen lisans ile dağıtılmaktadır.
