cmake_minimum_required(VERSION 3.10)
project(whisper_android)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

add_library(whisper SHARED
    whisper.cpp
    ggml.c
    ggml-alloc.c
    ggml-backend.c
    ggml-quants.c
)

target_compile_options(whisper PRIVATE
    -O3
    -DNDEBUG
    -pthread
)

target_link_libraries(whisper
    log
    m
)
