# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.10.2)

# Declares and names the project.

project("example")

# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

add_library(native-lib SHARED native-lib.cpp)
if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    add_library(erlang STATIC IMPORTED)
    set_target_properties(erlang PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../libs/armeabi-v7a/liberlang.a)
elseif(${ANDROID_ABI} STREQUAL "arm64-v8a") 
    add_library(erlang STATIC IMPORTED)
    set_target_properties(erlang PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../libs/arm64-v8a/liberlang.a)
elseif(${ANDROID_ABI} STREQUAL "x86_64")
    add_library(erlang STATIC IMPORTED)
    set_target_properties(erlang PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/../libs/x86_64/liberlang.a)
endif()

target_link_libraries(native-lib erlang)

# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library(log-lib log)

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries(native-lib ${log-lib})
