#include <jni.h>
#include <algorithm>
#include <cctype>
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

  const std::string response =
      "[Whisper native stub] JNI transcribe ok (wav accepted). modelPath=" + model +
      ", audioPath=" + audio;
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
