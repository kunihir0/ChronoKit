#!/usr/bin/env bash
set -e

SCHEME="${1:-rootless}"
if [[ "$SCHEME" != "rootless" && "$SCHEME" != "roothide" ]]; then
    echo "Usage: $0 [rootless|roothide]"
    exit 1
fi

echo "Building ChronoKit for scheme: $SCHEME"

if [[ "$SCHEME" == "roothide" ]]; then
    export THEOS_PACKAGE_SCHEME=roothide
    export ARCHS=arm64e
else
    export THEOS_PACKAGE_SCHEME=rootless
    export ARCHS=arm64
fi

make clean
make package FINALPACKAGE=1 DEBUG=0

echo "Build complete. Packages are in ./packages/"
