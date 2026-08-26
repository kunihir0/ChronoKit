#!/usr/bin/env bash
set -euo pipefail

SCHEME="${1:-rootless}"
if [[ "$SCHEME" != "rootless" && "$SCHEME" != "roothide" ]]; then
    echo "Usage: $0 [rootless|roothide]"
    exit 1
fi

echo "Building ChronoKit for scheme: $SCHEME"

# Cleanup trap to restore original control file
trap 'mv control.bak control 2>/dev/null || true' EXIT

if [[ "$SCHEME" == "roothide" ]]; then
    export THEOS_PACKAGE_SCHEME=roothide
    export ARCHS=arm64e
    # Update Architecture in control file for roothide
    sed -i.bak 's/^[ \t]*Architecture:.*/Architecture: iphoneos-arm64e/' control
else
    export THEOS_PACKAGE_SCHEME=rootless
    export ARCHS=arm64
    # Ensure Architecture is arm64 for rootless
    sed -i.bak 's/^[ \t]*Architecture:.*/Architecture: iphoneos-arm64/' control
fi

make clean THEOS_PACKAGE_SCHEME="$THEOS_PACKAGE_SCHEME" ARCHS="$ARCHS"
make package FINALPACKAGE=1 DEBUG=0 THEOS_PACKAGE_SCHEME="$THEOS_PACKAGE_SCHEME" ARCHS="$ARCHS"

echo "Build complete. Packages are in ./packages/"