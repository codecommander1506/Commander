#Global variables
set(CMAKE_EXECUTABLE_SUFFIX ".js")

set(CMAKE_C_FLAGS "-pipe -g -Wall -Wextra")

set(CMAKE_CXX_FLAGS "-pipe -g -std=gnu++11 -Wall -Wextra")

set(WASM_BROWSER "" CACHE STRING "Browser used for run")

set(WASM_PORT 8000 CACHE STRING "Defautlt server port")

#Locations
find_file(PYTHON_EXECUTABLE python3)

find_file(EMRUN_EXECUTABLE emrun.py)

set(QT_LOADER_JS ${Qt5_DIR}/../../../plugins/platforms/qtloader.js CACHE FILEPATH "qtloader.js file location")

#Macros
macro(_commander_add_wasm_library name)
    add_library(${name} STATIC ${exclude_from_all} ${sources})
endmacro()

macro(_commander_finalize_wasm_library name)
endmacro()

macro(_commander_generate_project_site_index_file file)
    file(WRITE ${file} [=[
        <!DOCTYPE HTML>

        <html>
            <head>
                <title>@SITE_TITLE@</title>

                <meta name="viewport" content="width=device-width, height=device-height, user-scalable=0"/>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <meta charset="UTF-8"/>
            </head>

            <body onload="init()">
                <figure id="qtspinner">
                    <center>
                        <img id="siteIcon" src="icon.png"/>
                        <img id="loadingImage" src="loading.gif"/>

                        <noscript>JavaScript is disabled. Please enable JavaScript to use this application.</noscript>
                    </center>
                </figure>

                <canvas id="qtcanvas" oncontextmenu="event.preventDefault()" contenteditable="true">
                </canvas>

                <script type="text/javascript">

                function init() {
                  var spinner = document.querySelector('#qtspinner');
                  var canvas = document.querySelector('#qtcanvas');
                  var image = document.querySelector('#loadingImage');

                  var qtLoader = QtLoader({
                      canvasElements : [canvas],
                      showLoader: function(loaderStatus) {
                          spinner.style.display = 'block';
                          canvas.style.display = 'none';
                          if (loaderStatus == "Compiling")
                              image.src = "";
                          console.log(loaderStatus);
                      },
                      showError: function(errorText) {
                          spinner.style.display = 'block';
                          canvas.style.display = 'none';
                          image.src = "images/error.png";
                          console.log(errorText);
                      },
                      showExit: function() {
                          spinner.style.display = 'block';
                          canvas.style.display = 'none';
                          console.log("Application exit");
                          if (qtLoader.exitCode !== undefined)
                              console.log(" with code " + qtLoader.exitCode);
                          if (qtLoader.exitText !== undefined)
                              console.log(" (" + qtLoader.exitText + ")");
                      },
                      showCanvas: function() {
                          spinner.style.display = 'none';
                          canvas.style.display = 'block';
                      },
                  });
                  qtLoader.loadEmscriptenModule("@EMSCRIPTEN_MODULE@");
                </script>
                <script type="text/javascript" src="qtloader.js"></script>
            </body>
        </html>
    ]=])
endmacro()

macro(_commander_generate_site_index_file file)
    set(options)
    set(oneValueArgs SITE_TITLE EMSCRIPTEN_MODULE)
    set(multiValueArgs)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(SITE_TITLE ${ARG_SITE_TITLE})

    set(EMSCRIPTEN_MODULE ${ARG_EMSCRIPTEN_MODULE})

    if (NOT EXISTS ${PROJECT_BINARY_DIR}/index.html.in)
        _commander_generate_project_site_index_file(${PROJECT_BINARY_DIR}/index.html.in)
    endif()

    configure_file(${PROJECT_BINARY_DIR}/index.html.in ${file} @ONLY)
endmacro()

macro(commander_add_server_target name)
    set(options)
    set(oneValueArgs BROWSER PORT SITE_SOURCE_DIR)
    set(multiValueArgs DEPENDS)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (ARG_BROWSER)
        set(browser --browser ${ARG_BROWSER})
    elseif (WASM_BROWSER)
        set(browser --browser ${WASM_BROWSER})
    else()
        unset(browser)
    endif()

    if (NOT ARG_PORT AND WASM_PORT)
        set(ARG_PORT ${WASM_PORT})
    else()
        set(ARG_PORT 8000)
    endif()

    if (NOT ARG_SITE_SOURCE_DIR)
        message(FATAL_ERROR "error: site source dir not provided for target ${name}")

        if (NOT EXISTS ${ARG_SITE_SOURCE_DIR}/index.html)
            message(FATAL_ERROR "error: site source dir provided for target ${name} didn't contains index.html file")
        endif()
    endif()

    add_custom_target(${name}
        COMMAND ${PYTHON_EXECUTABLE} ${EMRUN_EXECUTABLE}
            ${browser}
            --port ${ARG_PORT}
            --no_emrun_detect
            --serve_after_close
            ${ARG_SITE_SOURCE_DIR}/index.html
        DEPENDS ${ARG_DEPENDS}
    )
endmacro()

macro(_commander_register_wasm_executable name)
endmacro()

macro(_commander_finalize_wasm_executable name)
    get_target_property(site_source_dir ${name} SITE_SOURCE_DIR)

    if (NOT site_source_dir AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/wasm/index.html)
        set(site_source_dir ${CMAKE_CURRENT_SOURCE_DIR}/wasm)
    endif()

    get_target_property(output_name ${name} OUTPUT_NAME)

    if (NOT output_name)
        set(output_name ${name})
    endif()

    if (site_source_dir)
        file(COPY ${site_source_dir}/ ${QT_LOADER_JS} DESTINATION ${name}_wasm
            PATTERN "index.html" EXCLUDE
        )

        set(EMSCRIPTEN_MODULE ${output_name})

        configure_file(${site_source_dir}/index.html ${name}_wasm/index.html @ONLY)

        file(CREATE_LINK ${name}_wasm/index.html index.html SYMBOLIC)

        commander_add_server_target(${name}-server
            SITE_SOURCE_DIR ${name}_wasm
            DEPENDS ${name}
        )

        set(sources ${site_source_dir}/index.html)

        if (EXISTS ${site_source_dir}style.css)
            list(APPEND sources ${site_source_dir}/style.css)
        endif()

        if (EXISTS ${site_source_dir}script.js)
            list(APPEND sources ${site_source_dir}/script.js)
        endif()

        target_sources(${name}-server PRIVATE ${sources})

        install(DIRECTORY ${name}_wasm DESTINATION public/${name})
    endif()
endmacro()
