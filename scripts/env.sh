#!/usr/bin/env bash

set -e

# set project root
THIS_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "${THIS_SCRIPT_DIR}/../"
export APP_PROJECT_ROOT_DIR="$(pwd)"
popd

export APP_NAME_PLACEHOLDER="PlaceHolderName"
export APP_ID_PLACEHOLDER="com.place.holder"
export APP_ID_PLACEHOLDER_CAMEL="com.place.holderCamel"
export APP_ID_PLACEHOLDER_SNAKE="com.place.holder_snake"
export APP_BASIC_NAME_PLACEHOLDER="place_holder"
