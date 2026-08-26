#!/usr/bin/env bash
set -e

REPO_DIR="apt_repo"
DEBS_DIR="$REPO_DIR/debs"

echo "Building APT repository in $REPO_DIR..."

rm -rf "$REPO_DIR"
mkdir -p "$DEBS_DIR"

# Copy validated release packages
find packages -name "*.deb" -type f ! -name "*debug*" -exec cp {} "$DEBS_DIR/" \;

cd "$REPO_DIR"

echo "Generating Packages file..."
dpkg-scanpackages --multiversion debs > Packages
bzip2 -k -f Packages
gzip -k -f Packages

echo "Generating Release file..."
cat <<EOF > Release
Origin: ChronoKit
Label: ChronoKit
Suite: stable
Version: 1.0
Codename: stable
Architectures: iphoneos-arm64 iphoneos-arm64e
Components: main
Description: ChronoKit package repository
EOF

# Calculate hashes for the Release file
echo "MD5Sum:" >> Release
md5sum Packages Packages.gz Packages.bz2 | awk '{printf " %s %s %s\n", $1, "0", $2}' >> Release
echo "SHA1:" >> Release
sha1sum Packages Packages.gz Packages.bz2 | awk '{printf " %s %s %s\n", $1, "0", $2}' >> Release
echo "SHA256:" >> Release
sha256sum Packages Packages.gz Packages.bz2 | awk '{printf " %s %s %s\n", $1, "0", $2}' >> Release

echo "Creating index.html..."
cat <<EOF > index.html
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

cd ..
echo "APT repository built successfully."
