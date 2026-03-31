cmake_minimum_required(VERSION 3.18.1)
project(voice2note_whisper LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

set(WHISPER_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/whisper.cpp")
set(WHISPER_CPP_INCLUDE_DIR "${WHISPER_CPP_DIR}/include")
set(WHISPER_CPP_SOURCE_FILE "${WHISPER_CPP_DIR}/src/whisper.cpp")

set(VOICE2NOTE_SOURCES
    voice2note_whisper.cpp
)

if (EXISTS "${WHISPER_CPP_SOURCE_FILE}" AND EXISTS "${WHISPER_CPP_INCLUDE_DIR}/whisper.h" AND EXISTS "${WHISPER_CPP_DIR}/ggml/CMakeLists.txt")
    message(STATUS "voice2note_whisper: whisper.cpp source found, enabling real inference path.")
    list(APPEND VOICE2NOTE_SOURCES "${WHISPER_CPP_SOURCE_FILE}")
    set(VOICE2NOTE_HAS_WHISPER_CPP 1)
else()
    message(WARNING "voice2note_whisper: whisper.cpp source not found under src/main/cpp/third_party/whisper.cpp; using native stub.")
    set(VOICE2NOTE_HAS_WHISPER_CPP 0)
endif()

add_library(voice2note_whisper SHARED ${VOICE2NOTE_SOURCES})
target_compile_definitions(voice2note_whisper PRIVATE VOICE2NOTE_HAS_WHISPER_CPP=${VOICE2NOTE_HAS_WHISPER_CPP})

if (EXISTS "${WHISPER_CPP_INCLUDE_DIR}/whisper.h")
    target_include_directories(voice2note_whisper PRIVATE "${WHISPER_CPP_INCLUDE_DIR}")
endif()

find_library(log-lib log)
find_library(android-lib android)

if (VOICE2NOTE_HAS_WHISPER_CPP)
    # Android APK içinde libomp.so taşımamak için OpenMP kapalı.
    set(GGML_OPENMP OFF CACHE BOOL "ggml: use OpenMP" FORCE)
    set(GGML_BACKEND_DL OFF CACHE BOOL "ggml: dynamic backends" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "ggml: build shared libraries" FORCE)

    include(FetchContent)
    FetchContent_Declare(
        ggml
        SOURCE_DIR "${WHISPER_CPP_DIR}/ggml"
    )
    FetchContent_MakeAvailable(ggml)

    target_compile_definitions(voice2note_whisper PRIVATE GGML_USE_CPU)
    target_compile_definitions(voice2note_whisper PRIVATE WHISPER_VERSION="dev")
    target_include_directories(voice2note_whisper PRIVATE
        "${WHISPER_CPP_DIR}"
        "${WHISPER_CPP_DIR}/src"
        "${WHISPER_CPP_DIR}/include"
        "${WHISPER_CPP_DIR}/ggml/include"
        "${WHISPER_CPP_DIR}/ggml/src"
        "${WHISPER_CPP_DIR}/ggml/src/ggml-cpu"
    )

    target_link_libraries(voice2note_whisper PRIVATE ${log-lib} ${android-lib} ggml)
else()
    target_link_libraries(voice2note_whisper PRIVATE ${log-lib})
endif()
