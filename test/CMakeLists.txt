enable_testing()

find_package(GTest REQUIRED)

add_executable(commander_test main.cpp)

target_link_libraries(commander_test GTest::gtest commander)

add_test(commander_test COMMAND commander_test)
