#include <jni.h>
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <fstream>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#if VOICE2NOTE_HAS_WHISPER_CPP
#include <android/log.h>
#include <chrono>
#include <cstdlib>
#include <limits.h>

#include "whisper.h"

#define V2N_LOG_TAG "Voice2NoteWhisper"
#endif

namespace {

jstring NativePing(JNIEnv *env, jclass /* clazz */) {
  const char *msg = "voice2note_whisper NDK ok";
  return env->NewStringUTF(msg);
}

std::string JStringToStdString(JNIEnv *env, jstring value) {
  if (value == nullptr) {
    return "(null)";
  }

  const char *raw = env->GetStringUTFChars(value, nullptr);
  if (raw == nullptr) {
    return "(null)";
  }

  std::string out(raw);
  env->ReleaseStringUTFChars(value, raw);
  return out;
}

bool FileExists(const std::string &path) {
  std::ifstream f(path, std::ios::binary);
  return f.good();
}

struct WavInfo {
  bool ok = false;
  int sample_rate = 0;
  int channels = 0;
  int bits_per_sample = 0;
  int data_size = 0;
  std::string error;
};

struct WavData {
  WavInfo info;
  std::vector<float> pcm_f32;
};

WavInfo ReadWavInfo(const std::string &path) {
  WavInfo info;
  std::ifstream in(path, std::ios::binary);
  if (!in) {
    info.error = "wav acilamadi";
    return info;
  }

  char riff[4] = {0};
  in.read(riff, 4);
  if (std::string(riff, 4) != "RIFF") {
    info.error = "RIFF header yok";
    return info;
  }

  in.ignore(4); // chunk size

  char wave[4] = {0};
  in.read(wave, 4);
  if (std::string(wave, 4) != "WAVE") {
    info.error = "WAVE header yok";
    return info;
  }

  bool found_fmt = false;
  bool found_data = false;
  std::uint16_t audio_format = 0;

  while (in && (!found_fmt || !found_data)) {
    char id[4] = {0};
    std::uint32_t chunk_size = 0;
    in.read(id, 4);
    in.read(reinterpret_cast<char *>(&chunk_size), 4);
    if (!in) {
      break;
    }

    const std::string chunk_id(id, 4);
    if (chunk_id == "fmt ") {
      found_fmt = true;
      in.read(reinterpret_cast<char *>(&audio_format), 2);
      std::uint16_t channels = 0;
      std::uint32_t sample_rate = 0;
      std::uint32_t byte_rate = 0;
      std::uint16_t block_align = 0;
      std::uint16_t bits_per_sample = 0;
      in.read(reinterpret_cast<char *>(&channels), 2);
      in.read(reinterpret_cast<char *>(&sample_rate), 4);
      in.read(reinterpret_cast<char *>(&byte_rate), 4);
      in.read(reinterpret_cast<char *>(&block_align), 2);
      in.read(reinterpret_cast<char *>(&bits_per_sample), 2);

      info.channels = static_cast<int>(channels);
      info.sample_rate = static_cast<int>(sample_rate);
      info.bits_per_sample = static_cast<int>(bits_per_sample);

      const auto consumed = 16u;
      if (chunk_size > consumed) {
        in.ignore(static_cast<std::streamsize>(chunk_size - consumed));
      }
    } else if (chunk_id == "data") {
      found_data = true;
      info.data_size = static_cast<int>(chunk_size);
      in.ignore(static_cast<std::streamsize>(chunk_size));
    } else {
      in.ignore(static_cast<std::streamsize>(chunk_size));
    }
  }

  if (!found_fmt || !found_data) {
    info.error = "fmt/data chunk eksik";
    return info;
  }
  if (audio_format != 1) {
    info.error = "yalnizca PCM wav destekleniyor";
    return info;
  }

  info.ok = true;
  return info;
}

jstring NativeTranscribe(JNIEnv *env, jclass /* clazz */, jstring model_path,
                         jstring audio_path);

WavData ReadWavData16BitMono(const std::string &path) {
  WavData out;
  out.info = ReadWavInfo(path);
  if (!out.info.ok) {
    return out;
  }
  if (out.info.bits_per_sample != 16) {
    out.info.ok = false;
    out.info.error = "yalnizca 16-bit PCM destekleniyor";
    return out;
  }

  std::ifstream in(path, std::ios::binary);
  if (!in) {
    out.info.ok = false;
    out.info.error = "wav acilamadi";
    return out;
  }

  // data chunk konumunu tekrar bul.
  in.ignore(12); // RIFF + size + WAVE
  std::uint32_t data_size = 0;
  while (in) {
    char id[4] = {0};
    std::uint32_t chunk_size = 0;
    in.read(id, 4);
    in.read(reinterpret_cast<char *>(&chunk_size), 4);
    if (!in) break;

    const std::string chunk_id(id, 4);
    if (chunk_id == "data") {
      data_size = chunk_size;
      break;
    }
    in.ignore(static_cast<std::streamsize>(chunk_size));
  }

  if (data_size == 0) {
    out.info.ok = false;
    out.info.error = "data chunk bos";
    return out;
  }

  const size_t samples = data_size / sizeof(std::int16_t);
  std::vector<std::int16_t> pcm16(samples);
  in.read(reinterpret_cast<char *>(pcm16.data()), static_cast<std::streamsize>(data_size));
  if (!in) {
    out.info.ok = false;
    out.info.error = "pcm okunamadi";
    return out;
  }

  out.pcm_f32.resize(samples);
  for (size_t i = 0; i < samples; ++i) {
    out.pcm_f32[i] = static_cast<float>(pcm16[i]) / 32768.0f;
  }
  return out;
}

#if VOICE2NOTE_HAS_WHISPER_CPP
std::mutex g_whisper_mutex;
whisper_context *g_whisper_ctx = nullptr;
std::string g_whisper_model_path;

std::string CanonicalModelPath(const std::string &path) {
  char buf[PATH_MAX];
  if (realpath(path.c_str(), buf) != nullptr) {
    return std::string(buf);
  }
  return path;
}

void ReleaseCachedWhisperContext() {
  if (g_whisper_ctx != nullptr) {
    whisper_free(g_whisper_ctx);
    g_whisper_ctx = nullptr;
  }
  g_whisper_model_path.clear();
}

// Ön koşul: g_whisper_mutex tutuluyor.
std::string LoadWhisperIfNeededLocked(const std::string &model_canonical) {
  if (g_whisper_ctx != nullptr && g_whisper_model_path == model_canonical) {
    __android_log_print(ANDROID_LOG_INFO, V2N_LOG_TAG, "whisper model cache HIT");
    return "";
  }
  ReleaseCachedWhisperContext();
  const auto t0 = std::chrono::steady_clock::now();
  struct whisper_context_params cparams = whisper_context_default_params();
#if defined(__ANDROID__)
  cparams.use_gpu = false;
#endif
  g_whisper_ctx =
      whisper_init_from_file_with_params(model_canonical.c_str(), cparams);
  const auto t1 = std::chrono::steady_clock::now();
  const auto init_ms =
      std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
  __android_log_print(ANDROID_LOG_INFO, V2N_LOG_TAG,
                      "whisper model cache MISS init_ms=%lld",
                      static_cast<long long>(init_ms));
  if (g_whisper_ctx == nullptr) {
    return "Model yüklenemedi. Uygulamayı yeniden başlatmayı deneyin.";
  }
  g_whisper_model_path = model_canonical;
  return "";
}

std::string TranscribeWithWhisperCpp(const std::string &model,
                                     const std::string &audio) {
  const WavData wav = ReadWavData16BitMono(audio);
  if (!wav.info.ok) {
    return std::string("Ses dosyası okunamadı: ") + wav.info.error;
  }
  if (wav.info.sample_rate != 16000 || wav.info.channels != 1) {
    std::ostringstream ss;
    ss << "Ses formatı uygun değil (16 kHz mono WAV gerekli). sr="
       << wav.info.sample_rate << ", kanal=" << wav.info.channels;
    return ss.str();
  }

  const std::string model_canon = CanonicalModelPath(model);

  std::lock_guard<std::mutex> lock(g_whisper_mutex);

  const std::string load_err = LoadWhisperIfNeededLocked(model_canon);
  if (!load_err.empty()) {
    return load_err;
  }

  whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
  params.print_progress = false;
  params.print_realtime = false;
  params.print_timestamps = false;
  params.translate = false;
  params.no_timestamps = true;
  params.single_segment = true;
  params.language = "tr";
  {
    int n_threads = static_cast<int>(std::thread::hardware_concurrency());
    if (n_threads < 1) {
      n_threads = 1;
    }
    if (n_threads > 8) {
      n_threads = 8;
    }
    params.n_threads = n_threads;
  }

  const auto t_infer0 = std::chrono::steady_clock::now();
  const int code =
      whisper_full(g_whisper_ctx, params, wav.pcm_f32.data(),
                   static_cast<int>(wav.pcm_f32.size()));
  const auto t_infer1 = std::chrono::steady_clock::now();
  const auto infer_ms =
      std::chrono::duration_cast<std::chrono::milliseconds>(t_infer1 - t_infer0)
          .count();
  __android_log_print(ANDROID_LOG_INFO, V2N_LOG_TAG,
                      "whisper_full infer_ms=%lld audio_samples=%d",
                      static_cast<long long>(infer_ms),
                      static_cast<int>(wav.pcm_f32.size()));

  if (code != 0) {
    return "Konuşma metne çevrilemedi (kod " + std::to_string(code) + ").";
  }

  std::string transcript;
  const int n = whisper_full_n_segments(g_whisper_ctx);
  for (int i = 0; i < n; ++i) {
    const char *seg = whisper_full_get_segment_text(g_whisper_ctx, i);
    if (seg != nullptr) {
      if (!transcript.empty()) transcript += " ";
      transcript += seg;
    }
  }

  if (transcript.empty()) {
    return "Konuşma algılanamadı. Daha net konuşup tekrar deneyin.";
  }
  return transcript;
}

jstring NativeWarmup(JNIEnv *env, jclass /* clazz */, jstring model_path_j) {
  const std::string model_raw = JStringToStdString(env, model_path_j);
  if (model_raw.empty() || !FileExists(model_raw)) {
    return env->NewStringUTF("Model dosyası bulunamadı.");
  }
  const std::string model_canon = CanonicalModelPath(model_raw);
  std::lock_guard<std::mutex> lock(g_whisper_mutex);
  const std::string err = LoadWhisperIfNeededLocked(model_canon);
  if (!err.empty()) {
    return env->NewStringUTF(err.c_str());
  }
  return env->NewStringUTF("ok");
}
#endif

#if !VOICE2NOTE_HAS_WHISPER_CPP
jstring NativeWarmup(JNIEnv *env, jclass /* clazz */, jstring /* model_path_j */) {
  return env->NewStringUTF("ok");
}
#endif

jstring NativeTranscribe(JNIEnv *env, jclass /* clazz */, jstring model_path,
                         jstring audio_path) {
  const std::string model = JStringToStdString(env, model_path);
  const std::string audio = JStringToStdString(env, audio_path);

  std::string audio_lower = audio;
  std::transform(audio_lower.begin(), audio_lower.end(), audio_lower.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });

