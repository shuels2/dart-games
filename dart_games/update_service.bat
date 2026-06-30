@echo off
setlocal

REM ============================================================
REM Dart Games - Update Running Service
REM ============================================================
REM Pulls the latest code, recompiles the server, rebuilds the
REM Flutter web app, and restarts the DartGamesServer service.
REM
REM Run as Administrator. Assumes install_service.bat has been
REM run successfully at least once.
REM ============================================================

set SERVICE_ID=DartGamesServer
set REPO_DIR=%~dp0
if "%REPO_DIR:~-1%"=="\" set REPO_DIR=%REPO_DIR:~0,-1%
set SERVER_DIR=%REPO_DIR%\server
set WINSW_EXE=%REPO_DIR%\dart-games-service.exe

net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This script must be run as Administrator.
    pause
    exit /b 1
)

if not exist "%WINSW_EXE%" (
    echo ERROR: Service does not appear to be installed.
    echo Run install_service.bat first.
    pause
    exit /b 1
)

echo.
echo [1/5] Pulling latest code...
pushd "%REPO_DIR%\.."
git pull
if errorlevel 1 ( echo ERROR: git pull failed. & popd & pause & exit /b 1 )
popd

echo.
echo [2/5] Stopping service...
"%WINSW_EXE%" stop
REM Ignore errorlevel - service may not be running, that's OK

echo.
echo [3/5] Recompiling server...
pushd "%SERVER_DIR%"
call dart pub get
if errorlevel 1 ( echo ERROR: dart pub get failed. & popd & pause & exit /b 1 )
call dart compile exe bin\server.dart -o bin\server.exe
if errorlevel 1 ( echo ERROR: dart compile exe failed. & popd & pause & exit /b 1 )
popd

echo.
echo [4/5] Rebuilding Flutter web app...
pushd "%REPO_DIR%"
if exist "build.bat" (
    call build.bat build web
) else (
    call flutter build web --pwa-strategy=none
)
if errorlevel 1 ( echo ERROR: flutter build web failed. & popd & pause & exit /b 1 )
popd

echo.
echo [5/5] Starting service...
"%WINSW_EXE%" start
if errorlevel 1 (
    echo ERROR: Failed to start service after update.
    echo Check logs in logs\service\
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Update complete. Service is running with new code.
echo ============================================================

endlocal
pause
exit /b 0
