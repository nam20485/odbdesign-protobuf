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
set(gRPC_INSTALL ON)
set(gRPC_BUILD_TESTS OFF)
set(gRPC_BUILD_CSHARP_EXT OFF)
set(gRPC_BUILD_GRPC_CSHARP_PLUGIN OFF)
set(ABSL_PROPAGATE_CXX_STD ON)

FetchContent_Declare(
    gRPC
    GIT_REPOSITORY https://github.com/grpc/grpc.git
    GIT_TAG v1.63.0
)

FetchContent_MakeAvailable(gRPC)

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
        gRPC::grpc++
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
