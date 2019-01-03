#!/bin/bash -e
TMP_DIR=/tmp/protobuf_$$

BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TARGET_ARCHS=("x86_64" "arm64")

if [[ -d $BASE_DIR/ios ]];then
    rm -r $BASE_DIR/ios
fi

for target_arch in ${TARGET_ARCHS[@]};do
    mkdir -p $BASE_DIR/ios/$target_arch
    cd $BASE_DIR/ios/$target_arch
    CFLAGS="-DNDEBUG -DGOOGLE_PROTOBUF_NO_RTTI -g -Os -pipe -fPIC -arch $target_arch -fvisibility=hidden -fvisibility-inlines-hidden -Wall -Wextra -Wno-unused-function"
    CXXFLAGS="$CFLAGS -std=c++11 -stdlib=libc++"
    cmake \
        -Dprotobuf_BUILD_SHARED_LIBS=OFF \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_EXAMPLES=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=$BASE_DIR/ios.toolchain.cmake \
        -DCMAKE_C_FLAGS="$CFLAGS" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
        -DCMAKE_INSTALL_PREFIX=$BASE_DIR/ios/$target_arch \
        -DCMAKE_TARGET_ARCHITECTURE=$target_arch \
        $BASE_DIR/../cmake

    make -j4
    make install
done