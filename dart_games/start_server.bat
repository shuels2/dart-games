@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Dart Games Backend Server Launcher
REM ============================================================
REM Checks dependencies, then starts the backend server.
REM All arguments are forwarded to the server.
REM
REM Usage:
REM   start_server.bat                              Default (port 8080)
REM   start_server.bat --port 9090                  Custom port
REM   start_server.bat --data-dir /path/to/data     Custom data dir
REM   start_server.bat --db-path /path/to/db        Custom database path
REM ============================================================

echo.
echo ============================================================
echo Dart Games Backend Server
echo ============================================================

REM Verify server exists
if not exist "server\bin\server.dart" (
    echo.
    echo ERROR: Backend server not found at server\bin\server.dart
    echo Please ensure the server directory is set up correctly.
    pause
    exit /b 1
)

REM Ensure dependencies are installed
if not exist "server\.dart_tool\package_config.json" (
    echo.
    echo Installing server dependencies...
    pushd server
    dart pub get
    if !errorlevel! neq 0 (
        echo.
        echo ERROR: Failed to install server dependencies.
        popd
        pause
        exit /b 1
    )
    popd
    echo Dependencies installed.
) else (
    echo Dependencies already installed.
)

REM Start the server, forwarding all arguments
echo.
echo Starting server...
echo.
cd server
dart run bin/server.dart %*
