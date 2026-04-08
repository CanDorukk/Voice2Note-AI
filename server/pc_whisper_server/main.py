"""
Voice2Note ile uyumlu yerel Whisper HTTP API.

Uygulama POST /transcribe ile multipart "file" alanını gönderir; JSON {"text": "..."} döner.
Ses (m4a, mp3, wav, …) sunucuda ffmpeg ile 16 kHz mono PCM WAV’a normalize edilir; ardından
faster-whisper çalışır. **ffmpeg** sistem PATH’inde olmalıdır.

İsteğe bağlı: V2N_POLISH=ollama ile transkriptten sonra yerel **Ollama** (LLM) ile Türkçe düzeltme;
Flutter tarafı değişmez — yanıtta tek `text` alanı (nihai metin) döner.

Çalıştırma (venv içinde):
  pip install -r requirements.txt
  uvicorn main:app --host 0.0.0.0 --port 8787

Ortam değişkenleri:
  V2N_API_KEY     — doluysa istekte X-Api-Key başlığı aynı olmalı
  V2N_MODEL       — tiny | base | small | medium | large-v2 | large-v3 … (varsayılan: small)
  V2N_DEVICE      — cuda | cpu (boşsa varsayılan cpu; tam CUDA/cuBLAS yoksa güvenli)
  V2N_BEAM_SIZE   — arama genişliği (varsayılan: 5; daha yüksek = daha iyi, daha yavaş)
  V2N_VAD_FILTER  — 1/true veya 0/false (varsayılan: true; sessiz kısımları atlar)
  V2N_LANGUAGE    — ISO kod (varsayılan: tr) veya auto (otomatik dil)
  V2N_POLISH      — boş veya off: sadece Whisper. **ollama**: transkripti Ollama ile düzelt
  V2N_OLLAMA_BASE — örn. http://127.0.0.1:11434 (varsayılan)
  V2N_OLLAMA_MODEL — Ollama model adı (varsayılan: llama3.2)
  V2N_OLLAMA_TIMEOUT_SEC — Ollama HTTP zaman aşımı saniye (varsayılan: 120)
  V2N_OLLAMA_SYSTEM_PROMPT — doluysa Türkçe düzeltme sistem prompt’unu tamamen değiştirir
"""

from __future__ import annotations

import logging
import os
import shutil
import subprocess
import tempfile
from typing import Optional

import httpx
from fastapi import FastAPI, File, HTTPException, Header, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    from faster_whisper import WhisperModel
except ImportError as e:  # pragma: no cover
    raise SystemExit(
        "faster-whisper yüklü değil: pip install -r requirements.txt"
    ) from e

logger = logging.getLogger(__name__)

API_KEY = os.environ.get("V2N_API_KEY", "").strip()
MODEL_SIZE = os.environ.get("V2N_MODEL", "small").strip() or "small"

_model: WhisperModel | None = None

_DEFAULT_TR_POLISH_PROMPT = (
    "Sen bir metin düzenleyicisisin. Verilen konuşma transkriptini Türkçe olarak düzelt: "
    "yazım, noktalama ve gereksiz tekrarları sadeleştir. Anlamı değiştirme. "
    "Sadece düzeltilmiş metni yaz; açıklama veya başlık ekleme."
)


def _env_int(name: str, default: int, *, min_v: int = 1, max_v: int = 20) -> int:
    raw = os.environ.get(name, "").strip()
    if not raw:
        return default
    try:
        return max(min_v, min(max_v, int(raw)))
    except ValueError:
        return default


def _env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name, "").strip().lower()
    if not raw:
        return default
    if raw in ("1", "true", "yes", "on"):
        return True
    if raw in ("0", "false", "no", "off"):
        return False
    return default


def _transcribe_language() -> Optional[str]:
    """Varsayılan tr; 'auto' veya boş → otomatik dil (faster-whisper)."""
    raw = os.environ.get("V2N_LANGUAGE", "tr").strip().lower()
    if not raw or raw == "auto":
        return None
    return raw


BEAM_SIZE = _env_int("V2N_BEAM_SIZE", 5, min_v=1, max_v=20)
VAD_FILTER = _env_bool("V2N_VAD_FILTER", True)

