@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM ChromeDriver Version Sync Script
REM ============================================================
REM Checks the installed Chrome version, compares it to the
REM installed ChromeDriver version, and downloads the matching
REM ChromeDriver if they differ. Kills any running chromedriver
REM processes before updating.
REM
REM Usage:
REM   update_chromedriver.bat          Run check and update
REM   update_chromedriver.bat --force  Force re-download even if versions match
REM ============================================================

set "CHROMEDRIVER_DIR=chromedriver\chromedriver-win64"
set "CHROMEDRIVER_EXE=%CHROMEDRIVER_DIR%\chromedriver.exe"
set "CHROMEDRIVER_ZIP=chromedriver\chromedriver.zip"
set "FORCE_UPDATE=0"

if "%~1"=="--force" set "FORCE_UPDATE=1"

echo.
echo ============================================================
echo ChromeDriver Version Check
echo ============================================================

REM ============================================================
REM Step 1: Get Chrome version
REM ============================================================
echo.
echo [1/5] Detecting Chrome version...

set "CHROME_VERSION="
set "CHROME_MAJOR="

REM Try standard install path
set "CHROME_EXE=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist "!CHROME_EXE!" (
    set "CHROME_EXE=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
)
if not exist "!CHROME_EXE!" (
    echo ERROR: Google Chrome not found.
    echo Checked:
    echo   C:\Program Files\Google\Chrome\Application\chrome.exe
    echo   C:\Program Files ^(x86^)\Google\Chrome\Application\chrome.exe
    echo.
    echo Please install Google Chrome or update the path in this script.
    exit /b 1
)

REM Get Chrome version via PowerShell (most reliable method)
for /f "usebackq tokens=*" %%V in (`powershell -NoProfile -Command "(Get-Item '%CHROME_EXE%').VersionInfo.FileVersion"`) do (
    set "CHROME_VERSION=%%V"
)

if "!CHROME_VERSION!"=="" (
    echo ERROR: Could not determine Chrome version.
    exit /b 1
)

REM Extract major version (first number before the dot)
for /f "tokens=1 delims=." %%M in ("!CHROME_VERSION!") do (
    set "CHROME_MAJOR=%%M"
)

echo   Chrome path:    !CHROME_EXE!
echo   Chrome version: !CHROME_VERSION!
echo   Major version:  !CHROME_MAJOR!

REM ============================================================
REM Step 2: Get current ChromeDriver version
REM ============================================================
echo.
echo [2/5] Detecting ChromeDriver version...

set "DRIVER_VERSION="
set "DRIVER_MAJOR="

if exist "!CHROMEDRIVER_EXE!" (
    for /f "tokens=2" %%V in ('"!CHROMEDRIVER_EXE!" --version 2^>nul') do (
        if "!DRIVER_VERSION!"=="" set "DRIVER_VERSION=%%V"
    )
)

if "!DRIVER_VERSION!"=="" (
    echo   ChromeDriver: NOT FOUND
    set "DRIVER_MAJOR=0"
) else (
    for /f "tokens=1 delims=." %%M in ("!DRIVER_VERSION!") do (
        set "DRIVER_MAJOR=%%M"
    )
    echo   ChromeDriver version: !DRIVER_VERSION!
    echo   Major version:        !DRIVER_MAJOR!
)

REM ============================================================
REM Step 3: Compare versions
REM ============================================================
echo.
echo [3/5] Comparing versions...

if "!FORCE_UPDATE!"=="1" (
    echo   Force update requested. Proceeding with download.
    goto :do_update
)

if not "!CHROME_MAJOR!"=="!DRIVER_MAJOR!" goto :version_mismatch

echo   Chrome major version ^(!CHROME_MAJOR!^) matches ChromeDriver major version ^(!DRIVER_MAJOR!^).
echo   ChromeDriver is up to date. No update needed.
echo.
echo ============================================================
echo ChromeDriver Check: PASSED
echo ============================================================
echo.
exit /b 0

:version_mismatch
echo   MISMATCH: Chrome is v!CHROME_MAJOR!, ChromeDriver is v!DRIVER_MAJOR!
echo   Update required.

:do_update

REM ============================================================
REM Step 4: Kill running chromedriver processes
REM ============================================================
echo.
echo [4/5] Stopping running ChromeDriver processes...

taskkill /F /IM chromedriver.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo   Killed running chromedriver.exe processes.
    timeout /t 3 /nobreak >nul
) else (
    echo   No running chromedriver.exe processes found.
)

REM ============================================================
REM Step 5: Download and install matching ChromeDriver
REM ============================================================
echo.
echo [5/5] Downloading ChromeDriver for Chrome v!CHROME_MAJOR!...

