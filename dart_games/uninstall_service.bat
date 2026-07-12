@echo off
setlocal

REM ============================================================
REM Dart Games - Uninstall Windows Service
REM ============================================================
REM Stops and removes the DartGamesServer service. Leaves the
REM compiled server.exe, built web app, data, and logs in place.
REM
REM Run as Administrator.
REM ============================================================

set SERVICE_ID=DartGamesServer
set REPO_DIR=%~dp0
if "%REPO_DIR:~-1%"=="\" set REPO_DIR=%REPO_DIR:~0,-1%
set WINSW_EXE=%REPO_DIR%\dart-games-service.exe
set WINSW_XML=%REPO_DIR%\dart-games-service.xml

net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This script must be run as Administrator.
    pause
    exit /b 1
)

if not exist "%WINSW_EXE%" (
    echo ERROR: WinSW exe not found at %WINSW_EXE%
    echo Cannot uninstall without it. If you deleted it, you can
    echo still remove the service with: sc delete %SERVICE_ID%
    pause
    exit /b 1
)

echo Stopping %SERVICE_ID%...
"%WINSW_EXE%" stop >nul 2>&1

echo Uninstalling %SERVICE_ID%...
"%WINSW_EXE%" uninstall
if errorlevel 1 (
    echo ERROR: winsw uninstall failed.
    pause
    exit /b 1
)

REM Delete the generated XML (contains the password)
if exist "%WINSW_XML%" (
    echo Deleting %WINSW_XML% ^(contained service password^)...
    del /f /q "%WINSW_XML%"
)

echo.
echo Service '%SERVICE_ID%' removed.
echo Logs, data, server.exe, and build\web are still on disk.
echo (Delete them manually if you want a full cleanup.)

endlocal
pause
exit /b 0
