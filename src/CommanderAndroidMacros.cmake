include(${CMAKE_CURRENT_LIST_DIR}/CommanderAndroidSupport.cmake)

function(commander_add_android_executable name)
    add_library(${name} SHARED ${ARGN})

    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/android/AndroidManifest.xml)
        set_target_properties(${name} PROPERTIES ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android)
    endif()

    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/qml/main.qml)
        set_target_properties(${name} PROPERTIES QML_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/qml)
    endif()

    set_target_properties(${name}
        PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${name}_android/android-build/libs/${ANDROID_ABI}
            ANDROID_BUILD_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${name}_android/android-build
    )

    if (Qt5AndroidExtras_FOUND)
        target_link_libraries(${name} PRIVATE Qt5::AndroidExtras)
    endif()

    _commander_register_android_executable(${name} PARENT_SCOPE)
endfunction()

function(commander_add_android_library name)
    add_library(${name} ${ARGN})

    _commander_register_android_target(${name} PARENT_SCOPE)
endfunction()

# Convenience functions

macro(commander_add_executable name)
    set(options WIN32 MACOSX_BUNDLE)
    set(oneValueArgs)
    set(multiValueArgs)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    commander_add_android_executable(${name} ${ARG_UNPARSED_ARGUMENTS})
endmacro()

macro(commander_add_library name)
    commander_add_android_library(${name} ${ARGN})
endmacro()
