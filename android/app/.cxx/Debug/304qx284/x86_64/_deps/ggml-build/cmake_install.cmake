# Install script for directory: F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Program Files (x86)/voice2note_whisper")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Debug")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "C:/Users/Can/AppData/Local/Android/Sdk/ndk/23.1.7779620/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-objdump.exe")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/.cxx/Debug/304qx284/x86_64/_deps/ggml-build/src/cmake_install.cmake")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/.cxx/Debug/304qx284/x86_64/_deps/ggml-build/src/libggml.a")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include" TYPE FILE FILES
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-cpu.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-alloc.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-backend.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-blas.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-cann.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-cpp.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-cuda.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-opt.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-metal.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-rpc.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-virtgpu.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-sycl.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-vulkan.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-webgpu.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-zendnn.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/ggml-openvino.h"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/src/main/cpp/third_party/whisper.cpp/ggml/include/gguf.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/.cxx/Debug/304qx284/x86_64/_deps/ggml-build/src/libggml-base.a")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/ggml" TYPE FILE FILES
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/.cxx/Debug/304qx284/x86_64/_deps/ggml-build/ggml-config.cmake"
    "F:/Projelerim/Voice2Note AI/voice_2_note_ai/android/app/.cxx/Debug/304qx284/x86_64/_deps/ggml-build/ggml-version.cmake"
    )
endif()

