#!/bin/bash -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f $BASE_DIR/../src/protoc ]];then
    pushd $BASE_DIR/..
    ./autogen.sh
    ./configure
    make -j4
    popd
fi

if [[ -z $ANDROID_HOME ]];then
    (>&2  echo "ANDROID_HOME is not set")
    exit 1
fi
export ANDROID_NDK=${ANDROID_NDK:-$ANDROID_HOME/ndk-bundle}
if [[ ! -d $ANDROID_NDK ]];then
    (>&2 echo "You should download ndk first!")
    exit 1
fi
if [[ ! -d $ANDROID_HOME/cmake ]];then
    (>&2 echo "You should download android cmake first!")
    exit 1
fi

ARCHS=("x86" "x86_64" "armeabi-v7a" "arm64-v8a")
CFLAGS="-DNDEBUG -DGOOGLE_PROTOBUF_NO_RTTI -pipe -fvisibility=hidden -fvisibility-inlines-hidden -fPIC -Wall -Wextra -Wno-unused-function"
CXX_FLAGS="$CFLAGS -fno-rtti -fno-exceptions"
ANDROID_CMAKE=$(find $ANDROID_HOME/cmake -name cmake | grep "bin/cmake")

for arch in ${ARCHS[@]};do
    if [[ -f $BASE_DIR/android/$arch/lib/libprotobuf.a ]];then
        continue
    fi
    if [[ -d $BASE_DIR/android/build ]]; then
        rm -r $BASE_DIR/android/build
    fi
    mkdir -p $BASE_DIR/android/build
    pushd $BASE_DIR/android/build
    $ANDROID_CMAKE \
        -Dprotobuf_BUILD_SHARED_LIBS=OFF \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_EXAMPLES=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
        -DCMAKE_C_FLAGS="$CFLAGS" \
        -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
        -DANDROID_NDK=$ANDROID_NDK \
        -DCMAKE_INSTALL_PREFIX=$BASE_DIR/android/$arch \
        -DANDROID_TOOLCHAIN=clang \
        -DANDROID_ABI=$arch \
        -DANDROID_NATIVE_API_LEVEL=19 \
        -DANDROID_STL=c++_static \
        -DANDROID_LINKER_FLAGS="-landroid -llog" \
        $BASE_DIR/../cmake
   make -j4
   make install
   popd
done
