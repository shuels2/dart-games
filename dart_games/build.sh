#!/usr/bin/env bash
# Wrapper for `flutter build` / `flutter run` that injects BUILD_NUMBER
# from the current git commit count. Use this instead of bare flutter
# commands so the System Settings "Build N" label stays current.
#
# Examples:
#   ./build.sh run -d chrome
#   ./build.sh build web
#   ./build.sh build web --release
#
# Without this wrapper, BuildInfo.number falls back to 'dev'.

set -euo pipefail

BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo dev)
echo "[build.sh] BUILD_NUMBER=${BUILD_NUMBER}"
exec flutter "$@" --dart-define=BUILD_NUMBER="${BUILD_NUMBER}"
