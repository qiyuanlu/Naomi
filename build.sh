#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p build/module-cache
stage_dir=$(mktemp -d /tmp/nuomi-build.XXXXXX)
trap 'rm -rf "$stage_dir"' EXIT
app_path="$stage_dir/Nuomi.app"
mkdir -p "$app_path/Contents/"{MacOS,Resources}
swiftc -O -target arm64-apple-macosx13.0 -module-cache-path build/module-cache Sources/Geometry.swift Sources/Behavior.swift Sources/main.swift -o "$app_path/Contents/MacOS/Nuomi" -framework AppKit
cp -X assets/spritesheet-extended.png "$app_path/Contents/Resources/"
cp -X assets/Nuomi.icns "$app_path/Contents/Resources/"
cp -X Info.plist "$app_path/Contents/"
codesign --force --sign - "$app_path"
codesign --verify --deep --strict "$app_path"
/usr/bin/ditto --norsrc --noextattr "$app_path" build/Nuomi.app
codesign --verify --deep build/Nuomi.app
