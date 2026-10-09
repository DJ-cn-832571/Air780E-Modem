#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist build
IMAGE="$(mktemp -d "$PWD/build/dmg-stage.XXXXXX")"
VERSION="0.9.3"
OUT="dist/$VERSION"
mkdir -p "$OUT"
cp -R "build/Air780E Modem.app" "$IMAGE/"
cp README.md "$IMAGE/使用说明.md"
ln -s /Applications "$IMAGE/Applications"
ditto -c -k --sequesterRsrc --keepParent "build/Air780E Modem.app" "$OUT/Air780E-Modem-$VERSION-macos-arm64.zip"
hdiutil create -ov -volname "Air780E Modem" -srcfolder "$IMAGE" -format UDZO "$OUT/Air780E-Modem-$VERSION-macos-arm64.dmg"
COPY="$(mktemp -d /private/tmp/air780e-source.XXXXXX)"
mkdir "$COPY/Air780E-Modem"
cp -R src firmware scripts docs LICENSES .github README.md LICENSE CHANGELOG.md SECURITY.md CONTRIBUTING.md THIRD_PARTY_NOTICES.md requirements-build.txt .gitignore "$COPY/Air780E-Modem/"
find "$COPY/Air780E-Modem" -name __pycache__ -type d -exec /bin/rm -r {} +
ditto -c -k --keepParent "$COPY/Air780E-Modem" "$OUT/Air780E-Modem-$VERSION-source.zip"
"${PYTHON:-python3}" scripts/check_release.py "$OUT/Air780E-Modem-$VERSION-source.zip"
(cd "$OUT" && shasum -a 256 *.zip *.dmg > SHA256SUMS.txt)
echo "发布文件位于 ${OUT}；临时源码副本保留在 ${COPY}"