  // Sonraki adımda gerçek whisper.cpp çağrısı eklenecek.
  // Şimdiden wav şartını doğrulayıp net geri dönüş veriyoruz.
  const bool is_wav = audio_lower.size() >= 4 &&
                      audio_lower.rfind(".wav") == audio_lower.size() - 4;
  if (!is_wav) {
    const std::string not_ready =
        "Ses dosyası WAV olmalı. Kayıt ayarlarını kontrol edin.";
    return env->NewStringUTF(not_ready.c_str());
  }

  if (!FileExists(model)) {
    const std::string msg = "Model dosyası bulunamadı. Uygulamayı yeniden başlatın.";
    return env->NewStringUTF(msg.c_str());
  }
  if (!FileExists(audio)) {
    const std::string msg = "Ses dosyası bulunamadı.";
    return env->NewStringUTF(msg.c_str());
  }

  const WavInfo wav = ReadWavInfo(audio);
  if (!wav.ok) {
    const std::string msg =
        std::string("Ses dosyası geçersiz: ") + wav.error;
    return env->NewStringUTF(msg.c_str());
  }

#if VOICE2NOTE_HAS_WHISPER_CPP
  const std::string transcript = TranscribeWithWhisperCpp(model, audio);
  return env->NewStringUTF(transcript.c_str());
#else
  std::ostringstream details;
  details << "Çevrimdışı transkript henüz bu derlemede yok (stub). "
          << "sr=" << wav.sample_rate << ", ch=" << wav.channels
          << ", bits=" << wav.bits_per_sample;

  const std::string response = details.str();
  return env->NewStringUTF(response.c_str());
#endif
}

} // namespace

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void * /* reserved */) {
  JNIEnv *env = nullptr;
  if (vm->GetEnv(reinterpret_cast<void **>(&env), JNI_VERSION_1_6) != JNI_OK) {
    return JNI_ERR;
  }

  jclass clazz =
      env->FindClass("com/example/voice_2_note_ai/WhisperNative");
  if (clazz == nullptr) {
    return JNI_ERR;
  }

  static JNINativeMethod methods[] = {
      {"ping", "()Ljava/lang/String;",
       reinterpret_cast<void *>(NativePing)},
      {"transcribe", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;",
       reinterpret_cast<void *>(NativeTranscribe)},
      {"warmup", "(Ljava/lang/String;)Ljava/lang/String;",
       reinterpret_cast<void *>(NativeWarmup)},
  };

  if (env->RegisterNatives(clazz, methods, 3) != 0) {
    return JNI_ERR;
  }

  return JNI_VERSION_1_6;
}
