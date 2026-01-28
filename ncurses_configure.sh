#!/bin/bash

SCRIPT_PATH="$(command -v -- "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname -- "$SCRIPT_PATH")"

SOURCE_DIR="$(cd -- "${SCRIPT_DIR}/ncurses" &> /dev/null && pwd)"
BINARY_DIR="$(cd -- "${SCRIPT_DIR}" &> /dev/null && pwd)/Build"


#SYSROOT=`cygpath -au $PADOS_TOOLCHAIN_PATH`
SYSROOT=`cygpath -au ../../../Install`

echo "Script is stored in: $SCRIPT_DIR"
echo "Source dir: $SOURCE_DIR"
echo "Binary dir: $BINARY_DIR"
echo "SysRoot:    $SYSROOT"

mkdir -p ${BINARY_DIR}/ncurses && \
cd ${BINARY_DIR}/ncurses && ${SOURCE_DIR}/configure \
--prefix=${SYSROOT} \
--build=x86_64-w64-mingw32 \
--host=arm-unknown-pados-eabi \
--target=arm-unknown-pados-eabi \
--without-shared \
--without-cxx-shared \
--with-build-cflags=-D__POSIX_VISIBLE=200809 \
--disable-werror


#--without-libtool-opts \
