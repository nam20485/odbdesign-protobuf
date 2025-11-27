cmake_minimum_required(VERSION 3.20)

project(protobuf_tools VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include(FetchContent)

# Set CMake policy to handle older CMakeLists.txt files in dependencies
if(POLICY CMP0144)
    cmake_policy(SET CMP0144 NEW)
endif()

set(ABSL_PROPAGATE_CXX_STD ON)
set(ABSL_ENABLE_INSTALL OFF CACHE BOOL "Disable Abseil install rules" FORCE)
# Disable SSE optimizations on ARM macOS to avoid compilation errors
# This must be set before FetchContent processes Abseil
if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    set(ABSL_RANDOM_INTERNAL_RANDEN_HWAES_IMPL "generic" CACHE STRING "Use generic implementation on ARM macOS" FORCE)
    set(ABSL_RANDOM_HWAES_IMPL "generic" CACHE STRING "Use generic implementation on ARM macOS" FORCE)
endif()

set(protobuf_BUILD_TESTS OFF CACHE BOOL "Disable protobuf tests" FORCE)
set(protobuf_WITH_ZLIB OFF CACHE BOOL "Disable protobuf zlib dependency" FORCE)
set(protobuf_INSTALL OFF CACHE BOOL "Disable protobuf install rules" FORCE)

set(gRPC_INSTALL OFF CACHE BOOL "Disable gRPC install rules" FORCE)
set(gRPC_BUILD_TESTS OFF CACHE BOOL "Disable gRPC tests" FORCE)
set(gRPC_BUILD_CSHARP_EXT OFF CACHE BOOL "" FORCE)
set(gRPC_BUILD_GRPC_CSHARP_PLUGIN OFF CACHE BOOL "" FORCE)
# Use system zlib - "module" has compatibility issues with macOS SDK headers,
# "none" causes undefined symbols. All platforms have system zlib available.
set(gRPC_ZLIB_PROVIDER "package" CACHE STRING "Use system zlib" FORCE)

set(GRPC_PATCH_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/../native/cmake/PatchCares.cmake")
set(ABSEIL_PATCH_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/../native/cmake/PatchAbseil.cmake")

FetchContent_Declare(
    gRPC
    GIT_REPOSITORY https://github.com/grpc/grpc.git
    GIT_TAG v1.66.0
)

FetchContent_GetProperties(gRPC)
if(NOT gRPC_POPULATED)
    FetchContent_Populate(gRPC)
    # FetchContent_Populate should set gRPC_SOURCE_DIR and gRPC_BINARY_DIR, but if not available,
    # use the default FetchContent locations: ${CMAKE_BINARY_DIR}/_deps/<name>-src and <name>-build
    # For mixed-case "gRPC", CMake may use lowercase "grpc" in the path
    if(NOT DEFINED gRPC_SOURCE_DIR)
        # Try the default FetchContent location
        set(gRPC_SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/grpc-src")
        if(NOT EXISTS "${gRPC_SOURCE_DIR}")
            # Try with exact case
            set(gRPC_SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/gRPC-src")
        endif()
        if(NOT EXISTS "${gRPC_SOURCE_DIR}")
            message(FATAL_ERROR "Could not determine gRPC source directory. Checked: ${CMAKE_BINARY_DIR}/_deps/grpc-src and ${CMAKE_BINARY_DIR}/_deps/gRPC-src")
        endif()
    endif()
    if(NOT DEFINED gRPC_BINARY_DIR)
        # Set binary directory to match source directory pattern
        if(gRPC_SOURCE_DIR MATCHES "grpc-src$")
            set(gRPC_BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/grpc-build")
        else()
            set(gRPC_BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/gRPC-build")
        endif()
    endif()
    # Set GRPC_SOURCE_DIR for patch scripts (they expect this variable name)
    set(GRPC_SOURCE_DIR "${gRPC_SOURCE_DIR}")
    if(EXISTS "${GRPC_PATCH_SCRIPT}")
        include(${GRPC_PATCH_SCRIPT})
    endif()
    # Patch Abseil to disable SSE targets on ARM macOS
    if(EXISTS "${ABSEIL_PATCH_SCRIPT}")
        include(${ABSEIL_PATCH_SCRIPT})
    endif()
    # Re-query to populate gRPC_SOURCE_DIR / gRPC_BINARY_DIR for later use
    FetchContent_GetProperties(gRPC)
endif()

add_subdirectory(${gRPC_SOURCE_DIR} ${gRPC_BINARY_DIR} EXCLUDE_FROM_ALL)

# On ARM macOS, remove SSE flags from problematic Abseil targets
if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    foreach(TARGET_NAME absl_random_internal_randen_hwaes_impl absl_random_internal_randen_hwaes)
        if(TARGET ${TARGET_NAME})
            # Remove SSE compile flags from this target
            get_target_property(TARGET_FLAGS ${TARGET_NAME} COMPILE_OPTIONS)
            if(TARGET_FLAGS)
                list(REMOVE_ITEM TARGET_FLAGS "-msse4.1" "/arch:SSE2" "/arch:SSE")
                set_target_properties(${TARGET_NAME} PROPERTIES COMPILE_OPTIONS "${TARGET_FLAGS}")
            endif()
            # Exclude from build to prevent SSE compilation
            set_target_properties(${TARGET_NAME} PROPERTIES EXCLUDE_FROM_ALL TRUE)
        endif()
    endforeach()
endif()

# Tools will be built as part of gRPC/protobuf dependencies
# We just need to ensure they're built and accessible
# The workflow will find them in the build directory after building these targets

