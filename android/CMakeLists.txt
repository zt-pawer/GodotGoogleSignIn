cmake_minimum_required(VERSION 3.22.1)

if (NOT ANDROID_ABI)
    set(ANDROID_ABI "arm64-v8a")
endif ()

if (ANDROID_ABI STREQUAL "arm64-v8a")
    set(GODOT_CPP_LIB_ABI "arm64")
else ()
    message(FATAL_ERROR "Only arm64-v8a is supported. Got: ${ANDROID_ABI}")
endif ()

if (NOT ANDROID_PLATFORM)
    set(ANDROID_PLATFORM "android-24")
endif ()

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif ()

if (CMAKE_BUILD_TYPE MATCHES Debug)
    set(GODOT_CPP_LIB_BUILD_TYPE debug)
else ()
    set(GODOT_CPP_LIB_BUILD_TYPE release)
endif ()

if (NOT (ANDROID_STL STREQUAL "c++_shared"))
    set(ANDROID_STL "c++_shared")
endif ()

if (NOT ANDROID_NDK)
    if (DEFINED ENV{ANDROID_NDK_HOME})
        set(ANDROID_NDK $ENV{ANDROID_NDK_HOME})
    endif ()
endif ()

if (NOT CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "${ANDROID_NDK}/build/cmake/android.toolchain.cmake")
endif ()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

project(GodotGoogleSignIn LANGUAGES CXX)

## godot-cpp static library (prebuilt via scons, vendored as a git submodule)
set(GODOT_CPP_DIR "${CMAKE_SOURCE_DIR}/../godot-cpp")
set(GODOT-CPP "godot-cpp")
set(GODOT_CPP_STATIC_LIB "${GODOT_CPP_DIR}/bin/libgodot-cpp.android.template_${GODOT_CPP_LIB_BUILD_TYPE}.${GODOT_CPP_LIB_ABI}.a")

list(APPEND GODOT_CPP_INCLUDE_DIRECTORIES "${GODOT_CPP_DIR}/include")
list(APPEND GODOT_CPP_INCLUDE_DIRECTORIES "${GODOT_CPP_DIR}/gen/include")
list(APPEND GODOT_CPP_INCLUDE_DIRECTORIES "${GODOT_CPP_DIR}/gdextension")

add_library(${GODOT-CPP}
        STATIC
        IMPORTED GLOBAL
        INTERFACE_INCLUDE_DIRECTORIES "${GODOT_CPP_INCLUDE_DIRECTORIES}"
        )
set_target_properties(${GODOT-CPP} PROPERTIES IMPORTED_LOCATION ${GODOT_CPP_STATIC_LIB})

## Native shim
file(GLOB_RECURSE GODOT_GOOGLE_SIGN_IN_SOURCES ${CMAKE_SOURCE_DIR}/src/main/cpp/*.cpp)
file(GLOB_RECURSE GODOT_GOOGLE_SIGN_IN_HEADERS ${CMAKE_SOURCE_DIR}/src/main/cpp/*.h)

add_library(${CMAKE_PROJECT_NAME} SHARED
        ${GODOT_GOOGLE_SIGN_IN_SOURCES} ${GODOT_GOOGLE_SIGN_IN_HEADERS}
        )

target_include_directories(${CMAKE_PROJECT_NAME}
        SYSTEM PUBLIC
        ${GODOT_CPP_INCLUDE_DIRECTORIES}
        )

target_link_libraries(${CMAKE_PROJECT_NAME}
        android
        log
        ${GODOT-CPP}
        )
