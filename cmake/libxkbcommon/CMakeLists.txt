# This file is part of PadOS.
#
# Copyright (c) 2026 Kurt Skauen
#
# SPDX-License-Identifier: Apache-2.0
###############################################################################

include(ExternalProject)
include(CMakePackageConfigHelpers)

find_program(XKBCOMMON_MESON_EXECUTABLE NAMES meson REQUIRED)
find_program(XKBCOMMON_NINJA_EXECUTABLE NAMES ninja REQUIRED)
find_package(BISON 3.6 REQUIRED)

execute_process(
    COMMAND "${XKBCOMMON_MESON_EXECUTABLE}" --version
    OUTPUT_VARIABLE XKBCOMMON_MESON_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)
if(XKBCOMMON_MESON_VERSION VERSION_LESS 1.4)
    message(FATAL_ERROR "libxkbcommon requires Meson 1.4 or later.")
endif()

set(XKBCOMMON_SOURCE_DIR "${PROJECT_SOURCE_DIR}/libxkbcommon")
set(XKBCOMMON_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/build")
set(XKBCOMMON_STAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/stage")
set(XKBCOMMON_CROSS_FILE "${CMAKE_CURRENT_BINARY_DIR}/pados-cross.ini")
set(XKBCOMMON_VERSION 1.13.2)

if(NOT EXISTS "${XKBCOMMON_SOURCE_DIR}/meson.build")
    message(FATAL_ERROR "Initialize the libxkbcommon submodule with: git submodule update --init libxkbcommon")
endif()

# Runtime paths refer to the target filesystem, independently of the host install directory.
set(XKBCOMMON_CONFIG_ROOT "/usr/share/X11/xkb" CACHE STRING "Target XKB layout directory")
set(XKBCOMMON_CONFIG_EXTRA_PATH "/etc/xkb" CACHE STRING "Target XKB override directory")
set(XKBCOMMON_LOCALE_ROOT "/usr/share/X11/locale" CACHE STRING "Target X11 Compose data directory")

function(xkbcommon_meson_array output)
    set(values "")
    foreach(value IN LISTS ARGN)
        string(REPLACE "\\" "\\\\" value "${value}")
        string(REPLACE "'" "\\'" value "${value}")
        list(APPEND values "'${value}'")
    endforeach()
    list(JOIN values ", " values)
    set(${output} "[${values}]" PARENT_SCOPE)
endfunction()

# Use the same compiler, architecture, optimization and debug flags as the CMake build.
string(TOUPPER "${CMAKE_BUILD_TYPE}" XKBCOMMON_BUILD_TYPE)
separate_arguments(XKBCOMMON_C_FLAGS NATIVE_COMMAND "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${XKBCOMMON_BUILD_TYPE}}")
separate_arguments(XKBCOMMON_LINK_FLAGS NATIVE_COMMAND
    "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_EXE_LINKER_FLAGS_${XKBCOMMON_BUILD_TYPE}}"
)
separate_arguments(XKBCOMMON_COMPILER_ARGS NATIVE_COMMAND "${CMAKE_C_COMPILER_ARG1}")
xkbcommon_meson_array(XKBCOMMON_MESON_CC "${CMAKE_C_COMPILER}" ${XKBCOMMON_COMPILER_ARGS})
xkbcommon_meson_array(XKBCOMMON_MESON_AR "${CMAKE_AR}")
xkbcommon_meson_array(XKBCOMMON_MESON_STRIP "${CMAKE_STRIP}")
xkbcommon_meson_array(XKBCOMMON_MESON_BISON "${BISON_EXECUTABLE}")
xkbcommon_meson_array(XKBCOMMON_MESON_C_ARGS ${XKBCOMMON_C_FLAGS})
xkbcommon_meson_array(XKBCOMMON_MESON_LINK_ARGS ${XKBCOMMON_LINK_FLAGS})
configure_file(pados-cross.ini.in "${XKBCOMMON_CROSS_FILE}" @ONLY)

set(XKBCOMMON_MESON_COMMAND
    "${CMAKE_COMMAND}" -E env "NINJA=${XKBCOMMON_NINJA_EXECUTABLE}" "${XKBCOMMON_MESON_EXECUTABLE}"
)

# Keep the upstream Meson sources unmodified. Only build the public static library;
# upstream's default build also includes test executables that need a complete OS image.
ExternalProject_Add(libxkbcommon
    SOURCE_DIR "${XKBCOMMON_SOURCE_DIR}"
    BINARY_DIR "${XKBCOMMON_BINARY_DIR}"
    INSTALL_DIR "${XKBCOMMON_STAGE_DIR}"
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${XKBCOMMON_MESON_COMMAND} setup --reconfigure <BINARY_DIR> <SOURCE_DIR>
        --cross-file "${XKBCOMMON_CROSS_FILE}"
        "-Dc_args=${XKBCOMMON_MESON_C_ARGS}"
        "-Dc_link_args=${XKBCOMMON_MESON_LINK_ARGS}"
        --backend ninja
        --prefix /usr
        --libdir lib
        --sysconfdir /etc
        --buildtype plain
        --default-library static
        --wrap-mode nofallback
        -Db_staticpic=false
        -Denable-tools=false
        -Denable-x11=false
        -Denable-wayland=false
        -Denable-xkbregistry=false
        -Denable-docs=false
        -Denable-bash-completion=false
        "-Dxkb-config-root=${XKBCOMMON_CONFIG_ROOT}"
        "-Dxkb-config-extra-path=${XKBCOMMON_CONFIG_EXTRA_PATH}"
        "-Dx-locale-root=${XKBCOMMON_LOCALE_ROOT}"
    BUILD_COMMAND "${XKBCOMMON_NINJA_EXECUTABLE}" -C <BINARY_DIR> libxkbcommon.a
    BUILD_ALWAYS TRUE
    BUILD_BYPRODUCTS "${XKBCOMMON_BINARY_DIR}/libxkbcommon.a"
    INSTALL_COMMAND ${XKBCOMMON_MESON_COMMAND} install -C <BINARY_DIR> --no-rebuild --destdir <INSTALL_DIR>
)
ExternalProject_Add_StepDependencies(libxkbcommon configure "${XKBCOMMON_CROSS_FILE}")

# Stage with the target /usr prefix, then install alongside the other external libraries.
install(DIRECTORY "${XKBCOMMON_STAGE_DIR}/usr/include/" DESTINATION include)
install(DIRECTORY "${XKBCOMMON_STAGE_DIR}/usr/lib/" DESTINATION lib)
install(FILES "${XKBCOMMON_SOURCE_DIR}/LICENSE" DESTINATION share/licenses/libxkbcommon)

configure_package_config_file(
    xkbcommonConfig.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/xkbcommonConfig.cmake"
    INSTALL_DESTINATION lib/cmake/xkbcommon
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/xkbcommonConfigVersion.cmake"
    VERSION "${XKBCOMMON_VERSION}"
    COMPATIBILITY SameMajorVersion
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/xkbcommonConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/xkbcommonConfigVersion.cmake"
    DESTINATION lib/cmake/xkbcommon
)
