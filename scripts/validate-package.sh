#!/usr/bin/env bash
set -e

DEB_FILE="$1"
EXPECTED_SCHEME="$2"
CONTROL_VERSION=$(awk '/^Version:/ {print $2}' control)

if [[ ! -f "$DEB_FILE" ]]; then
    echo "Error: Debian package $DEB_FILE not found."
    exit 1
fi

if [[ -z "$EXPECTED_SCHEME" ]]; then
    echo "Usage: $0 <path_to_deb> [rootless|roothide]"
    exit 1
fi

echo "Validating $DEB_FILE for scheme $EXPECTED_SCHEME..."

TMP_DIR=$(mktemp -d)
dpkg-deb -I "$DEB_FILE" > "$TMP_DIR/info.txt"
dpkg-deb -c "$DEB_FILE" > "$TMP_DIR/contents.txt"
dpkg-deb -x "$DEB_FILE" "$TMP_DIR/ext"

# Check Package
PACKAGE_ID=$(awk '/^[ \t]*Package:/ {print $2}' "$TMP_DIR/info.txt")
if [[ "$PACKAGE_ID" != "com.kunihir0.chronokit" ]]; then
    echo "Validation failed: Expected Package com.kunihir0.chronokit, got $PACKAGE_ID"
    exit 1
fi

# Check Version
PKG_VERSION=$(awk '/^[ \t]*Version:/ {print $2}' "$TMP_DIR/info.txt")
if [[ "$PKG_VERSION" != "$CONTROL_VERSION" ]]; then
    echo "Validation failed: Expected Version $CONTROL_VERSION, got $PKG_VERSION"
    exit 1
fi

# Check Architecture
PKG_ARCH=$(awk '/^[ \t]*Architecture:/ {print $2}' "$TMP_DIR/info.txt")
if [[ "$EXPECTED_SCHEME" == "rootless" ]]; then
    if [[ "$PKG_ARCH" != "iphoneos-arm64" ]]; then
        echo "Validation failed: Expected Architecture iphoneos-arm64 for rootless, got $PKG_ARCH"
        exit 1
    fi
elif [[ "$EXPECTED_SCHEME" == "roothide" ]]; then
    if [[ "$PKG_ARCH" != "iphoneos-arm64e" ]]; then
        echo "Validation failed: Expected Architecture iphoneos-arm64e for roothide, got $PKG_ARCH"
        exit 1
    fi
fi

# Ensure Orion exists in Depends
PKG_DEPENDS=$(awk -F': ' '/^[ \t]*Depends:/ {print $2}' "$TMP_DIR/info.txt")
if [[ "$PKG_DEPENDS" != *"dev.theos.orion"* ]]; then
    echo "Validation failed: Dependency dev.theos.orion not found. (Got: $PKG_DEPENDS)"
    exit 1
fi

# Check paths inside the package
if grep -q "Users/" "$TMP_DIR/contents.txt"; then
    echo "Validation failed: Found accidental local paths like /Users/ in the package."
    exit 1
fi

if [[ "$EXPECTED_SCHEME" == "rootless" ]]; then
    if ! grep -q "var/jb/Library/MobileSubstrate/DynamicLibraries/ChronoKit.dylib" "$TMP_DIR/contents.txt"; then
        echo "Validation failed: ChronoKit.dylib not found at rootless path."
        exit 1
    fi
elif [[ "$EXPECTED_SCHEME" == "roothide" ]]; then
    if ! grep -q "var/jb/Library/MobileSubstrate/DynamicLibraries/ChronoKit.dylib" "$TMP_DIR/contents.txt"; then
        echo "Validation failed: ChronoKit.dylib not found at roothide path (RootHide theos standardizes var/jb)."
        exit 1
    fi
fi

# Check non-system dynamic dependencies (optional, just listing)
DYLIB_PATH="$TMP_DIR/ext/var/jb/Library/MobileSubstrate/DynamicLibraries/ChronoKit.dylib"
if [[ -f "$DYLIB_PATH" ]]; then
    echo "Dependencies for ChronoKit.dylib:"
    otool -L "$DYLIB_PATH" | grep -v "^\s*/usr/lib" | grep -v "^\s*/System/Library" || true
else
    echo "Error: $DYLIB_PATH not found in extracted files."
    exit 1
fi

# Ensure binary is stripped (no debug symbols)
if file "$DYLIB_PATH" | grep -q "not stripped"; then
    echo "Validation failed: ChronoKit.dylib contains debug symbols (not stripped)."
    exit 1
fi

rm -rf "$TMP_DIR"
echo "Validation passed for $DEB_FILE ($EXPECTED_SCHEME)"