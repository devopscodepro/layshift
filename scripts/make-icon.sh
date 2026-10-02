#!/bin/sh
# Renders the app icon into the asset catalog at every size macOS wants.
set -eu
cd "$(dirname "$0")/.."
OUT=LayShift/Resources/Assets.xcassets/AppIcon.appiconset
swiftc -O -o build/app-icon scripts/app-icon.swift
for size in 16 32 64 128 256 512 1024; do
    build/app-icon "$size" "$OUT/icon_$size.png"
done
rm -f build/app-icon
