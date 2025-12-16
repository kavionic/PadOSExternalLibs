cmake_minimum_required(VERSION 3.25)

project(PadOSExternalLibs VERSION 0.1)

include_directories(
	${CMAKE_SOURCE_DIR}/cmsis-core/Include
	${CMAKE_SOURCE_DIR}/cmsis-device-h7/Include
	${CMAKE_SOURCE_DIR}/pugixml/src
	${CMAKE_SOURCE_DIR}/json/include
	${CMAKE_SOURCE_DIR}/zlib
	${CMAKE_SOURCE_DIR}/libpng
	${CMAKE_SOURCE_DIR}/eigen
	${CMAKE_SOURCE_DIR}/googletest/googletest/include
	${CMAKE_SOURCE_DIR}/fmt/include
	${CMAKE_BINARY_DIR}/zlib
	${CMAKE_BINARY_DIR}/libpng
)

set(FMT_INSTALL ON)
set(EIGEN_BUILD_CMAKE_PACKAGE ON)
set(JSON_Install ON)
set(INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/include")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-conversion -Wno-implicit-function-declaration")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-psabi") # Supress STL warnings

set(ZLIB_BUILD_TESTING OFF)
set(ZLIB_BUILD_SHARED OFF)
set(ZLIB_INCLUDE_DIR  "${CMAKE_SOURCE_DIR}/zlib;${CMAKE_BINARY_DIR}/zlib" CACHE PATH "" FORCE)
set(ZLIB_LIBRARY      "${CMAKE_BINARY_DIR}/zlib/libz.a" CACHE FILEPATH "" FORCE)
set(ZLIB_LIBRARY_DEBUG   "${ZLIB_LIBRARY}" CACHE FILEPATH "" FORCE)
set(ZLIB_LIBRARY_RELEASE "${ZLIB_LIBRARY}" CACHE FILEPATH "" FORCE)

# libpng Build options
#set(PNG_SHARED OFF CACHE BOOL "" FORCE)
#set(PNG_STATIC ON  CACHE BOOL "" FORCE)
#set(PNG_TOOLS  OFF CACHE BOOL "" FORCE)
#set(PNG_TESTS  OFF CACHE BOOL "" FORCE)
set(PNG_BUILD_ZLIB OFF)
set(PNG_SHARED OFF)
set(PNG_STATIC ON)
set(PNG_TESTS  OFF)
set(PNG_TOOLS  OFF)

# We add an empty ZLIB::ZLIB interface library to stop find_package(ZLIB) from
# creating one. libpng will still add the target to its list of link libraries,
# but since it's an empty target, it will have no effect.
add_library(ZLIB::ZLIB INTERFACE IMPORTED)

# MuParser Build options
set(ENABLE_SAMPLES OFF)
set(ENABLE_OPENMP OFF)
set(ENABLE_WIDE_CHAR OFF)
set(BUILD_SHARED_LIBS OFF)
set(BUILD_TESTING OFF)

# fmt Build options
add_compile_definitions(FMT_OPTIMIZE_SIZE=2)

add_subdirectory(pugixml)
add_subdirectory(zlib)
add_subdirectory(libpng)
add_subdirectory(eigen)
add_subdirectory(fmt)
add_subdirectory(json)
add_subdirectory(googletest)
add_subdirectory(muparser)

add_dependencies(png_static zlibstatic)

install(TARGETS
	fmt
	pugixml
	png_static
	gtest
	zlibstatic
	muparser
    ARCHIVE DESTINATION lib
)

install(DIRECTORY cmsis-core/Include/ DESTINATION include/cmsis-core)
install(DIRECTORY cmsis-device-h7/Include/ DESTINATION include/cmsis-device-h7)
