cmake_minimum_required(VERSION 3.20)

project(Commander
    DESCRIPTION "Commander"
    VERSION     1.0.0
    LANGUAGES   C CXX
)

# Test
option(Commander_BUILD_TEST "Build Commander test" OFF)

# Documentation
option(Commander_BUILD_DOC "Build Commander documentation" OFF)

# Translations
option(Commander_BUILD_TRANSLATIONS "Build Commander translations" OFF)

# Examples
option(Commander_BUILD_EXAMPLES "Build Commander examples" OFF)

# Package
set(Commander_COMPONENTS Android Wasm)

include(CMakePackageConfigHelpers)

configure_package_config_file(
    CommanderConfig.cmake.in ${CMAKE_BINARY_DIR}/lib/cmake/Commander/CommanderConfig.cmake
    INSTALL_DESTINATION lib/cmake/Commander
)

write_basic_package_version_file(
    ${CMAKE_BINARY_DIR}/lib/cmake/Commander/CommanderConfigVersion.cmake
    VERSION       ${Commander_VERSION}
    COMPATIBILITY SameMajorVersion
    ARCH_INDEPENDENT
)

# External packages
include(cmake/FindQt5.cmake)

# Internal
include(cmake/CommanderHelpers.cmake)

# CXX Variables
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# C Variables
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Output locations
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)

add_subdirectory(src)

if (Commander_BUILD_TEST)
    add_subdirectory(test)
endif()

if (Commander_BUILD_DOC)
    add_subdirectory(doc)
endif()

if (Commander_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# Packaging
commander_export()
