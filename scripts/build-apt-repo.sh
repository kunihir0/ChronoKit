#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="${1:-packages}"
REPO_DIR="apt_repo"
DEBS_DIR="$REPO_DIR/debs"

if [[ ! -d "$PACKAGE_DIR" ]]; then
    echo "Error: package directory not found: $PACKAGE_DIR"
    exit 1
fi

shopt -s nullglob
packages=("$PACKAGE_DIR"/*.deb)
if [[ ${#packages[@]} -eq 0 ]]; then
    echo "Error: no Debian packages found in $PACKAGE_DIR"
    exit 1
fi

echo "Building APT repository in $REPO_DIR..."
rm -rf "$REPO_DIR"
mkdir -p "$DEBS_DIR"

for package in "${packages[@]}"; do
    package_version=$(dpkg-deb -f "$package" Version)
    if [[ "$package_version" == *debug* ]]; then
        echo "Error: debug package cannot enter the APT repository: $package"
        exit 1
    fi
    cp "$package" "$DEBS_DIR/"
done

cd "$REPO_DIR"

echo "Generating Packages file..."
dpkg-scanpackages --multiversion debs > Packages
bzip2 -k -f Packages
gzip -k -f Packages

echo "Generating Release file..."
cat <<'EOF' > Release
Origin: ChronoKit
Label: ChronoKit
Suite: stable
Version: 1.0
Codename: stable
Architectures: iphoneos-arm64 iphoneos-arm64e
Components: main
Description: ChronoKit package repository
EOF

append_checksums() {
    local heading="$1"
    local algorithm="$2"
    local file size digest

    echo "$heading:" >> Release
    for file in Packages Packages.gz Packages.bz2; do
        size=$(wc -c < "$file" | tr -d ' ')
        case "$algorithm" in
            md5) digest=$(md5 -q "$file") ;;
            sha1) digest=$(shasum -a 1 "$file" | awk '{print $1}') ;;
            sha256) digest=$(shasum -a 256 "$file" | awk '{print $1}') ;;
        esac
        printf ' %s %s %s\n' "$digest" "$size" "$file" >> Release
    done
}

append_checksums MD5Sum md5
append_checksums SHA1 sha1
append_checksums SHA256 sha256

echo "Creating index.html..."
cat <<'EOF' > index.html
<!DOCTYPE html>
<html>
<head>
    <title>ChronoKit Repository</title>
</head>
<body>
    <h1>ChronoKit Repository</h1>
    <p>Add this URL to Sileo or Zebra to install ChronoKit.</p>
</body>
</html>
EOF

echo "APT repository built successfully."
