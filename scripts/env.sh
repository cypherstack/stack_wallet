#!/usr/bin/env bash

set -x -e

# set project root
THIS_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "${THIS_SCRIPT_DIR}/../"
export APP_PROJECT_ROOT_DIR="$(pwd)"
popd