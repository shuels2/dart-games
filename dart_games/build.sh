#!/usr/bin/env bash
# Wrapper for `flutter build` / `flutter run` that injects BUILD_NUMBER
# from the current git commit count. Use this instead of bare flutter
# commands so the System Settings "Build N" label stays current.
#
# Production builds also disable the PWA service worker
# (--pwa-strategy=none) so the browser doesn't serve stale cached
# JS after a deploy. The `web/.htaccess` complements this on the
# Apache side.
#
# Examples:
#   ./build.sh run -d chrome
#   ./build.sh build web
#   ./build.sh build web --release
#
# Without this wrapper, BuildInfo.number falls back to 'dev' and
# the service worker re-enables itself in `flutter build web`.

set -euo pipefail

BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo dev)
echo "[build.sh] BUILD_NUMBER=${BUILD_NUMBER}"

# --pwa-strategy is a `flutter build web` flag only — passing it to
# `flutter run` errors out. Append only when the first arg is build.
if [ "${1:-}" = "build" ]; then
  exec flutter "$@" --pwa-strategy=none --dart-define=BUILD_NUMBER="${BUILD_NUMBER}"
else
  exec flutter "$@" --dart-define=BUILD_NUMBER="${BUILD_NUMBER}"
fi
