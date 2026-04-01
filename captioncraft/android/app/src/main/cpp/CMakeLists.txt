cmake_minimum_required(VERSION 3.10)
project(whisper_android)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# Locate the whisper.cpp repo.
# Set WHISPER_CPP_DIR env var, or it will search sibling directories.
if(DEFINED ENV{WHISPER_CPP_DIR})
    set(WHISPER_CPP_DIR $ENV{WHISPER_CPP_DIR})
else()
    # Walk up from cpp/ to find a 'whisper' sibling of the project root
    set(_SEARCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    foreach(i RANGE 1 10)
        get_filename_component(_SEARCH_DIR "${_SEARCH_DIR}/.." ABSOLUTE)
        if(EXISTS "${_SEARCH_DIR}/whisper/whisper.cpp/include/whisper.h")
            set(WHISPER_CPP_DIR "${_SEARCH_DIR}/whisper/whisper.cpp")
            break()
        endif()
        if(EXISTS "${_SEARCH_DIR}/../whisper/whisper.cpp/include/whisper.h")
            get_filename_component(WHISPER_CPP_DIR "${_SEARCH_DIR}/../whisper/whisper.cpp" ABSOLUTE)
            break()
        endif()
    endforeach()
endif()

if(NOT WHISPER_CPP_DIR OR NOT EXISTS "${WHISPER_CPP_DIR}/include/whisper.h")
    message(FATAL_ERROR "Could not find whisper.cpp repo. Set WHISPER_CPP_DIR env var to the repo root.")
endif()

message(STATUS "Using whisper.cpp at: ${WHISPER_CPP_DIR}")

# Disable backends we don't need on Android
set(GGML_METAL OFF CACHE BOOL "" FORCE)
set(GGML_CUDA OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_ACCELERATE OFF CACHE BOOL "" FORCE)
set(GGML_BLAS OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_BACKEND_DL OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)

set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

find_library(LOG_LIB log)

include(FetchContent)

# Pull ggml from the whisper.cpp repo's ggml subdirectory
FetchContent_Declare(ggml SOURCE_DIR ${WHISPER_CPP_DIR}/ggml)
FetchContent_MakeAvailable(ggml)

# Build whisper shared library
add_library(whisper SHARED ${WHISPER_CPP_DIR}/src/whisper.cpp)

target_compile_definitions(whisper PUBLIC GGML_USE_CPU)
target_compile_definitions(whisper PRIVATE WHISPER_VERSION="1.8.4")

target_include_directories(whisper PRIVATE
    ${WHISPER_CPP_DIR}
    ${WHISPER_CPP_DIR}/src
    ${WHISPER_CPP_DIR}/include
    ${WHISPER_CPP_DIR}/ggml/include
    ${WHISPER_CPP_DIR}/ggml/src
    ${WHISPER_CPP_DIR}/ggml/src/ggml-cpu
)

# ARM64 optimizations
if(${ANDROID_ABI} STREQUAL "arm64-v8a")
    target_compile_options(whisper PRIVATE -march=armv8.2-a+fp16)
endif()

# Release optimizations
if(NOT ${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    target_compile_options(whisper PRIVATE -O3 -fvisibility=hidden -ffunction-sections -fdata-sections)
    target_link_options(whisper PRIVATE -Wl,--gc-sections -Wl,--exclude-libs,ALL -flto)
endif()

target_compile_options(whisper PRIVATE
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-missing-field-initializers
)

target_link_libraries(whisper ${LOG_LIB} android ggml)
