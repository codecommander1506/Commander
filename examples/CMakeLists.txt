unset(Commander_DIR CACHE)
set(CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})

find_package(Commander REQUIRED COMPONENTS Android Wasm)

commander_add_executable(test)
