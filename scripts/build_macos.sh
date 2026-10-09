#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -m)" == arm64 ]] || { echo "目前只支持 Apple Silicon 构建"; exit 1; }
PYTHON="${PYTHON:-python3}"
export PYINSTALLER_CONFIG_DIR="$PWD/build/pyinstaller-cache"
"$PYTHON" -m venv .build-venv
.build-venv/bin/python -m pip install -r requirements-build.txt
.build-venv/bin/python -m unittest discover -s src -p 'test_*.py'
.build-venv/bin/python -m PyInstaller --noconfirm --clean --onedir --name modem-backend --distpath build/backend --workpath build/pyinstaller --specpath build src/backend_entry.py
STAGE="$(mktemp -d "$PWD/build/app-stage.XXXXXX")"
APP="$STAGE/Air780E Modem.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/backend" "$APP/Contents/Resources/firmware"
cp -R build/backend/modem-backend/. "$APP/Contents/Resources/backend/"
cp -R firmware/lua "$APP/Contents/Resources/firmware/"
cp -R LICENSES "$APP/Contents/Resources/"
cp LICENSE README.md "$APP/Contents/Resources/"
cp -R docs "$APP/Contents/Resources/"
cp CHANGELOG.md THIRD_PARTY_NOTICES.md SECURITY.md CONTRIBUTING.md "$APP/Contents/Resources/"
cp scripts/Info.plist "$APP/Contents/Info.plist"
xcrun swiftc -target arm64-apple-macos26.0 -module-cache-path build/swift-module-cache src/ModemApp.swift src/EmailSettings.swift -framework Cocoa -framework Security -o "$APP/Contents/MacOS/Air780E Modem"
codesign --force --deep --sign "${SIGN_IDENTITY:--}" "$APP"
"$APP/Contents/Resources/backend/modem-backend" --self-test
codesign --verify --deep --strict "$APP"
if [ -d "build/Air780E Modem.app" ]; then
    PREVIOUS="$(mktemp -d "$PWD/build/previous-app.XXXXXX")"
    mv "build/Air780E Modem.app" "$PREVIOUS/"
fi
mv "$APP" "build/Air780E Modem.app"
