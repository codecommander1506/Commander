if (NOT EXISTS ${Commander_SOURCE_DIR}/translations)
    file(MAKE_DIRECTORY ${Commander_SOURCE_DIR}/translations)
endif()

get_target_property(TS_FILES commander LOCALES)

list(TRANSFORM TS_FILES PREPEND ${Commander_SOURCE_DIR}/translations/commander_)
list(TRANSFORM TS_FILES APPEND  .ts)

qt5_create_translation(QM_FILES ${CMAKE_CURRENT_SOURCE_DIR} ${TS_FILES})

target_sources(commander PRIVATE ${QM_FILES})

install(FILES ${QM_FILES} DESTINATION translations)
