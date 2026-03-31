cmake_minimum_required(VERSION 3.18.1)
project(voice2note_whisper LANGUAGES CXX)

add_library(voice2note_whisper SHARED voice2note_whisper.cpp)

find_library(log-lib log)
target_link_libraries(voice2note_whisper PRIVATE ${log-lib})
