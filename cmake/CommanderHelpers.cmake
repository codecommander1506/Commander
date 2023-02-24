if (WIN32)
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
endif()

option(BUILD_SHARED_LIBS "Enable/disable shared build" ON)

# Dir creation
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include/Commander)

function(commander_add_executable name)
    add_executable(${name} ${ARGN})
endfunction()

function(commander_add_library name)
    add_library(${name} ${ARGN})
endfunction()

macro(commander_sources target)
    target_sources(${target} PRIVATE ${SOURCES})

    install(FILES ${HEADERS} DESTINATION include/Commander)

    foreach (header ${HEADERS} ${HEADERS2})
        file(CREATE_LINK ${CMAKE_CURRENT_SOURCE_DIR}/${header}
            ${CMAKE_BINARY_DIR}/include/Commander/${header}
        )
    endforeach()

    unset(HEADERS)
    unset(HEADERS2)
    unset(SOURCES)
endmacro()

macro(commander_install type)
    install(${type} ${ARGN})
endmacro()

macro(commander_export)
    foreach (module "" ${ARGN})
        export(
            EXPORT    Commander${module}Export
            NAMESPACE Commander::
            FILE      ${CMAKE_BINARY_DIR}/lib/cmake/Commander/Commander${module}Targets.cmake
        )

        install(
            EXPORT      Commander${module}Export
            NAMESPACE   Commander::
            DESTINATION lib/cmake/Commander
        )
    endforeach()
endmacro()
