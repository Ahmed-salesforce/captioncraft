cmake_minimum_required(VERSION 3.10)
project(whisper_android)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

add_library(whisper SHARED
    ggml.c
    ggml-alloc.c
    ggml-backend.cpp
    ggml-backend-reg.cpp
    ggml-quants.c
    ggml-threading.cpp
    ggml.cpp
    gguf.cpp
    ggml-cpu/ggml-cpu.c
    ggml-cpu/ggml-cpu.cpp
    ggml-cpu/ops.cpp
    ggml-cpu/vec.cpp
    ggml-cpu/binary-ops.cpp
    ggml-cpu/unary-ops.cpp
    ggml-cpu/traits.cpp
    ggml-cpu/quants.c
    ggml-cpu/repack.cpp
    ggml-cpu/hbm.cpp
    whisper.cpp
)

target_include_directories(whisper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/ggml-cpu
)

target_compile_definitions(whisper PRIVATE
    GGML_USE_CPU
    GGML_VERSION="0.9.8"
    GGML_COMMIT=""
)

target_compile_options(whisper PRIVATE
    -O3
    -DNDEBUG
    -pthread
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-missing-field-initializers
)

target_link_libraries(whisper
    log
    m
)
