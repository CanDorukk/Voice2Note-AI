# Native third_party (Whisper / ggml)

CMake, `whisper.cpp` kaynaklarını şu dizinde arar:

`third_party/whisper.cpp/`

İçinde en az şunlar olmalı (ggerganov/whisper.cpp yapısı):

- `include/whisper.h`
- `src/whisper.cpp`
- `ggml/` (alt CMake ile birlikte)

## Seçenek A — Yerel kopya (hızlı)

Harici klonladığın repodan bu klasöre kopyala (örnek Windows PowerShell):

```powershell
$src  = "F:\Projelerim\Voice2Note AI\whisper.cpp"
$dst  = "android\app\src\main\cpp\third_party\whisper.cpp"
# include, src, ggml klasörlerini $dst altına kopyala (robocopy veya elle)
```

Ardından `flutter build apk` ile NDK derlemesinin geçtiğini doğrula.

## Seçenek B — Git submodule (takım / tekrarlanabilir)

Repo kökünde:

```bash
git submodule add https://github.com/ggerganov/whisper.cpp.git android/app/src/main/cpp/third_party/whisper.cpp
git submodule update --init --recursive
```

Submodule sürümünü sabitlemek için belirli commit’e checkout edip submodule kaydını commit et.

## Repo boyutu: commit etmeyecek misin?

Kök `.gitignore` içinde şu satırı **yorumdan çıkarırsan** bu ağaç Git’e girmez (klon sonrası elle veya CI’da doldurulur):

`android/app/src/main/cpp/third_party/whisper.cpp/`

## Model dosyası (ayrı)

`ggml-tiny.bin` **burada değil**; Flutter asset / `WhisperModelService` ile `assets/models/` ve uygulama dizinine kopyalanır. Ayrıca `assets/models/*.bin` genelde `.gitignore`’dadır.
