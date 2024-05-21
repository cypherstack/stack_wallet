#!/bin/bash

# Function to display usage.
usage() {
    echo "Usage: $0 [-v <version>] [-b <build_number>]"
    exit 1
}

# Parse command-line arguments.
while getopts "v:b:" opt; do
    case "$opt" in
        v) VERSION="$OPTARG" ;;
        b) BUILD_NUMBER="$OPTARG" ;;
        *) usage ;;
    esac
done

# Define the pubspec.yaml file path.
PUBSPEC_FILE="../../pubspec.yaml"

# Ensure the pubspec.yaml file exists.
if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "Error: $PUBSPEC_FILE not found!"
    exit 1
fi

# Extract the current version and build number from pubspec.yaml.
CURRENT_VERSION_LINE=$(grep "^version:" "$PUBSPEC_FILE")
CURRENT_VERSION=$(echo "$CURRENT_VERSION_LINE" | cut -d ' ' -f 2)
CURRENT_VERSION_NUMBER=$(echo "$CURRENT_VERSION" | cut -d '+' -f 1)
CURRENT_BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d '+' -f 2)

# If version is not provided, use the current version number.
if [ -z "$VERSION" ]; then
    VERSION="$CURRENT_VERSION_NUMBER"
fi

# If build number is not provided, increment the current build number by one.
if [ -z "$BUILD_NUMBER" ]; then
    BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
fi

# Update the version and build number in pubspec.yaml.
TMP_FILE=$(mktemp)
sed "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" "$PUBSPEC_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$PUBSPEC_FILE"

echo "Updated $PUBSPEC_FILE with version: $VERSION and build number: $BUILD_NUMBER"
