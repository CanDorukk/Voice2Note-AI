# Voice2 Note AI

Ses kaydini metne cevirip nota donusturen, ozetleyen ve PDF olarak disa aktarabilen Flutter tabanli Android uygulamasi.

## Surum ve Durum

- **Urun cizgisi:** v1
- **Paket surumu:** `0.1.0` (`pubspec.yaml`)
- **Platform odagi:** Android
- **Transkript mimarisi:** Mobil uygulama + ayri Whisper sunucusu

## Neler Yapabilirsiniz?

- Ses kaydi veya dosyadan ice aktarma ile not olusturma
- Transkript alma (sunucu uzerinden)
- TextRank tabanli ozet olusturma
- Not listesinde arama (transkript + ozet)
- Ses oynatma, metin duzenleme ve kopyalama
- PDF onizleme, yazdirma, dosyaya kaydetme
- Notu metin/PDF olarak paylasma
- Tema secimi (sistem / acik / koyu)

## Mimari Ozet

```text
[Android Uygulamasi] -- HTTP --> [PC/VPS Whisper Sunucusu]
       |                               |
  kayit / dosya                    faster-whisper + ffmpeg
       |                               |
       +-------- POST /transcribe -----+
       +<------ JSON { "text": "..." } -+
```

> Uygulamanin icinde Whisper modeli yoktur. Model sunucu tarafinda calisir.

## Teknoloji Yigini

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
- (Opsiyonel) Ollama ile metin duzeltme

## Mobil Kurulum (Uygulama)

### Gereksinimler

- Flutter SDK
- Dart SDK (`>=3.4.3 <4.0.0`)
- Android Studio veya Android SDK + emu/cihaz

### Adimlar

```bash
git clone <repo-url>
cd voice_2_note_ai
flutter pub get
flutter run
```

### Uygulamada Yapilacak Son Ayar

Uygulama acildiktan sonra **Hakkinda** ekranindan transkript sunucu adresini girin.

Ornek:

- `http://192.168.1.10:8787` (ayni Wi-Fi aginda yerel PC)
- `https://api.senin-domainin.com` (uzak sunucu)

## Server Kurulum (PC Whisper Sunucusu)

Sunucu kodu: `server/pc_whisper_server`

Detayli dokumantasyon: [`docs/pc_whisper_sunucu.md`](docs/pc_whisper_sunucu.md)

### Gereksinimler

- Python 3.10+
- ffmpeg (PATH uzerinde olmali)
- (Opsiyonel) NVIDIA GPU + CUDA

### Windows (PowerShell)

```powershell
cd server\pc_whisper_server
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8787
```

### Linux/macOS

```bash
cd server/pc_whisper_server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8787
```

Sunucu ayaga kalkinca mobil uygulamada taban adresi olarak bu host/port bilgisini kullanin.

## Gelistirme Komutlari

```bash
flutter analyze
flutter test
```

CI akisi: [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)

## Dizin Ozeti

```text
lib/                      # Flutter uygulamasi
server/pc_whisper_server/ # Whisper HTTP API
docs/                     # Kurulum ve teknik dokumanlar
```

## Lisans

Bu proje `LICENSE` dosyasinda belirtilen lisans ile dagitilmaktadir.
