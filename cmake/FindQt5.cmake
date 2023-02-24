# Core
set(QT5_MODULES Core)

# Test
if (Commander_BUILD_TESTS)
    list(APPEND QT5_MODULES Test)
endif()

# Translations
if (Commander_BUILD_TRANSLATIONS)
    list(APPEND QT5_MODULES LinguistTools)
endif()

find_package(Qt5 REQUIRED COMPONENTS ${QT5_MODULES})

# Global variables
set(CMAKE_AUTOMOC ON)
#set(CMAKE_AUTORCC ON)
#set(CMAKE_AUTOUIC ON)
