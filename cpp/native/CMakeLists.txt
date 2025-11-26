cmake_minimum_required(VERSION 3.20)

project(odbdesign_protobuf_native VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(GENERATED_CPP_DIR "${CMAKE_SOURCE_DIR}/../../generated/cpp")
if(NOT EXISTS "${GENERATED_CPP_DIR}")
    message(FATAL_ERROR "Generated C++ sources not found at ${GENERATED_CPP_DIR}. Run scripts/generate_protos.sh first or download the protobuf-cpp artifact.")
endif()

file(GLOB_RECURSE GENERATED_CPP_SOURCES
     CONFIGURE_DEPENDS
     "${GENERATED_CPP_DIR}/*.cc")

if(GENERATED_CPP_SOURCES STREQUAL "")
    message(FATAL_ERROR "No generated C++ sources discovered under ${GENERATED_CPP_DIR}.")
endif()

include(FetchContent)

# Set CMake policy to handle older CMakeLists.txt files in dependencies
if(POLICY CMP0144)
    cmake_policy(SET CMP0144 NEW)
endif()

set(ABSL_PROPAGATE_CXX_STD ON)
set(ABSL_ENABLE_INSTALL OFF CACHE BOOL "Disable Abseil install rules" FORCE)

set(protobuf_BUILD_TESTS OFF CACHE BOOL "Disable protobuf tests" FORCE)
set(protobuf_WITH_ZLIB OFF CACHE BOOL "Disable protobuf zlib dependency" FORCE)
set(protobuf_INSTALL OFF CACHE BOOL "Disable protobuf install rules" FORCE)

set(gRPC_INSTALL OFF CACHE BOOL "Disable gRPC install rules" FORCE)
set(gRPC_BUILD_TESTS OFF CACHE BOOL "Disable gRPC tests" FORCE)
set(gRPC_BUILD_CSHARP_EXT OFF CACHE BOOL "" FORCE)
set(gRPC_BUILD_GRPC_CSHARP_PLUGIN OFF CACHE BOOL "" FORCE)
set(gRPC_ZLIB_PROVIDER "none" CACHE STRING "Disable zlib in gRPC to avoid macOS compilation issues" FORCE)

set(GRPC_PATCH_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PatchCares.cmake")

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
    # Set GRPC_SOURCE_DIR for PatchCares.cmake (it expects this variable name)
    set(GRPC_SOURCE_DIR "${gRPC_SOURCE_DIR}")
    include(${GRPC_PATCH_SCRIPT})
    # Re-query to populate gRPC_SOURCE_DIR / gRPC_BINARY_DIR for later use
    FetchContent_GetProperties(gRPC)
endif()

add_subdirectory(${gRPC_SOURCE_DIR} ${gRPC_BINARY_DIR} EXCLUDE_FROM_ALL)

set(GRPC_CPP_LIB_TARGET "")
if(TARGET gRPC::grpc++)
    set(GRPC_CPP_LIB_TARGET gRPC::grpc++)
elseif(TARGET grpc++)
    set(GRPC_CPP_LIB_TARGET grpc++)
else()
    message(FATAL_ERROR "gRPC++ target not found. Ensure gRPC is available via FetchContent or find_package.")
endif()

add_library(odbdesign_protobuf_native SHARED
    ${GENERATED_CPP_SOURCES}
    src/ProtobufApi.cpp
)

if(MSVC)
    target_compile_definitions(odbdesign_protobuf_native PRIVATE _WIN32_WINNT=0x0A00)
endif()

target_compile_definitions(odbdesign_protobuf_native
    PRIVATE ODBDESIGN_PROTOBUF_NATIVE_BUILD
)

target_include_directories(odbdesign_protobuf_native
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${GENERATED_CPP_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/generated>
)

target_link_libraries(odbdesign_protobuf_native
    PUBLIC
        ${GRPC_CPP_LIB_TARGET}
        protobuf::libprotobuf
)

set_target_properties(odbdesign_protobuf_native PROPERTIES
    OUTPUT_NAME "odbdesign_protobuf_native"
    WINDOWS_EXPORT_ALL_SYMBOLS OFF
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN YES
)

include(GNUInstallDirs)

install(TARGETS odbdesign_protobuf_native
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(DIRECTORY ${GENERATED_CPP_DIR}/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/generated
    FILES_MATCHING
        PATTERN "*.pb.h"
        PATTERN "*.grpc.pb.h"
)
