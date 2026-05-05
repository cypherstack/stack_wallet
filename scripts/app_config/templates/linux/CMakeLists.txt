# Project-level configuration.
cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "place_holder")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.place.holder")

set(INCLUDE_EPIC_SO INCLUDE_EPIC_SO_FLAG)
set(INCLUDE_MWC_SO INCLUDE_MWC_SO_FLAG)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# jsoncpp and libsecret for flutter_secure_storage. When
# USE_SYSTEM_SECURE_STORAGE_DEPS is set, link and bundle the system-installed
# copies; otherwise use the artifacts built by scripts/linux/build_secure_storage_deps.sh.
option(USE_SYSTEM_SECURE_STORAGE_DEPS "Link against system-installed jsoncpp and libsecret" OFF)
if(DEFINED ENV{USE_SYSTEM_SECURE_STORAGE_DEPS} AND "$ENV{USE_SYSTEM_SECURE_STORAGE_DEPS}" STREQUAL "1")
  set(USE_SYSTEM_SECURE_STORAGE_DEPS ON)
endif()

if(USE_SYSTEM_SECURE_STORAGE_DEPS)
  pkg_check_modules(JSONCPP REQUIRED IMPORTED_TARGET jsoncpp)
  pkg_check_modules(LIBSECRET REQUIRED IMPORTED_TARGET libsecret-1)
  pkg_get_variable(JSONCPP_LIBDIR jsoncpp libdir)
  pkg_get_variable(LIBSECRET_LIBDIR libsecret-1 libdir)
else()
  set(ENV{PKG_CONFIG_PATH} "$ENV{PKG_CONFIG_PATH}:${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/jsoncpp/build/pkg-config")
  set(ENV{PKG_CONFIG_PATH} "$ENV{PKG_CONFIG_PATH}:${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/pc")

  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/jsoncpp/include)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/libsecret)
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/libsecret/_build)

  add_library(jsoncpp SHARED IMPORTED)
  set_target_properties(jsoncpp PROPERTIES IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/jsoncpp/build/src/lib_json/libjsoncpp.so")
  add_library(secret-1 SHARED IMPORTED)
  set_target_properties(secret-1 PROPERTIES IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/libsecret/_build/libsecret/libsecret-1.so")
endif()

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Define the application target. To change its name, change BINARY_NAME above,
# not the value here, or `flutter run` will no longer work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE -static-libgcc -static-libstdc++)
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
if(USE_SYSTEM_SECURE_STORAGE_DEPS)
  target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::JSONCPP PkgConfig::LIBSECRET)
else()
  target_link_libraries(${BINARY_NAME} PRIVATE jsoncpp)
  target_link_libraries(${BINARY_NAME} PRIVATE secret-1)
endif()


# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)

# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(INCLUDE_EPIC_SO)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../crypto_plugins/flutter_libepiccash/scripts/linux/build/rust/target/x86_64-unknown-linux-gnu/release/libepic_cash_wallet.so" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

if(INCLUDE_MWC_SO)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../crypto_plugins/flutter_libmwc/scripts/linux/build/rust/target/x86_64-unknown-linux-gnu/release/libmwc_wallet.so" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

if(USE_SYSTEM_SECURE_STORAGE_DEPS)
  file(GLOB JSONCPP_SO_FILES "${JSONCPP_LIBDIR}/libjsoncpp.so*")
  install(FILES ${JSONCPP_SO_FILES} DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  file(GLOB LIBSECRET_SO_FILES "${LIBSECRET_LIBDIR}/libsecret-1.so*")
  install(FILES ${LIBSECRET_SO_FILES} DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
else()
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/jsoncpp/build/src/lib_json/libjsoncpp.so.1.7.4" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/jsoncpp/build/src/lib_json/libjsoncpp.so.1" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/jsoncpp/build/src/lib_json/libjsoncpp.so" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)

  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/libsecret/_build/libsecret/libsecret-1.so.0.0.0" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/libsecret/_build/libsecret/libsecret-1.so.0" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/linux/build/libsecret/_build/libsecret/libsecret-1.so" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
