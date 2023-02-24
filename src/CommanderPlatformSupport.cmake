# Wasm platform detection
string(FIND ${CMAKE_CXX_COMPILER} "em++" WASM_FOUND)

if (WASM_FOUND GREATER_EQUAL 0)
    set(WASM ON)
endif()

unset(WASM_FOUND)

# Global targets

if (NOT TARGET translations)
    add_custom_target(translations)
endif()

# Other
function(commander_generate_nested_headers dir)
    foreach (header ${ARGN})
        if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${header})
            set(header ${CMAKE_CURRENT_SOURCE_DIR}/${header})
        endif()

        string(FIND ${header} / pos REVERSE)
        string(SUBSTRING ${header} ${pos} -1 file)
        set(file ".${file}")

        file(RELATIVE_PATH path ${dir} ${header})
        file(WRITE ${dir}/${file} "#include \"${path}\"")
    endforeach()
endfunction()

function(commander_add_translation_target name base_target)
    get_target_property(LUPDATE_EXECUTABLE Qt5::lupdate IMPORTED_LOCATION)
    get_target_property(LRELEASE_EXECUTABLE Qt5::lrelease IMPORTED_LOCATION)

    set(TS_FILES ${ARGN})
    list(TRANSFORM TS_FILES PREPEND ${CMAKE_CURRENT_SOURCE_DIR}/)

    if (ANDROID)
        get_target_property(OUTPUT_DIR ${base_target} ANDROID_BUILD_DIRECTORY)

        if (OUTPUT_DIR)
            set(OUTPUT_DIR ${OUTPUT_DIR}/assets/translations)
        endif()
    else()
        unset(OUTPUT_DIR)
    endif()

    if (OUTPUT_DIR)
        if (NOT EXISTS OUTPUT_DIR)
            file(MAKE_DIRECTORY ${OUTPUT_DIR})
        endif()
    elseif (CMAKE_TRANSLATION_OUTPUT_DIRECTORY)
        set(OUTPUT_DIR ${CMAKE_TRANSLATION_OUTPUT_DIRECTORY})
    else()
        set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    get_target_property(SOURCE_DIR ${target} SOURCE_DIR)

    set(FILES ${ARGN})
    list(TRANSFORM FILES REPLACE ".ts" "")

    unset(COMMANDS)
    foreach(file ${FILES})
        list(APPEND COMMANDS COMMAND ${LRELEASE_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/${file}.ts -qm ${file}.qm)
    endforeach()

    add_custom_target(${name}
        COMMAND ${LUPDATE_EXECUTABLE} ${SOURCE_DIR} -ts ${TS_FILES}
        ${COMMANDS}
        WORKING_DIRECTORY ${OUTPUT_DIR}
        SOURCES ${ARGN}
    )

    add_dependencies(${base_target} ${name})
    add_dependencies(translations ${name})
endfunction()

macro(_commander_register_target name)
    set(COMMANDER_TARGETS ${COMMANDER_TARGETS} ${name} ${ARGN})
    cmake_language(DEFER CALL _commander_finalize_targets)
endmacro()

macro(_commander_finalize_targets)
    foreach (target ${COMMANDER_TARGETS})
        get_target_property(TRANSLATIONS ${target} TRANSLATIONS)

        if (TRANSLATIONS)
            commander_add_translation_target(${target}-translations ${target} ${TRANSLATIONS})
        endif()
    endforeach()

    unset(COMMANDER_TARGETS ${ARGN})
endmacro()
