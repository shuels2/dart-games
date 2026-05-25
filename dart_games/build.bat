@echo off
REM Wrapper for `flutter build` / `flutter run` that injects BUILD_NUMBER
REM from the current git commit count. Use this instead of bare flutter
REM commands so the System Settings "Build N" label stays current.
REM
REM Examples:
REM   build.bat run -d chrome
REM   build.bat build web
REM   build.bat build web --release
REM
REM Without this wrapper, BuildInfo.number falls back to 'dev'.

setlocal
for /f %%i in ('git rev-list --count HEAD') do set BUILD_NUMBER=%%i
if "%BUILD_NUMBER%"=="" set BUILD_NUMBER=dev

echo [build.bat] BUILD_NUMBER=%BUILD_NUMBER%
flutter %* --dart-define=BUILD_NUMBER=%BUILD_NUMBER%
endlocal
