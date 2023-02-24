configure_file(config.h.in ${CMAKE_CURRENT_SOURCE_DIR}/config.h @ONLY)

set(HEADERS 
    config.h global.h
    debug.h
)

set(HEADERS2
)

set(SOURCES
    debug.cpp
)

commander_sources(commander)
