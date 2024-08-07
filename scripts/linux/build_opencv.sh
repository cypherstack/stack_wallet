#!/bin/sh

# Set up variables.
OPENCV_VERSION=4.5.5
OPENCV_SRC_DIR=opencv
BUILD_DIR=build

# Create build directory.
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Clone OpenCV repository.
git clone https://github.com/opencv/opencv.git -b $OPENCV_VERSION $OPENCV_SRC_DIR
cd $OPENCV_SRC_DIR

# Create build subdirectory.
mkdir -p build && cd build

# Configure OpenCV build.
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_opencv_python2=OFF \
    -DBUILD_opencv_python3=OFF \
    -DWITH_FFMPEG=OFF \
    -DWITH_GSTREAMER=OFF \
    -DWITH_GTK=OFF \
    -DWITH_QT=OFF \
    -DWITH_CUDA=OFF

# Build OpenCV.
cmake --build . -- -j$(nproc)

# Create libopencv_wrapper.so.
g++ -shared -o libopencv_wrapper.so -Wl,--whole-archive lib/libopencv_*.a -Wl,--no-whole-archive

# Copy libopencv_wrapper.so to the main build directory.
mkdir -p ../../../../build
cp libopencv_wrapper.so "../../../../build/libopencv_wrapper.so"

# Return to the original directory.
cd ../../../
