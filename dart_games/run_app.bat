@echo off

REM ============================================================
REM Dart Games - Full App Launcher
REM ============================================================
REM Starts a fresh backend server with a clean database, waits
REM for it to be ready, then launches the Flutter app in Chrome.
REM
REM Each launch starts with a blank database so the app behaves
REM like a first-time install (dartboard setup screen first).
REM
REM Usage:
REM   run_app.bat                   Launch with defaults (port 8080)
REM   run_app.bat --port 9090       Launch server on custom port
REM   run_app.bat --keep-data       Preserve database between runs
REM
REM Press q in the Flutter console to quit. The server is cleaned
REM up automatically on exit.
REM ============================================================

echo.
echo ============================================================
echo  Dart Games Launcher
echo ============================================================

set SERVER_PORT=8080
set KEEP_DATA=0
set DATA_DIR=playground_data

REM Parse arguments
:parse_args
if "%~1"=="" goto done_args
if "%~1"=="--port" (
    set SERVER_PORT=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--keep-data" (
    set KEEP_DATA=1
    shift
    goto parse_args
)
shift
goto parse_args
:done_args

set SERVER_URL=http://localhost:%SERVER_PORT%
set DB_PATH=%DATA_DIR%\dart_games.db

REM Kill any existing server on this port
call :kill_port %SERVER_PORT%

REM Clean the database for a fresh start (unless --keep-data)
if "%KEEP_DATA%"=="0" (
    if exist "server\%DATA_DIR%" (
        echo Clearing previous database for fresh start...
        rmdir /s /q "server\%DATA_DIR%"
    )
    echo Starting with clean database.
) else (
    echo Keeping existing database.
)

REM Create data directory
if not exist "server\%DATA_DIR%" mkdir "server\%DATA_DIR%"

REM Verify server exists
if not exist "server\bin\server.dart" (
    echo.
    echo ERROR: Backend server not found at server\bin\server.dart
    pause
    exit /b 1
)

REM Ensure server dependencies are installed
if not exist "server\.dart_tool\package_config.json" (
    echo.
    echo Installing server dependencies...
    pushd server
    dart pub get
    if errorlevel 1 (
        echo ERROR: Failed to install server dependencies.
        popd
        pause
        exit /b 1
    )
    popd
)

REM Start the server in the background
echo.
echo Starting backend server on port %SERVER_PORT%...
start /b "" cmd /c "cd server && dart run bin/server.dart --port %SERVER_PORT% --data-dir %DATA_DIR% --db-path %DB_PATH%"

REM Wait for server to be ready (up to 15 seconds)
echo Waiting for server to be ready...
set ATTEMPTS=0
:wait_loop
if %ATTEMPTS% geq 15 (
    echo.
    echo ERROR: Server did not start within 15 seconds.
    echo Try running start_server.bat manually to see errors.
    pause
    exit /b 1
)
timeout /t 1 /nobreak >nul 2>&1
curl -s "%SERVER_URL%/api/v1/settings" >nul 2>&1
if not errorlevel 1 goto server_ready
set /a ATTEMPTS+=1
goto wait_loop

:server_ready
echo Server is ready.

REM Ensure Flutter dependencies are installed
if not exist ".dart_tool\package_config.json" (
    echo.
    echo Installing Flutter dependencies...
    flutter pub get
    if errorlevel 1 (
        echo ERROR: Failed to install Flutter dependencies.
        pause
        exit /b 1
    )
)

echo.
echo ============================================================
echo  Launching Dart Games in Chrome...
echo  Server:   %SERVER_URL%
echo  Database: server/%DB_PATH%
echo  Press q in this window to quit the app.
echo ============================================================
echo.

flutter run -d chrome

REM After Flutter exits, kill the server
echo.
echo Shutting down server...
call :kill_port %SERVER_PORT%
echo Done.
exit /b 0

REM ---- Subroutine: kill process listening on a port ----
:kill_port
setlocal
set "_port=%~1"
for /f "usebackq tokens=5" %%p in (`netstat -ano ^| findstr ":%_port% " ^| findstr "LISTENING"`) do (
    echo Stopping process on port %_port% (PID %%p^)...
    taskkill /pid %%p /f >nul 2>&1
)
endlocal
exit /b 0
