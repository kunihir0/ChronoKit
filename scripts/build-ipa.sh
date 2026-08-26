#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path_to_deb>"
    exit 1
fi

TWEAK_DEB="$1"
if [[ ! -f "$TWEAK_DEB" ]]; then
    echo "Error: Debian package not found."
    exit 1
fi

if [[ -z "${TIKTOK_IPA_URL:-}" || -z "${TIKTOK_IPA_SHA256:-}" ]]; then
    echo "Error: missing required GitHub secrets:"
    echo "  TIKTOK_IPA_URL"
    echo "  TIKTOK_IPA_SHA256"
    echo "Configure them interactively with:"
    echo "  gh secret set TIKTOK_IPA_URL"
    echo "  gh secret set TIKTOK_IPA_SHA256"
    exit 1
fi
if [[ ! "$TIKTOK_IPA_SHA256" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "Error: base IPA SHA256 secret is not valid SHA256 format."
    exit 1
fi

EXPECTED_VERSION=$(awk -F'"' '/supportedVersionString =/ {print $2; exit}' Sources/ChronoKit/Managers/BypassStatusManager.swift)
EXPECTED_BUNDLE_ID=$(awk -F'"' '/Bundles/ {print $2; exit}' ChronoKit.plist)
if [[ -z "$EXPECTED_VERSION" || -z "$EXPECTED_BUNDLE_ID" ]]; then
    echo "Error: could not derive TikTok support identity from ChronoKit sources."
    exit 1
fi

PACKAGE_ID=$(dpkg-deb -f "$TWEAK_DEB" Package)
CHRONOKIT_VERSION=$(dpkg-deb -f "$TWEAK_DEB" Version)
PACKAGE_ARCH=$(dpkg-deb -f "$TWEAK_DEB" Architecture)
if [[ "$PACKAGE_ID" != "com.kunihir0.chronokit" || "$PACKAGE_ARCH" != "iphoneos-arm64" ]]; then
    echo "Error: injection requires the validated ChronoKit Rootless package."
    exit 1
fi
if [[ ! "$CHRONOKIT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: ChronoKit package version is not a production semantic version."
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
BASE_IPA="$TMP_DIR/base.ipa"
OUT_IPA="TikTok_${EXPECTED_VERSION}_ChronoKit_${CHRONOKIT_VERSION}.ipa"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

curl --fail --location --silent --show-error \
    --output "$BASE_IPA" \
    "$TIKTOK_IPA_URL"

ACTUAL_SHA256=$(shasum -a 256 "$BASE_IPA" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$TIKTOK_IPA_SHA256" ]]; then
    echo "Error: base IPA SHA256 verification failed."
    exit 1
fi

unzip -tq "$BASE_IPA" >/dev/null
unzip -q "$BASE_IPA" -d "$TMP_DIR/input"
shopt -s nullglob
input_apps=("$TMP_DIR/input/Payload/"*.app)
if [[ ${#input_apps[@]} -ne 1 ]]; then
    echo "Error: base IPA must contain exactly one Payload application."
    exit 1
fi
INPUT_APP="${input_apps[0]}"
INPUT_PLIST="$INPUT_APP/Info.plist"
if [[ ! -f "$INPUT_PLIST" ]]; then
    echo "Error: base application Info.plist is missing."
    exit 1
fi

INPUT_BUNDLE_ID=$($PLIST_BUDDY -c 'Print CFBundleIdentifier' "$INPUT_PLIST")
INPUT_VERSION=$($PLIST_BUDDY -c 'Print CFBundleShortVersionString' "$INPUT_PLIST")
INPUT_EXECUTABLE=$($PLIST_BUDDY -c 'Print CFBundleExecutable' "$INPUT_PLIST")
if [[ "$INPUT_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
    echo "Error: base IPA does not target ChronoKit's TikTok bundle."
    exit 1
fi
if [[ "$INPUT_VERSION" != "$EXPECTED_VERSION" ]]; then
    echo "Error: base IPA TikTok version is unsupported."
    exit 1
fi
if [[ ! -f "$INPUT_APP/$INPUT_EXECUTABLE" ]]; then
    echo "Error: base IPA main executable is missing."
    exit 1
fi
rm -rf "$TMP_DIR/input"

echo "Setting up pinned cyan injector..."
export PIPX_BIN_DIR="$TMP_DIR/pipx_bin"
export PATH="$PIPX_BIN_DIR:$PATH"
mkdir -p "$PIPX_BIN_DIR"
# Cyan source is commit-pinned; pipx resolves its declared Python dependencies at runtime.
pipx install --force \
    https://github.com/asdfzxcvbn/pyzule-rw/archive/740d3716dcd98c20c000f12cdb88f1f0b2a533a4.zip

cyan -i "$BASE_IPA" -f "$TWEAK_DEB" -o "$OUT_IPA"
rm -f "$BASE_IPA"

if [[ ! -f "$OUT_IPA" ]]; then
    echo "Error: injector did not produce an IPA."
    exit 1
fi
unzip -tq "$OUT_IPA" >/dev/null
unzip -q "$OUT_IPA" -d "$TMP_DIR/output"
output_apps=("$TMP_DIR/output/Payload/"*.app)
if [[ ${#output_apps[@]} -ne 1 ]]; then
    echo "Error: output IPA must contain exactly one Payload application."
    exit 1
fi
OUTPUT_APP="${output_apps[0]}"
OUTPUT_PLIST="$OUTPUT_APP/Info.plist"
OUTPUT_BUNDLE_ID=$($PLIST_BUDDY -c 'Print CFBundleIdentifier' "$OUTPUT_PLIST")
OUTPUT_VERSION=$($PLIST_BUDDY -c 'Print CFBundleShortVersionString' "$OUTPUT_PLIST")
OUTPUT_EXECUTABLE=$($PLIST_BUDDY -c 'Print CFBundleExecutable' "$OUTPUT_PLIST")
MAIN_EXECUTABLE="$OUTPUT_APP/$OUTPUT_EXECUTABLE"
if [[ "$OUTPUT_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" || "$OUTPUT_VERSION" != "$EXPECTED_VERSION" ]]; then
    echo "Error: output IPA changed the TikTok identity or supported version."
    exit 1
fi
if [[ ! -f "$MAIN_EXECUTABLE" ]]; then
    echo "Error: output IPA main executable is missing."
    exit 1
fi

chronokit_dylibs=()
while IFS= read -r dylib; do
    chronokit_dylibs+=("$dylib")
done < <(find "$OUTPUT_APP" -type f -name ChronoKit.dylib -print)
if [[ ${#chronokit_dylibs[@]} -ne 1 ]]; then
    echo "Error: output IPA must contain exactly one ChronoKit.dylib."
    exit 1
fi
DYLIB_PATH="${chronokit_dylibs[0]}"

if ! otool -L "$MAIN_EXECUTABLE" | grep -q 'ChronoKit\.dylib'; then
    echo "Error: TikTok executable does not load ChronoKit.dylib."
    exit 1
fi

LOAD_COMMANDS=$(otool -l "$DYLIB_PATH"; otool -l "$MAIN_EXECUTABLE")
if grep -Eq '/var/jb|\.jbroot|/Users/' <<< "$LOAD_COMMANDS"; then
    echo "Error: output IPA contains unresolved jailbreak or developer load paths."
    exit 1
fi

resolve_dependency() {
    local dependency="$1"
    local relative candidate
    local matches=()

    case "$dependency" in
        /System/Library/*|/usr/lib/*)
            return 0
            ;;
        @executable_path/*)
            relative="${dependency#@executable_path/}"
            candidate="$OUTPUT_APP/$relative"
            [[ -f "$candidate" ]] || return 1
            ;;
        @loader_path/*)
            relative="${dependency#@loader_path/}"
            candidate="$(dirname "$DYLIB_PATH")/$relative"
            [[ -f "$candidate" ]] || return 1
            ;;
        @rpath/*)
            relative="${dependency#@rpath/}"
            while IFS= read -r candidate; do
                matches+=("$candidate")
            done < <(find "$OUTPUT_APP" -type f -path "*/$relative" -print)
            [[ ${#matches[@]} -ge 1 ]] || return 1
            ;;
        /*)
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

orion_dependency=false
substrate_dependency=false
while IFS= read -r dependency; do
    [[ -n "$dependency" ]] || continue
    if [[ "$dependency" == *ChronoKit.dylib ]]; then
        continue
    fi
    if ! resolve_dependency "$dependency"; then
        echo "Error: unresolved non-system ChronoKit dependency: $dependency"
        exit 1
    fi
    [[ "$dependency" == *Orion* ]] && orion_dependency=true
    if [[ "$dependency" =~ CydiaSubstrate|ElleKit|libsubstrate|substitute ]]; then
        substrate_dependency=true
    fi
done < <(otool -L "$DYLIB_PATH" | awk 'NR > 1 {print $1}')

if [[ "$orion_dependency" != true ]]; then
    echo "Error: embedded Orion dependency was not verified."
    exit 1
fi
if [[ "$substrate_dependency" != true ]]; then
    echo "Error: embedded substrate or ElleKit compatibility dependency was not verified."
    exit 1
fi
if find "$OUTPUT_APP" -type f \( -name '*.ipa' -o -name '*.deb' \) -print | grep -q .; then
    echo "Error: output application contains nested source packages."
    exit 1
fi

shasum -a 256 "$OUT_IPA"
echo "Successfully generated $OUT_IPA"
