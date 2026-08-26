#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <repository-url> <commit> <destination>"
    exit 1
fi

REPOSITORY_URL="$1"
COMMIT="$2"
DESTINATION="$3"

if [[ ! "$COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Error: Theos revision must be a full commit SHA."
    exit 1
fi

rm -rf "$DESTINATION"
git clone --no-checkout "$REPOSITORY_URL" "$DESTINATION"
git -C "$DESTINATION" checkout --detach "$COMMIT"
git -C "$DESTINATION" submodule sync --recursive
git -C "$DESTINATION" submodule update --init --recursive
