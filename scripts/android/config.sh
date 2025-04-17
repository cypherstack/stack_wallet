#!/bin/sh

export WORKDIR="$(pwd)/"build
# Change this Value to a lower number if you run out of memory while compiling
export OVERRIDE_THREADS="$(nproc)"