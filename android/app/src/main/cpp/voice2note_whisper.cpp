#include <jni.h>
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <fstream>
#include <sstream>
#include <string>

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
        "[Whisper native stub] input wav degil. Once m4a->wav donusumu gerekli. "
        "audioPath=" +
        audio;
    return env->NewStringUTF(not_ready.c_str());
  }

  if (!FileExists(model)) {
    const std::string msg =
        "[Whisper native stub] model dosyasi bulunamadi. modelPath=" + model;
    return env->NewStringUTF(msg.c_str());
  }
  if (!FileExists(audio)) {
    const std::string msg =
        "[Whisper native stub] audio dosyasi bulunamadi. audioPath=" + audio;
    return env->NewStringUTF(msg.c_str());
  }

  const WavInfo wav = ReadWavInfo(audio);
  if (!wav.ok) {
    const std::string msg =
        "[Whisper native stub] wav parse hatasi: " + wav.error +
        ". audioPath=" + audio;
    return env->NewStringUTF(msg.c_str());
  }

  const bool whisper_friendly =
      wav.sample_rate == 16000 && wav.channels == 1 && wav.bits_per_sample == 16;
  std::ostringstream details;
  details << "[Whisper native stub] JNI transcribe ok (wav accepted). "
          << "sr=" << wav.sample_rate << ", ch=" << wav.channels
          << ", bits=" << wav.bits_per_sample << ", bytes=" << wav.data_size
          << ", whisper_ready=" << (whisper_friendly ? "yes" : "no")
          << ". modelPath=" << model << ", audioPath=" << audio;

  const std::string response = details.str();
  return env->NewStringUTF(response.c_str());
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
  };

  if (env->RegisterNatives(clazz, methods, 2) != 0) {
    return JNI_ERR;
  }

  return JNI_VERSION_1_6;
}
