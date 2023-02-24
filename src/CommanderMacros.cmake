#CMake version 3.19 or higher required for defered calls (target finalizaion)
cmake_minimum_required(VERSION 3.19)

include(${CMAKE_CURRENT_LIST_DIR}/CommanderPlatformSupport.cmake)

# Macros

if (ANDROID)
    include(${CMAKE_CURRENT_LIST_DIR}/CommanderAndroidMacros.cmake)
elseif (WASM)
    include(${CMAKE_CURRENT_LIST_DIR}/CommanderWasmMacros.cmake)
else()
    function(commander_add_executable name)
        add_executable(${name} ${ARGN})
        _commander_register_target(${name})
    endfunction()

    function(commander_add_library name)
        add_library(${name} ${ARGN})
        _commander_register_target(${name})
    endfunction()
endif()

function(target_files target)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs HEADERS SOURCES FORMS RESOURCES TRANSLATIONS)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (ARG_HEADERS)
        get_target_property(dir ${target} DISPLAY_NAME)

        if (NOT dir OR ${PROJECT_NAME} STREQUAL ${dir})
            set(dir ${PROJECT_NAME})
        else()
            set(dir ${PROJECT_NAME}${dir})
        endif()

        unset(PUBLIC_HEADERS)
        unset(PRIVATE_HEADERS)

        foreach (header ${ARG_HEADERS})
            get_source_file_property(PRIVATE ${header} PRIVATE)

            if (NOT PRIVATE)
                list(APPEND PUBLIC_HEADERS ${header})
            else()
                list(APPEND PRIVATE_HEADERS ${header})
            endif()

        endforeach()

        commander_generate_nested_headers(${${CMAKE_PROJECT_NAME}_BINARY_DIR}/include/${dir} ${PUBLIC_HEADERS})
        commander_generate_nested_headers(${${CMAKE_PROJECT_NAME}_BINARY_DIR}/include/${dir}/private ${PRIVATE_HEADERS})
        install(FILES ${PUBLIC_HEADERS} DESTINATION include/${dir})
    endif()

    if (ARG_SOURCES OR ARG_FORMS OR ARG_RESOURCES)
        target_sources(${target} PRIVATE ${ARG_SOURCES} ${ARG_FORMS} ${ARG_RESOURCES})
    endif()

    if (ARG_TRANSLATIONS)
        set_target_properties(${target} PROPERTIES TRANSLATIONS "${TRANSLATIONS}")
    endif()
endfunction()
