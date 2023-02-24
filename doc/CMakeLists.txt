configure_file(Doxyfile.in Doxyfile)

find_package(Doxygen REQUIRED)

find_program(qhelpgenerator qhelpgenerator REQUIRED)

add_custom_target(commander_doc ALL
    Doxygen::doxygen  Doxyfile
    SOURCES           Doxyfile.in
)

add_dependencies(commander_doc commander)

install(DIRECTORY ${CMAKE_BINARY_DIR}/doc/Commander DESTINATION doc)