REM Get the latest ChromeDriver version for this Chrome major version
set "LATEST_DRIVER_VERSION="
for /f "usebackq tokens=*" %%V in (`powershell -NoProfile -Command "try { [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri 'https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_!CHROME_MAJOR!' -UseBasicParsing).Content).Trim() } catch { '' }"`) do (
    set "LATEST_DRIVER_VERSION=%%V"
)

if "!LATEST_DRIVER_VERSION!"=="" (
    echo ERROR: Could not find a ChromeDriver release for Chrome v!CHROME_MAJOR!.
    echo This may mean Chrome v!CHROME_MAJOR! is too new and ChromeDriver hasn't been released yet.
    echo.
    echo Try updating Chrome or check https://googlechromelabs.github.io/chrome-for-testing/
    exit /b 1
)

echo   Latest ChromeDriver for v!CHROME_MAJOR!: !LATEST_DRIVER_VERSION!

set "DOWNLOAD_URL=https://storage.googleapis.com/chrome-for-testing-public/!LATEST_DRIVER_VERSION!/win64/chromedriver-win64.zip"
echo   Download URL: !DOWNLOAD_URL!
echo.
echo   Downloading...

REM Ensure chromedriver directory exists
if not exist "chromedriver" mkdir "chromedriver"

REM Download the zip file
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '!DOWNLOAD_URL!' -OutFile '!CHROMEDRIVER_ZIP!' -UseBasicParsing; exit 0 } catch { Write-Host \"ERROR: Download failed - $_\"; exit 1 }"
if !errorlevel! neq 0 (
    echo ERROR: Failed to download ChromeDriver.
    exit /b 1
)

echo   Download complete.
echo.
echo   Extracting...

REM Back up existing chromedriver.exe (just in case)
if exist "!CHROMEDRIVER_EXE!" (
    copy /Y "!CHROMEDRIVER_EXE!" "!CHROMEDRIVER_DIR!\chromedriver.exe.bak" >nul 2>&1
)

REM Extract - the zip contains a chromedriver-win64/ folder
powershell -NoProfile -Command "try { Expand-Archive -Path '!CHROMEDRIVER_ZIP!' -DestinationPath 'chromedriver\temp_extract' -Force; exit 0 } catch { Write-Host \"ERROR: Extraction failed - $_\"; exit 1 }"
if !errorlevel! neq 0 (
    echo ERROR: Failed to extract ChromeDriver.
    REM Restore backup if extraction failed
    if exist "!CHROMEDRIVER_DIR!\chromedriver.exe.bak" (
        move /Y "!CHROMEDRIVER_DIR!\chromedriver.exe.bak" "!CHROMEDRIVER_EXE!" >nul 2>&1
    )
    rd /s /q "chromedriver\temp_extract" >nul 2>&1
    exit /b 1
)

REM Ensure target directory exists
if not exist "!CHROMEDRIVER_DIR!" (
    mkdir "!CHROMEDRIVER_DIR!"
)

REM Copy extracted files to the target directory
copy /Y "chromedriver\temp_extract\chromedriver-win64\chromedriver.exe" "!CHROMEDRIVER_DIR!\" >nul 2>&1
copy /Y "chromedriver\temp_extract\chromedriver-win64\LICENSE.chromedriver" "!CHROMEDRIVER_DIR!\" >nul 2>&1
copy /Y "chromedriver\temp_extract\chromedriver-win64\THIRD_PARTY_NOTICES.chromedriver" "!CHROMEDRIVER_DIR!\" >nul 2>&1

REM Clean up temp extraction directory and backup
rd /s /q "chromedriver\temp_extract" >nul 2>&1
del /Q "!CHROMEDRIVER_DIR!\chromedriver.exe.bak" >nul 2>&1

echo   Extraction complete.

REM Verify the new version
set "NEW_DRIVER_VERSION="
for /f "tokens=2" %%V in ('"!CHROMEDRIVER_EXE!" --version 2^>nul') do (
    if "!NEW_DRIVER_VERSION!"=="" set "NEW_DRIVER_VERSION=%%V"
)

echo.
if "!NEW_DRIVER_VERSION!"=="" (
    echo ERROR: ChromeDriver was installed but version could not be verified.
    exit /b 1
)

echo   Installed ChromeDriver: !NEW_DRIVER_VERSION!
echo.
echo ============================================================
echo ChromeDriver Check: UPDATED
echo   Chrome:       !CHROME_VERSION!
echo   ChromeDriver: !NEW_DRIVER_VERSION!
echo ============================================================
echo.

exit /b 0
