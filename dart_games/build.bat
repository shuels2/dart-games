@echo off
REM Wrapper for `flutter build` / `flutter run` that injects BUILD_NUMBER
REM from the current git commit count. Use this instead of bare flutter
REM commands so the System Settings "Build N" label stays current.
REM
REM Production builds also disable the PWA service worker
REM (--pwa-strategy=none) so the browser doesn't serve stale cached
REM JS after a deploy. The `web/.htaccess` complements this on the
REM Apache side.
REM
REM Examples:
REM   build.bat run -d chrome
REM   build.bat build web
REM   build.bat build web --release
REM
REM Without this wrapper, BuildInfo.number falls back to 'dev' and
REM the service worker re-enables itself in `flutter build web`.

setlocal
for /f %%i in ('git rev-list --count HEAD') do set BUILD_NUMBER=%%i
if "%BUILD_NUMBER%"=="" set BUILD_NUMBER=dev

echo [build.bat] BUILD_NUMBER=%BUILD_NUMBER%

REM --pwa-strategy is a `flutter build web` flag only — passing it to
REM `flutter run` errors out. Append only when the first arg is build.
if "%1"=="build" (
    flutter %* --pwa-strategy=none --dart-define=BUILD_NUMBER=%BUILD_NUMBER%
) else (
    flutter %* --dart-define=BUILD_NUMBER=%BUILD_NUMBER%
)
endlocal
