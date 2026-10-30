#!/usr/bin/env bash
#
# Build a minimal static OpenCV for the camera_linux QR scanner plugin.
#
# camera_linux (src/opencv_wrapper.cpp) only uses VideoCapture, Mat and imencode,
# so core, imgproc, imgcodecs and videoio are enough. Building them as static
# archives with their own jpeg/png/zlib lets libopencv_wrapper.so carry OpenCV
# inside itself, instead of depending on ~50 libopencv_*.so that user machines do
# not have. Same module list and V4L-only videoio as the Flatpak OpenCV module.
#
# Usage: build_opencv_static.sh [PREFIX]    (default /opt/opencv-static)
#
# The result is OpenCVConfig.cmake in PREFIX/lib/cmake/opencv4; the Linux CMake
# picks it up through STACKWALLET_OPENCV_DIR (see linux/CMakeLists.txt template).

set -euo pipefail

OPENCV_VERSION="4.10.0"
OPENCV_COMMIT="71d3237a093b60a27601c20e9ee6c3e52154e8b1"

PREFIX="${1:-/opt/opencv-static}"
STAMP="${PREFIX}/.stackwallet-opencv-${OPENCV_VERSION}-${OPENCV_COMMIT}"
JOBS="${OPENCV_BUILD_JOBS:-$(nproc)}"

if [ -f "${STAMP}" ] && [ -f "${PREFIX}/lib/cmake/opencv4/OpenCVConfig.cmake" ]; then
  echo "OpenCV ${OPENCV_VERSION} already built in ${PREFIX}"
  exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

git init -q "${WORK}/src"
git -C "${WORK}/src" fetch -q --depth 1 https://github.com/opencv/opencv.git "${OPENCV_COMMIT}"
git -C "${WORK}/src" checkout -q FETCH_HEAD
if [ "$(git -C "${WORK}/src" rev-parse HEAD)" != "${OPENCV_COMMIT}" ]; then
  echo "OpenCV checkout does not match ${OPENCV_COMMIT}" >&2
  exit 1
fi

# Every flag that is OFF is something that would otherwise add a runtime
# dependency on the user's machine (GTK, Qt, FFmpeg, GStreamer, OpenCL, TIFF,
# WebP, ...) or a network download (IPP, ITT).
cmake -S "${WORK}/src" -B "${WORK}/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DENABLE_PIC=ON \
  -DENABLE_PRECOMPILED_HEADERS=OFF \
  -DBUILD_LIST=core,imgcodecs,imgproc,videoio \
  -DBUILD_ZLIB=ON -DBUILD_PNG=ON -DBUILD_JPEG=ON \
  -DWITH_JPEG=ON -DWITH_PNG=ON \
  -DWITH_TIFF=OFF -DWITH_WEBP=OFF -DWITH_OPENJPEG=OFF -DWITH_JASPER=OFF \
  -DWITH_OPENEXR=OFF -DWITH_JPEGXL=OFF -DWITH_AVIF=OFF -DWITH_GDAL=OFF -DWITH_GDCM=OFF \
  -DWITH_V4L=ON \
  -DWITH_FFMPEG=OFF -DWITH_GSTREAMER=OFF -DWITH_1394=OFF -DWITH_LIBREALSENSE=OFF \
  -DWITH_OBSENSOR=OFF \
  -DWITH_GTK=OFF -DWITH_QT=OFF -DWITH_OPENGL=OFF -DWITH_VTK=OFF \
  -DWITH_OPENCL=OFF -DWITH_CUDA=OFF \
  -DWITH_IPP=OFF -DWITH_ITT=OFF -DWITH_EIGEN=OFF -DWITH_LAPACK=OFF \
  -DWITH_PROTOBUF=OFF -DWITH_ADE=OFF -DWITH_TBB=OFF -DWITH_OPENMP=OFF \
  -DBUILD_opencv_apps=OFF -DBUILD_opencv_python3=OFF \
  -DBUILD_opencv_python_bindings_generator=OFF -DBUILD_JAVA=OFF \
  -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_DOCS=OFF \
  -DOPENCV_GENERATE_PKGCONFIG=OFF

cmake --build "${WORK}/build" --parallel "${JOBS}"
cmake --install "${WORK}/build"

touch "${STAMP}"
echo "OpenCV ${OPENCV_VERSION} (static, minimal) installed in ${PREFIX}"
