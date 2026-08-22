#!/usr/bin/env bash

set -euo pipefail

if [ "${USE_SYSTEM_SECURE_STORAGE_DEPS:-0}" = "1" ]; then
    echo "USE_SYSTEM_SECURE_STORAGE_DEPS is set; skipping build of jsoncpp and libsecret (using system packages)"
    exit 0
fi

LINUX_DIRECTORY="$(pwd)"
JSONCPP_COMMIT="48d2a69d47bbf92337a09fc1672e1bad39fdde86"
LIBSECRET_COMMIT="6b5a6c28afc6dd93c232a4907a87c881079ff91b"
mkdir -p build

checkout_commit() {
  local url="$1"
  local directory="$2"
  local commit="$3"

  [ ! -L "$directory" ] || {
    echo "Refusing dependency checkout through symlink: $directory" >&2
    exit 1
  }
  if [ ! -d "$directory/.git" ]; then
    git clone --filter=blob:none --no-checkout "$url" "$directory"
  fi
  [ "$(git -C "$directory" remote get-url origin)" = "$url" ] || {
    echo "Unexpected origin for $directory." >&2
    exit 1
  }
  git -C "$directory" fetch --depth 1 origin "$commit"
  [ "$(git -C "$directory" rev-parse FETCH_HEAD)" = "$commit" ] || {
    echo "Unexpected commit fetched for $directory." >&2
    exit 1
  }
  git -C "$directory" checkout --detach --force "$commit"
  git -C "$directory" clean -dffx
  git -C "$directory" diff --quiet
  git -C "$directory" diff --cached --quiet
}

# Build JsonCPP
cd build || exit 1
if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 1
fi
checkout_commit \
  https://github.com/open-source-parsers/jsoncpp.git \
  jsoncpp \
  "$JSONCPP_COMMIT"
cd jsoncpp || exit 1
mkdir -p build
cd build || exit 1
cmake \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -Wno-error=implicit-int-float-conversion" \
  -DJSONCPP_WITH_TESTS=OFF \
  -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF \
  -DBUILD_STATIC_LIBS=ON \
  -DBUILD_SHARED_LIBS=ON \
  -DARCHIVE_INSTALL_DIR=. \
  -G Ninja \
  ..
cmake --build . --parallel "$(nproc)"

cd "$LINUX_DIRECTORY" || exit 1
# Build libSecret
# sudo apt install meson libgirepository1.0-dev valac xsltproc gi-docgen docbook-xsl
# sudo apt install python3-pip
#pip3 install --user meson markdown tomli --upgrade
# pip3 install --user gi-docgen
cd build || exit 1
checkout_commit \
  https://git.cypherstack.com/Cypher_Stack/libsecret.git \
  libsecret \
  "$LIBSECRET_COMMIT"
cd libsecret || exit 1
if ! [ -x "$(command -v meson)" ]; then
  echo 'Error: meson is not installed.' >&2
  exit 1
fi
if [ -d _build ]; then
  meson setup --wipe _build \
    -Dmanpage=false \
    -Dgtk_doc=false \
    -Dintrospection=false \
    -Dvapi=false \
    -Dbash_completion=disabled
else
  meson setup _build \
    -Dmanpage=false \
    -Dgtk_doc=false \
    -Dintrospection=false \
    -Dvapi=false \
    -Dbash_completion=disabled
fi
if ! [ -x "$(command -v ninja)" ]; then
  echo 'Error: ninja is not installed.' >&2
  exit 1
fi
ninja -C _build
