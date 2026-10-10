#!/bin/sh
# Private glibc runtime for the official Linux ARM64 editor on Alpine/Android.
set -eu
yeti_runtime=${YETI_GODOT_RUNTIME:-/tmp/yeti-godot-debian-runtime}
yeti_binary=${YETI_GODOT_BINARY:-/tmp/godot-4.7.2/Godot_v4.7.2-stable_linux.arm64}
yeti_loader="$yeti_runtime/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1"
if [ ! -x "$yeti_loader" ] || [ ! -x "$yeti_binary" ]; then
    echo 'Prepare the private runtime with python3 tools/prepare_godot_arm64_runtime.py.' >&2
    exit 1
fi
if ! command -v flock >/dev/null 2>&1; then
    echo 'The private runtime runner requires flock (util-linux).' >&2
    exit 1
fi
if [ -d "$yeti_runtime/usr/lib/aarch64-linux-gnu/dri" ]; then
    LIBGL_DRIVERS_PATH="$yeti_runtime/usr/lib/aarch64-linux-gnu/dri"
    export LIBGL_DRIVERS_PATH
fi
if [ -d "$yeti_runtime/usr/share/X11/locale" ]; then
    XLOCALEDIR="$yeti_runtime/usr/share/X11/locale"
    export XLOCALEDIR
fi
exec flock --shared "$yeti_runtime/.yeti-runtime.lock" "$yeti_loader" --library-path "$yeti_runtime/lib/aarch64-linux-gnu:$yeti_runtime/usr/lib/aarch64-linux-gnu" "$yeti_binary" "$@"
