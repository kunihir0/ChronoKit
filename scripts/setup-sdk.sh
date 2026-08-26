#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <theos-directory>"
    exit 1
fi

THEOS_DIR="$1"
SDK_RELEASE="master-146e41f"
SDK_ARCHIVE="iPhoneOS16.5.sdk.tar.xz"
SDK_SHA256="5e0fd3f01266cce4ce012d4a99b38eb56578fca40d09edc81cd83dee958202fb"
SDK_URL="https://github.com/theos/sdks/releases/download/${SDK_RELEASE}/${SDK_ARCHIVE}"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

curl --fail --location --silent --show-error \
    --output "$TMP_DIR/$SDK_ARCHIVE" \
    "$SDK_URL"

ACTUAL_SHA256=$(shasum -a 256 "$TMP_DIR/$SDK_ARCHIVE" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$SDK_SHA256" ]]; then
    echo "Error: iOS SDK SHA256 verification failed."
    exit 1
fi

mkdir -p "$THEOS_DIR/sdks"
tar -xf "$TMP_DIR/$SDK_ARCHIVE" -C "$THEOS_DIR/sdks"
