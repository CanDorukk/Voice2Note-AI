cmake_minimum_required(VERSION 3.18.1)
project(voice2note_whisper LANGUAGES CXX)

set(WHISPER_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/whisper.cpp")
set(WHISPER_CPP_INCLUDE_DIR "${WHISPER_CPP_DIR}/include")
set(WHISPER_CPP_SOURCE_FILE "${WHISPER_CPP_DIR}/src/whisper.cpp")

set(VOICE2NOTE_SOURCES
    voice2note_whisper.cpp
)

if (EXISTS "${WHISPER_CPP_SOURCE_FILE}" AND EXISTS "${WHISPER_CPP_INCLUDE_DIR}/whisper.h")
    message(STATUS "voice2note_whisper: whisper.cpp source found, enabling real inference path.")
    list(APPEND VOICE2NOTE_SOURCES "${WHISPER_CPP_SOURCE_FILE}")
    add_compile_definitions(VOICE2NOTE_HAS_WHISPER_CPP=1)
else()
    message(WARNING "voice2note_whisper: whisper.cpp source not found under src/main/cpp/third_party/whisper.cpp; using native stub.")
    add_compile_definitions(VOICE2NOTE_HAS_WHISPER_CPP=0)
endif()

add_library(voice2note_whisper SHARED ${VOICE2NOTE_SOURCES})

if (EXISTS "${WHISPER_CPP_INCLUDE_DIR}/whisper.h")
    target_include_directories(voice2note_whisper PRIVATE "${WHISPER_CPP_INCLUDE_DIR}")
endif()

find_library(log-lib log)
target_link_libraries(voice2note_whisper PRIVATE ${log-lib})