POLISH_MODE = os.environ.get("V2N_POLISH", "").strip().lower()
OLLAMA_BASE = os.environ.get("V2N_OLLAMA_BASE", "http://127.0.0.1:11434").rstrip("/")
OLLAMA_MODEL = os.environ.get("V2N_OLLAMA_MODEL", "llama3.2").strip() or "llama3.2"
OLLAMA_TIMEOUT = _env_int("V2N_OLLAMA_TIMEOUT_SEC", 120, min_v=10, max_v=600)


def _polish_enabled() -> bool:
    return POLISH_MODE in ("ollama", "1", "true", "yes")


def _ollama_system_prompt() -> str:
    custom = os.environ.get("V2N_OLLAMA_SYSTEM_PROMPT", "").strip()
    return custom if custom else _DEFAULT_TR_POLISH_PROMPT


def _polish_with_ollama(raw_text: str) -> str:
    """Ollama /api/chat ile Türkçe düzeltme. Hata veya boş yanıtta ham metin döner."""
    if not raw_text.strip():
        return raw_text
    url = f"{OLLAMA_BASE}/api/chat"
    payload = {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": _ollama_system_prompt()},
            {"role": "user", "content": raw_text},
        ],
        "stream": False,
    }
    try:
        with httpx.Client(timeout=float(OLLAMA_TIMEOUT)) as client:
            r = client.post(url, json=payload)
            r.raise_for_status()
            data = r.json()
    except Exception as e:
        logger.warning("Ollama polish atlandı (Whisper metni kullanılıyor): %s", e)
        return raw_text
    content = data.get("message", {}).get("content")
    if isinstance(content, str) and content.strip():
        return content.strip()
    logger.warning("Ollama boş veya beklenmeyen yanıt; Whisper metni kullanılıyor.")
    return raw_text


def _polish_with_ollama_strict(raw_text: str) -> str:
    """POST /polish için: hata durumunda HTTPException."""
    if not raw_text.strip():
        return raw_text
    url = f"{OLLAMA_BASE}/api/chat"
    payload = {
        "model": OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": _ollama_system_prompt()},
            {"role": "user", "content": raw_text},
        ],
        "stream": False,
    }
    try:
        with httpx.Client(timeout=float(OLLAMA_TIMEOUT)) as client:
            r = client.post(url, json=payload)
            r.raise_for_status()
            data = r.json()
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=503,
            detail=f"Ollama erişilemedi veya hata: {e}",
        ) from e
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Ollama yanıtı işlenemedi: {e}",
        ) from e
    content = data.get("message", {}).get("content")
    if not (isinstance(content, str) and content.strip()):
        raise HTTPException(status_code=502, detail="Ollama boş metin döndü.")
    return content.strip()


class PolishBody(BaseModel):
    text: str = Field(..., min_length=1, description="Düzeltilecek ham metin")


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
    lang = _transcribe_language()
    segments, _info = model.transcribe(
        path,
        language=lang,
        beam_size=BEAM_SIZE,
        vad_filter=VAD_FILTER,
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
def health() -> dict:
    """Sunucu ayarının özeti (API anahtarı dönmez)."""
    dev = os.environ.get("V2N_DEVICE", "cpu").strip().lower() or "cpu"
    lang_eff = _transcribe_language()
    out: dict = {
        "ok": True,
        "model": MODEL_SIZE,
        "device_requested": dev,
        "beam_size": BEAM_SIZE,
        "vad_filter": VAD_FILTER,
        "language": "auto" if lang_eff is None else lang_eff,
        "polish": POLISH_MODE or "off",
    }
    if _polish_enabled():
        out["ollama_base"] = OLLAMA_BASE
        out["ollama_model"] = OLLAMA_MODEL
    return out


@app.post("/polish")
def polish(
    body: PolishBody,
    x_api_key: Optional[str] = Header(None, alias="X-Api-Key"),
) -> dict[str, str]:
    """Ham metni Ollama ile düzeltir (V2N_POLISH=ollama gerekir). Test ve dış araçlar için."""
    if API_KEY and (x_api_key or "").strip() != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")
    if not _polish_enabled():
        raise HTTPException(
            status_code=400,
            detail="Metin düzeltme kapalı. Ortam: V2N_POLISH=ollama ve çalışan Ollama.",
        )
    text = _polish_with_ollama_strict(body.text)
    return {"text": text}


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
        if _polish_enabled():
            text = _polish_with_ollama(text)
        return {"text": text}
    finally:
        for p in (wav_path, raw_path):
            if p and os.path.isfile(p):
                try:
                    os.unlink(p)
                except OSError:
                    pass
