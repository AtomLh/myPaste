#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>   e.g. $0 0.1.0"
    exit 1
fi

echo "==> Building release .app"
./scripts/make_app_bundle.sh release

RELEASE_DIR="build/release"
mkdir -p "$RELEASE_DIR"
ZIP_NAME="myPaste-$VERSION.zip"
ZIP_PATH="$RELEASE_DIR/$ZIP_NAME"
rm -f "$ZIP_PATH"

echo "==> Zipping"
(cd build && zip -ry "release/$ZIP_NAME" myPaste.app > /dev/null)

echo ""
echo "Release artifact:"
ls -lh "$ZIP_PATH"
echo ""
echo "Upload to a GitHub Release tagged v$VERSION."
