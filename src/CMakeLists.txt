commander_add_library(commander)

set_target_properties(commander
    PROPERTIES
        DISPLAY_NAME Commander
        VERSION      ${Commander_VERSION}
        SOVERSION    ${Commander_VERSION}
        LOCALES      fr
)

target_include_directories(commander
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_link_libraries(commander PUBLIC Qt5::Core)

if (BUILD_SHARED_LIBS)
    set(BUILD_TYPE SHARED)
else()
    set(BUILD_TYPE STATIC)
endif()

target_compile_definitions(commander
    PUBLIC  COMMANDER_${BUILD_TYPE} COMMANDER_LIB
    PRIVATE BUILD_COMMANDER_LIB
)

add_subdirectory(kernel)

if (Commander_BUILD_TRANSLATIONS)
    include(translations.cmake)
endif()

set(CMAKE_FILES
    CommanderMacros.cmake CommanderPlatformSupport.cmake
    CommanderAndroidMacros.cmake CommanderAndroidSupport.cmake
    CommanderWasmMacros.cmake CommanderWasmSupport.cmake
)

file(COPY ${CMAKE_FILES} DESTINATION ${CMAKE_BINARY_DIR}/lib/cmake/Commander)

commander_install(FILES ${CMAKE_FILES} DESTINATION lib/cmake/Commander)

commander_install(TARGETS commander EXPORT CommanderExport)

