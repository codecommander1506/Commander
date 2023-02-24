include(${CMAKE_CURRENT_LIST_DIR}/CommanderPlatformSupport.cmake)

#Detect Qt
find_library(Qt5Core_${ANDROID_ABI}_Probe Qt5Core_${ANDROID_ABI})

#Global variables
set(${PROJECT_NAME}-MultiAbiBuild ON CACHE INTERNAL "" FORCE)

set(CMAKE_SHARED_MODULE_SUFFIX_CXX "_${ANDROID_ABI}.so")
set(CMAKE_SHARED_LIBRARY_SUFFIX_CXX "_${ANDROID_ABI}.so")
set(CMAKE_SHARED_MODULE_SUFFIX_C "_${ANDROID_ABI}.so")
set(CMAKE_SHARED_LIBRARY_SUFFIX_C "_${ANDROID_ABI}.so")

# Match Android's sysroots
set(ANDROID_SYSROOT_armeabi-v7a arm-linux-androideabi)
set(ANDROID_SYSROOT_arm64-v8a aarch64-linux-android)
set(ANDROID_SYSROOT_x86 i686-linux-android)
set(ANDROID_SYSROOT_x86_64 x86_64-linux-android)

if(NOT ANDROID_SDK)
  get_filename_component(ANDROID_SDK ${ANDROID_NDK}/../ ABSOLUTE)
endif()

find_program(ANDROID_DEPLOY_QT androiddeployqt)
get_filename_component(QT_DIR ${ANDROID_DEPLOY_QT}/../../ ABSOLUTE)

#Options
set(ANDROID_ABIS armeabi-v7a arm64-v8a x86 x86_64)

set(ANDROID_ABI armeabi-v7a CACHE STRING "Android ABI")

set_property(CACHE ANDROID_ABI PROPERTY STRINGS ${ANDROID_ABIS})

option(ANDROID_BUILD_AAB "Enable/disable AAB build" OFF)

# Global targets
if (NOT TARGET apk)
    add_custom_target(apk)
endif()

# Deployment settings file stuff
function(_commander_write_android_project_deployment_settings_file file)
    file(WRITE ${file}
    [=[{
    "_description": "This file is created by CMake to be read by androiddeployqt and should not be modified by hand.",
    "application-binary": "@QT_ANDROID_APPLICATION_BINARY@",
    "architectures": {
      @QT_ANDROID_ARCHITECTURES@
    },
    @QT_ANDROID_DEPLOYMENT_DEPENDENCIES@
    @QT_ANDROID_EXTRA_PLUGINS@
    @QT_ANDROID_PACKAGE_SOURCE_DIR@
    @QT_ANDROID_VERSION_CODE@
    @QT_ANDROID_VERSION_NAME@
    @QT_ANDROID_EXTRA_LIBS@
    @QT_QML_IMPORT_PATH@
    "ndk": "@ANDROID_NDK@",
    "ndk-host": "@ANDROID_HOST_TAG@",
    "qml-root-path": "@QML_ROOT_PATH@",
    "qt": "@QT_DIR@",
    "sdk": "@ANDROID_SDK@",
    "stdcpp-path": "@ANDROID_TOOLCHAIN_ROOT@/sysroot/usr/lib/",
    "tool-prefix": "llvm",
    "toolchain-prefix": "llvm",
    "useLLVM": true
    }]=])
endfunction()

