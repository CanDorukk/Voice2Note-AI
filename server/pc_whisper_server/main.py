"""
Voice2Note ile uyumlu yerel Whisper HTTP API.

Uygulama POST /transcribe ile multipart "file" alanını gönderir; JSON {"text": "..."} döner.
Ses (m4a, mp3, wav, …) sunucuda ffmpeg ile 16 kHz mono PCM WAV’a normalize edilir; ardından
faster-whisper çalışır. **ffmpeg** sistem PATH’inde olmalıdır.

Çalıştırma (venv içinde):
  pip install -r requirements.txt
  uvicorn main:app --host 0.0.0.0 --port 8787

Ortam değişkenleri:
  V2N_API_KEY  — doluysa istekte X-Api-Key başlığı aynı olmalı
  V2N_MODEL    — tiny | base | small | medium (varsayılan: small)
  V2N_DEVICE  — cuda | cpu (boşsa varsayılan cpu; tam CUDA/cuBLAS yoksa güvenli)
"""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from typing import Optional

from fastapi import FastAPI, File, HTTPException, Header, UploadFile
from fastapi.middleware.cors import CORSMiddleware

try:
    from faster_whisper import WhisperModel
except ImportError as e:  # pragma: no cover
    raise SystemExit(
        "faster-whisper yüklü değil: pip install -r requirements.txt"
    ) from e

API_KEY = os.environ.get("V2N_API_KEY", "").strip()
MODEL_SIZE = os.environ.get("V2N_MODEL", "small").strip() or "small"

_model: WhisperModel | None = None


def _load_model() -> WhisperModel:
    """Varsayılan cpu; CUDA yalnızca V2N_DEVICE=cuda ve kütüphaneler uygunsa."""
    global _model
    if _model is not None:
        return _model
    dev = os.environ.get("V2N_DEVICE", "cpu").strip().lower()
    if dev == "cuda":
        try:
            _model = WhisperModel(MODEL_SIZE, device="cuda", compute_type="float16")
        except Exception:
            _model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
    else:
        _model = WhisperModel(MODEL_SIZE, device="cpu", compute_type="int8")
    return _model


def _reset_model() -> None:
    global _model
    _model = None


def _transcribe_to_text(path: str) -> str:
    model = _load_model()
    segments, _info = model.transcribe(
        path,
        language="tr",
        beam_size=5,
        vad_filter=True,
    )
    return " ".join(s.text for s in segments).strip()


def _require_ffmpeg() -> str:
    exe = shutil.which("ffmpeg")
    if not exe:
        raise HTTPException(
            status_code=503,
            detail=(
                "ffmpeg bulunamadı (PATH). Ses dosyalarını dönüştürmek için gerekli — "
                "https://ffmpeg.org/download.html — Windows: winget install ffmpeg"
            ),
        )
    return exe


def _normalize_to_wav16k_mono(ffmpeg: str, src_path: str) -> str:
    """Geçici 16 kHz mono PCM WAV yolu döner; çağıran silmekle yükümlü."""
    fd, out_path = tempfile.mkstemp(suffix=".wav")
    os.close(fd)
    try:
        subprocess.run(
            [
                ffmpeg,
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                src_path,
                "-ar",
                "16000",
                "-ac",
                "1",
                "-c:a",
                "pcm_s16le",
                out_path,
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=7200,
        )
    except subprocess.CalledProcessError as e:
        try:
            os.unlink(out_path)
        except OSError:
            pass
        err = (e.stderr or e.stdout or str(e))[:800]
        raise HTTPException(
            status_code=400,
            detail=f"Ses dönüştürülemedi (ffmpeg): {err}",
        ) from e
    return out_path


app = FastAPI(title="Voice2Note PC Whisper", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, bool]:
    return {"ok": True}


@app.post("/transcribe")
async def transcribe(
    file: UploadFile = File(...),
    x_api_key: Optional[str] = Header(None, alias="X-Api-Key"),
) -> dict[str, str]:
    if API_KEY and (x_api_key or "").strip() != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")
    raw = await file.read()
    if len(raw) < 64:
        raise HTTPException(status_code=400, detail="Dosya çok kısa")
    suffix = ".bin"
    if file.filename:
        lower = file.filename.lower()
        for ext in (
            ".wav",
            ".m4a",
            ".mp3",
            ".ogg",
            ".webm",
            ".flac",
            ".aac",
            ".opus",
        ):
            if lower.endswith(ext):
                suffix = ext
                break
    ffmpeg = _require_ffmpeg()
    raw_path: str | None = None
    wav_path: str | None = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(raw)
            raw_path = tmp.name
        wav_path = _normalize_to_wav16k_mono(ffmpeg, raw_path)
        try:
            text = _transcribe_to_text(wav_path)
        except RuntimeError as e:
            err = str(e).lower()
            # Model CUDA ile yüklendi ama çalışma zamanında cuBLAS/cuDNN yok (Windows sık)
            if any(
                x in err
                for x in ("cublas", "cudnn", "cuda", "nvrtc")
            ):
                _reset_model()
                os.environ["V2N_DEVICE"] = "cpu"
                text = _transcribe_to_text(wav_path)
            else:
                raise
        return {"text": text}
    finally:
        for p in (wav_path, raw_path):
            if p and os.path.isfile(p):
                try:
                    os.unlink(p)
                except OSError:
                    pass
