#!/bin/sh
# Copies the shared core into every prototype.
#
# App playgrounds must be self-contained — Swift Playgrounds and the Swift
# Student Challenge ZIP cannot follow a symlink or a local package — so each
# prototype carries its own copy of Shared/HolosCore in a Core/ folder.
# Edit Shared/HolosCore, never a prototype's Core/, then run this script.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
for playground in "$root"/Prototypes/*.swiftpm; do
    rm -rf "$playground/Core"
    mkdir -p "$playground/Core"
    cp -R "$root/Shared/HolosCore/." "$playground/Core/"
    echo "synced $(basename "$playground")"
done
