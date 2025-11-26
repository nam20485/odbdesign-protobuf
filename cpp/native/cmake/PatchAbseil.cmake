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
    
    # Comment out lines containing absl_random_internal_randen_hwaes_impl
    # This target uses SSE4.1 instructions which aren't supported on ARM
    # Split into lines, process, and rejoin
    string(REPLACE "\n" ";" ABSEIL_LINES "${ABSEIL_CONTENTS}")
    set(MODIFIED_LINES "")
    foreach(LINE ${ABSEIL_LINES})
        if(LINE MATCHES "absl_random_internal_randen_hwaes_impl")
            # Comment out this line
            set(MODIFIED_LINES "${MODIFIED_LINES}# Disabled on ARM: ${LINE}\n")
        else()
            set(MODIFIED_LINES "${MODIFIED_LINES}${LINE}\n")
        endif()
    endforeach()
    
    file(WRITE "${ABSEIL_RANDOM_CMAKE_FILE}" "${MODIFIED_LINES}")
    
    message(STATUS "Patched Abseil random CMakeLists.txt to disable randen_hwaes_impl on ARM macOS")
endif()

