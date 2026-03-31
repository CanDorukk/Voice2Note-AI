#include <jni.h>
#include <string>

namespace {

jstring NativePing(JNIEnv *env, jclass /* clazz */) {
  const char *msg = "voice2note_whisper NDK ok";
  return env->NewStringUTF(msg);
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
  };

  if (env->RegisterNatives(clazz, methods, 1) != 0) {
    return JNI_ERR;
  }

  return JNI_VERSION_1_6;
}
