if(NOT DEFINED GRPC_SOURCE_DIR)
    message(FATAL_ERROR "GRPC_SOURCE_DIR not provided to PatchCares.cmake")
endif()

if(NOT DEFINED CARES_MIN_VERSION)
    set(CARES_MIN_VERSION 3.5)
endif()

set(CARES_CMAKE_FILE "${GRPC_SOURCE_DIR}/third_party/cares/cares/CMakeLists.txt")

if(NOT EXISTS "${CARES_CMAKE_FILE}")
    message(WARNING "c-ares CMakeLists.txt not found at ${CARES_CMAKE_FILE}")
    return()
endif()

file(READ "${CARES_CMAKE_FILE}" CARES_CONTENTS)

string(REGEX REPLACE
    "cmake_minimum_required\\(VERSION [0-9]+\\.[0-9]+\\)"
    "cmake_minimum_required(VERSION ${CARES_MIN_VERSION})"
    CARES_CONTENTS
    "${CARES_CONTENTS}"
)

file(WRITE "${CARES_CMAKE_FILE}" "${CARES_CONTENTS}")

message(STATUS "Patched c-ares CMakeLists.txt to require CMake ${CARES_MIN_VERSION}+")