function(commander_generate_android_deployment_settings_file file)
    set(options)
    set(oneValueArgs APPLICATION_BINARY PACKAGE_SOURCE_DIR VERSION_CODE VERSION_NAME QML_ROOT_PATH)
    set(multiValueArgs ARCHITECTURES DEPLOYMENT_DEPENDENCIES EXTRA_PLUGINS EXTRA_LIBS QML_IMPORT_PATH)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARG_APPLICATION_BINARY)
        message(FATAL_ERROR "application binary not specified")
    else()
        set(QT_ANDROID_APPLICATION_BINARY ${ARG_APPLICATION_BINARY})
    endif()

    set(PROPERTIES
        DEPLOYMENT_DEPENDENCIES
        EXTRA_PLUGINS
        PACKAGE_SOURCE_DIR
        VERSION_CODE
        VERSION_NAME
        EXTRA_LIBS
    )

    foreach (property ${PROPERTIES})
        if (ARG_${property})
            set(ANDROID_${property} ${ARG_${property}})
        else()
            unset(ANDROID_${property})
        endif()
    endforeach()

    if (NOT ARG_ARCHITECTURES)
        set(ARG_ARCHITECTURES ${ANDROID_ABI})
    endif()

    if (ARG_QML_ROOT_PATH)
        set(QML_ROOT_PATH ${ARG_QML_ROOT_PATH})
    else()
        set(QML_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    unset(QT_ANDROID_ARCHITECTURES)
    foreach(abi IN LISTS ARG_ARCHITECTURES)
        list(APPEND QT_ANDROID_ARCHITECTURES "\"${abi}\" : \"${ANDROID_SYSROOT_${abi}}\"")
    endforeach()
    string(REPLACE ";" ",\n" QT_ANDROID_ARCHITECTURES "${QT_ANDROID_ARCHITECTURES}")

    if (ARG_QML_IMPORT_PATH)
        set(QML_IMPORT_PATH ${ARG_QML_IMPORT_PATH})
    else()
        unset(QML_IMPORT_PATH)
    endif()

    macro(generate_json_variable_list var_list json_key)
      if (${var_list})
        set(QT_${var_list} "\"${json_key}\": \"")
        string(REPLACE ";" "," joined_var_list "${${var_list}}")
        string(APPEND QT_${var_list} "${joined_var_list}\",")
      endif()
    endmacro()

    macro(generate_json_variable var json_key)
      if (${var})
        set(QT_${var} "\"${json_key}\": \"${${var}}\",")
      endif()
    endmacro()

    generate_json_variable_list(ANDROID_DEPLOYMENT_DEPENDENCIES "deployment-dependencies")
    generate_json_variable_list(ANDROID_EXTRA_PLUGINS "android-extra-plugins")
    generate_json_variable(ANDROID_PACKAGE_SOURCE_DIR "android-package-source-directory")
    generate_json_variable(ANDROID_VERSION_CODE "android-version-code")
    generate_json_variable(ANDROID_VERSION_NAME "android-version-name")
    generate_json_variable_list(ANDROID_EXTRA_LIBS "android-extra-libs")
    generate_json_variable_list(QML_IMPORT_PATH "qml-import-paths")
    #generate_json_variable_list(ANDROID_MIN_SDK_VERSION "android-min-sdk-version")
    #generate_json_variable_list(ANDROID_TARGET_SDK_VERSION "android-target-sdk-version")

    if (NOT EXISTS ${PROJECT_BINARY_DIR}/android/android_deployment_settings.json.in)
        _commander_write_android_project_deployment_settings_file(${PROJECT_BINARY_DIR}/android/android_deployment_settings.json.in)
    endif()

    configure_file(${PROJECT_BINARY_DIR}/android/android_deployment_settings.json.in ${file} @ONLY)
endfunction()

# Apk target stuff

function(commander_add_android_apk_target name)
    set(options AAB)
    set(oneValueArgs BASE_TARGET INPUT OUTPUT APK)
    set(multiValueArgs)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT ARG_BASE_TARGET)
        message(FATAL_ERROR "base target not provided")
    endif()

    if (ARG_AAB)
        set(aab --aab)
    else()
        unset(aab)
    endif()

    if (NOT ARG_INPUT)
        message(FATAL_ERROR "input file not specified")
    endif()

    if (NOT ARG_OUTPUT)
        message(FATAL_ERROR "output dir not specified")
    endif()

    if (NOT ARG_APK)
        message(FATAL_ERROR "output apk file not specified")
    endif()

    get_target_property(PACKAGE_SOURCE_DIR ${ARG_BASE_TARGET} ANDROID_PACKAGE_SOURCE_DIR)

    if (PACKAGE_SOURCE_DIR)
        set(FILES AndroidManifest.xml)

        if (EXISTS ${PACKAGE_SOURCE_DIR}/gradle.properties)
            list(APPEND FILES gradle.properties)
        endif()

        if (EXISTS ${PACKAGE_SOURCE_DIR}/build.gradle)
            list(APPEND FILES build.gradle)
        endif()

        list(TRANSFORM FILES PREPEND ${PACKAGE_SOURCE_DIR}/)

        set(SOURCES SOURCES ${FILES})
    else()
        unset(SOURCES)
    endif()

    get_target_property(keystore ${ARG_BASE_TARGET} ANDROID_KEYSTORE_PATH)
    get_target_property(alias ${ARG_BASE_TARGET}    ANDROID_KEYSTORE_ALIAS)
    get_target_property(password ${ARG_BASE_TARGET} ANDROID_KEYSTORE_PASSWORD)

    if (keystore AND password AND alias)
        set(signing --sign file:///${keystore} ${alias} --storepass ${password})
    else()
        unset(signing)
    endif()

    if (CMAKE_BUILD_TYPE IN_LIST "Release;RelWithDebInfo;MinSizeRel")
        set(release --release)
    else()
        unset(release)
    endif()

    add_custom_target(${name} ALL
        COMMAND ${CMAKE_COMMAND} -E env JAVA_HOME=${JAVA_HOME} ${ANDROID_DEPLOY_QT}
            --input "${ARG_INPUT}"
            --output "${ARG_OUTPUT}"
            --apk "${ARG_APK}"
            ${aab}
            ${signing}
            ${release}
            ${android_deploy_qt_platform}
            ${android_deploy_qt_jdk}
        DEPENDS ${ARG_BASE_TARGET}
        VERBATIM
        ${SOURCES}
    )

    set_target_properties(${ARG_BASE_TARGET}
        PROPERTIES
            ADDITIONAL_CLEAN_FILES "${ARG_INPUT};${ARG_OUTPUT};${target}_android/${ARG_APK}"
    )

    add_dependencies(apk ${name})
endfunction()

# Other stuff

function(commander_generate_android_target_deployment_file target file)
    set(PROPERTIES
        APPLICATION_BINARY
        ARCHITECTURES
        DEPLOYMENT_DEPENDENCIES
        EXTRA_PLUGINS
        PACKAGE_SOURCE_DIR
        VERSION_CODE
        VERSION_NAME
        EXTRA_LIBS
    )

    unset(PARAMS)
    foreach (property ${PROPERTIES})
        get_target_property(value ${target} ANDROID_${property})

        if (value)
            list(APPEND PARAMS ${property} ${value})
            set(ANDROID_${property} ON)
        else()
            unset(ANDROID_${property})
        endif()
    endforeach()

    get_target_property(APP_BINARY ${target} OUTPUT_NAME)

    if (NOT APP_BINARY)
        set(APP_BINARY ${target})
    endif()

    get_target_property(QML_ROOT ${target} QML_ROOT_PATH)

    if (NOT QML_ROOT)
        set(QML_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    get_target_property(IMPORT_PATH ${target} QML_IMPORT_PATH)

    if (IMPORT_PATH)
        set(IMPORT_PATH QML_IMPORT_PATH ${IMPORT_PATH})
    else()
        unset(IMPORT_PATH)
    endif()

    commander_generate_android_deployment_settings_file(${file}
        APPLICATION_BINARY ${APP_BINARY}
        QML_ROOT_PATH ${QML_ROOT}
        ARCHITECTURES ${ARCHITECTURES}
        ${IMPORT_PATH}
        ${PARAMS}
    )
endfunction()

function(commander_generate_android_package target)
    get_target_property(INPUT ${target} ANDROID_DEPLOYMENT_SETTINGS_FILE)

    if (NOT INPUT)
        commander_generate_android_target_deployment_file(${target} ${target}_android/android_deployment_settings.json)
        set(INPUT ${target}_android/android_deployment_settings.json)
    endif()

    get_target_property(OUTPUT_NAME ${target} OUTPUT_NAME)

    if (NOT OUTPUT_NAME)
        set(OUTPUT_NAME ${target})
    endif()

    if (ANDROID_BUILD_AAB)
        set(AAB AAB)
    else()
        unset(AAB)
    endif()

    commander_add_android_apk_target(${target}-apk
        BASE_TARGET ${target}
        INPUT ${INPUT}
        OUTPUT ${target}_android/android-build
        APK ${OUTPUT_NAME}.apk
        ${AAB}
    )
endfunction()

macro(_commander_register_android_target name)
    _commander_register_target(${name} ${ARGN})
endmacro()

macro(_commander_register_android_executable name)
    _commander_register_android_target(${name} ${ARGN})

    set(COMMANDER_ANDROID_EXECUTABLES ${COMMANDER_ANDROID_EXECUTABLES} ${name} ${ARGN})
    cmake_language(DEFER CALL _commander_generate_android_packages)
endmacro()

macro(_commander_generate_android_packages)
    foreach (target ${COMMANDER_ANDROID_EXECUTABLES})
        commander_generate_android_package(${target})
    endforeach()

    unset(COMMANDER_ANDROID_EXECUTABLES)
endmacro()
