#!/usr/bin/env bash
set -e

# Usage: ./scripts/build-ipa.sh <path_to_deb>

if [[ -z "$1" ]]; then
    echo "Usage: $0 <path_to_deb>"
    exit 1
fi

TWEAK_DEB="$1"

if [[ ! -f "$TWEAK_DEB" ]]; then
    echo "Error: Deb file $TWEAK_DEB not found."
    exit 1
fi

echo "--- IPA Injection Process ---"
echo "Tweak: $TWEAK_DEB"

# Validate secrets
if [[ -z "$TIKTOK_IPA_URL" || -z "$TIKTOK_IPA_SHA256" ]]; then
    echo "Error: Missing required environment variables."
    echo "Please configure the following GitHub secrets:"
    echo "  - TIKTOK_IPA_URL"
    echo "  - TIKTOK_IPA_SHA256"
    echo "You can set them using:"
    echo "  gh secret set TIKTOK_IPA_URL"
    echo "  gh secret set TIKTOK_IPA_SHA256"
    exit 1
fi

EXPECTED_VERSION="46.6.0"

TMP_DIR=$(mktemp -d)
BASE_IPA="$TMP_DIR/base.ipa"
OUT_IPA="TikTok_${EXPECTED_VERSION}_ChronoKit.ipa"

echo "Downloading decrypted TikTok IPA..."
curl -sL "$TIKTOK_IPA_URL" -o "$BASE_IPA"

echo "Verifying SHA256..."
ACTUAL_SHA256=$(sha256sum "$BASE_IPA" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$TIKTOK_IPA_SHA256" ]]; then
    echo "Error: SHA256 mismatch!"
    echo "Expected: $TIKTOK_IPA_SHA256"
    echo "Actual:   $ACTUAL_SHA256"
    exit 1
fi

echo "Validating IPA structure and TikTok version..."
unzip -q "$BASE_IPA" -d "$TMP_DIR/extracted"
INFO_PLIST="$TMP_DIR/extracted/Payload/TikTok.app/Info.plist"

if [[ ! -f "$INFO_PLIST" ]]; then
    echo "Error: Payload/TikTok.app/Info.plist not found in IPA."
    exit 1
fi

# Need to extract CFBundleShortVersionString
PLIST_BUDDY="/usr/libexec/PlistBuddy"
APP_VERSION=$($PLIST_BUDDY -c "Print CFBundleShortVersionString" "$INFO_PLIST")

if [[ "$APP_VERSION" != "$EXPECTED_VERSION" ]]; then
    echo "Error: IPA Version mismatch. Expected $EXPECTED_VERSION, found $APP_VERSION."
    exit 1
fi
echo "Verified TikTok version: $APP_VERSION"

echo "Setting up cyan..."
export PIPX_BIN_DIR="$TMP_DIR/pipx_bin"
export PATH="$PIPX_BIN_DIR:$PATH"
mkdir -p "$PIPX_BIN_DIR"
pipx install --force https://github.com/asdfzxcvbn/pyzule-rw/archive/740d3716dcd98c20c000f12cdb88f1f0b2a533a4.zip

echo "Injecting tweak using cyan..."
cyan -i "$BASE_IPA" -f "$TWEAK_DEB" -o "$OUT_IPA"

echo "Validating output IPA..."
if [[ ! -f "$OUT_IPA" ]]; then
    echo "Error: Injection failed, output IPA not found."
    exit 1
fi

unzip -q "$OUT_IPA" -d "$TMP_DIR/out_extracted"
DYLIB_PATH="$TMP_DIR/out_extracted/Payload/TikTok.app/ChronoKit.dylib"

if [[ ! -f "$DYLIB_PATH" ]]; then
    echo "Error: ChronoKit.dylib not found in output IPA."
    exit 1
fi

echo "Checking embedded dependencies..."
otool -L "$DYLIB_PATH"

if otool -L "$DYLIB_PATH" | grep -q "/var/jb"; then
    echo "Error: Unresolved /var/jb dependency found in output IPA!"
    exit 1
fi

echo "Calculating final IPA SHA256..."
sha256sum "$OUT_IPA"

rm -rf "$TMP_DIR"
echo "Successfully generated $OUT_IPA"
