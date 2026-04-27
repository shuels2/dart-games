@echo off

REM ============================================================
REM Dart Games - Full App Launcher
REM ============================================================
REM Starts the backend server and launches the Flutter app in Chrome.
REM
REM Usage:
REM   run_app.bat                   Launch with default database (persistent)
REM   run_app.bat --fresh           Clear default database and start clean
REM   run_app.bat --temp            Use a temporary database (deleted on exit)
REM   run_app.bat --port 9090       Launch server on custom port
REM
REM Press q in the Flutter console to quit. The server is cleaned
REM up automatically on exit.
REM ============================================================

echo.
echo ============================================================
echo  Dart Games Launcher
echo ============================================================

set SERVER_PORT=8080
set MODE=default

REM Parse arguments
:parse_args
if "%~1"=="" goto done_args
if "%~1"=="--port" (
    set SERVER_PORT=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--fresh" (
    set MODE=fresh
    shift
    goto parse_args
)
if "%~1"=="--temp" (
    set MODE=temp
    shift
    goto parse_args
)
shift
goto parse_args
:done_args

set SERVER_URL=http://localhost:%SERVER_PORT%

REM Set data directory based on mode
if "%MODE%"=="temp" (
    set DATA_DIR=temp_data_%RANDOM%
) else (
    set DATA_DIR=data
)
set DB_PATH=%DATA_DIR%\dart_games.db

REM Kill any existing server on this port
call :kill_port %SERVER_PORT%

REM Handle database based on mode
if "%MODE%"=="fresh" (
    if exist "server\%DATA_DIR%" (
        echo Clearing default database for fresh start...
        rmdir /s /q "server\%DATA_DIR%"
    )
    echo Starting with clean database.
) else if "%MODE%"=="temp" (
    echo Using temporary database (will be deleted on exit^).
) else (
    echo Using default database.
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
echo  Mode:     %MODE%
echo  Database: server/%DB_PATH%
echo  Type Q and press Enter in this window to stop the server and exit.
echo ============================================================
echo.

flutter run -d chrome

echo.
echo ============================================================
echo  App is running in Chrome.
echo  Type Q and press Enter to shut down the server and exit...
echo ============================================================
:wait_quit
set /p "QUIT_INPUT=> "
if /i "%QUIT_INPUT%"=="q" goto do_shutdown
echo Type Q to quit.
goto wait_quit
:do_shutdown

REM After user presses a key, kill the server
echo.
echo Shutting down server...
call :kill_port %SERVER_PORT%

REM Clean up temp database if using --temp mode
if "%MODE%"=="temp" (
    if exist "server\%DATA_DIR%" (
        echo Removing temporary database...
        rmdir /s /q "server\%DATA_DIR%"
    )
)

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
