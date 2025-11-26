if(NOT DEFINED GRPC_SOURCE_DIR)
    message(FATAL_ERROR "GRPC_SOURCE_DIR not provided to PatchAbseil.cmake")
endif()

# Check if we're on ARM macOS
if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    set(ABSEIL_RANDOM_CMAKE_FILE "${GRPC_SOURCE_DIR}/third_party/abseil-cpp/absl/random/CMakeLists.txt")
    
    if(NOT EXISTS "${ABSEIL_RANDOM_CMAKE_FILE}")
        message(WARNING "Abseil random CMakeLists.txt not found at ${ABSEIL_RANDOM_CMAKE_FILE}")
        return()
    endif()
    
    file(READ "${ABSEIL_RANDOM_CMAKE_FILE}" ABSEIL_CONTENTS)
    
    # Comment out or remove the absl_random_internal_randen_hwaes_impl target
    # This target uses SSE4.1 instructions which aren't supported on ARM
    string(REGEX REPLACE
        "(add_library\\(absl_random_internal_randen_hwaes_impl[^)]*\\))"
        "# Disabled on ARM: \\1"
        ABSEIL_CONTENTS
        "${ABSEIL_CONTENTS}"
    )
    
    # Also comment out any references to this target
    string(REGEX REPLACE
        "(absl::random_internal_randen_hwaes_impl)"
        "# absl::random_internal_randen_hwaes_impl # Disabled on ARM"
        ABSEIL_CONTENTS
        "${ABSEIL_CONTENTS}"
    )
    
    file(WRITE "${ABSEIL_RANDOM_CMAKE_FILE}" "${ABSEIL_CONTENTS}")
    
    message(STATUS "Patched Abseil random CMakeLists.txt to disable randen_hwaes_impl on ARM macOS")
endif()

