#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

PROJECT_ROOT_DIR="$SCRIPT_DIR/../.."

cd "$PROJECT_ROOT_DIR" || exit
dart run build_runner build --delete-conflicting-outputs
