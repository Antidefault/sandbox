#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
cd "$SCRIPT_DIR/images"

echo "Running build scripts from: $(pwd)"
for dir in */; do
    if [ -d "$dir" ]; then
        echo "Building ${dir%/}"
        (cd "$dir" && if [ -f "build.sh" ]; then ./build.sh; else echo "no build.sh found, skipping."; fi)
    fi
done