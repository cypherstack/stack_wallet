#!/bin/bash

set -x -e

# Function to display usage.
usage() {
    echo "Usage: $0 [-v <version>] [-b <build_number>]"
    exit 1
}

unset -v VERSION
unset -v BUILD_NUMBER

# Check if no arguments are provided.
if [ $# -ne 4 ]; then # if [ -z "$VERSION" ] || [ -z "$BUILD_NUMBER" ]; then
    usage
fi

# Parse command-line arguments.
while getopts "v:b:" opt; do
    case "$opt" in
        v) VERSION="$OPTARG" ;;
        b) BUILD_NUMBER="$OPTARG" ;;
        *) usage ;;
    esac
done

# Define the pubspec.yaml file path.
PUBSPEC_FILE="${APP_PROJECT_ROOT_DIR}/pubspec.yaml"

# Ensure the pubspec.yaml file exists.
if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "Error: $PUBSPEC_FILE not found!"
    exit 1
fi

if [[ "$(uname)" == 'Darwin' ]]; then
  # macos specific sed
  sed -i '' "s/PLACEHOLDER_V/$VERSION/g" "${PUBSPEC_FILE}"
  sed -i '' "s/PLACEHOLDER_B/$BUILD_NUMBER/g" "${PUBSPEC_FILE}"
else
  sed -i '' "s/PLACEHOLDER_V/$VERSION/g" "${PUBSPEC_FILE}"
  sed -i '' "s/PLACEHOLDER_B/$BUILD_NUMBER/g" "${PUBSPEC_FILE}"
fi

echo "Updated $PUBSPEC_FILE with version: $VERSION and build number: $BUILD_NUMBER"
