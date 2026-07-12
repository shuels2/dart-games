@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Dart Games - Install as Windows Service (via WinSW)
REM ============================================================
REM Compiles the backend, builds the Flutter web app, generates
REM a WinSW config, and installs/starts the DartGamesServer
REM Windows service.
REM
REM Prerequisites (one-time):
REM   1. Flutter SDK on PATH      (provides dart + flutter)
REM   2. WinSW exe placed here:   %~dp0dart-games-service.exe
REM      Download WinSW-x64.exe from
REM        https://github.com/winsw/winsw/releases
REM      Rename it to:  dart-games-service.exe
REM      Place in:      this dart_games\ folder
REM   3. Python deps verified once (run check_python_deps.bat).
REM
REM Run as Administrator (right-click - Run as administrator).
REM Re-run safe: stops + reinstalls the service.
REM
REM To remove: run uninstall_service.bat
REM To update after pulling new code: run update_service.bat
REM ============================================================

set SERVICE_ID=DartGamesServer
set SERVICE_PORT=80
REM SERVICE_USER is prompted in Step 3 (defaults to the current %USERNAME%).
set REPO_DIR=%~dp0
if "%REPO_DIR:~-1%"=="\" set REPO_DIR=%REPO_DIR:~0,-1%
set SERVER_DIR=%REPO_DIR%\server
set SERVER_EXE=%SERVER_DIR%\bin\server.exe
set WEB_ROOT=%REPO_DIR%\build\web
set DATA_DIR=%SERVER_DIR%\data
set LOG_DIR=%REPO_DIR%\logs\service
set WINSW_EXE=%REPO_DIR%\dart-games-service.exe
set WINSW_XML=%REPO_DIR%\dart-games-service.xml

echo.
echo ============================================================
echo  Dart Games Service Installer (WinSW)
echo ============================================================
echo  Service ID:  %SERVICE_ID%
echo  Port:        %SERVICE_PORT%
echo  Account:     prompted below
echo  Repo:        %REPO_DIR%
echo  Server exe:  %SERVER_EXE%
echo  Web root:    %WEB_ROOT%
echo  Data dir:    %DATA_DIR%
echo  Logs:        %LOG_DIR%
echo  WinSW exe:   %WINSW_EXE%
echo ============================================================
echo.

REM ============================================================
REM Step 0: Prerequisite checks
REM ============================================================

REM Must be elevated (creating a service requires admin)
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This script must be run as Administrator.
    echo Right-click install_service.bat and choose "Run as administrator".
    pause
    exit /b 1
)

if not exist "%WINSW_EXE%" (
    echo ERROR: WinSW exe not found.
    echo   Expected: %WINSW_EXE%
    echo.
    echo Download WinSW-x64.exe from:
    echo   https://github.com/winsw/winsw/releases
    echo Rename it to dart-games-service.exe and place it in:
    echo   %REPO_DIR%
    pause
    exit /b 1
)

where dart >nul 2>&1
if errorlevel 1 (
    echo ERROR: dart not found on PATH. Install Flutter SDK first.
    pause
    exit /b 1
)

where flutter >nul 2>&1
if errorlevel 1 (
    echo ERROR: flutter not found on PATH. Install Flutter SDK first.
    pause
    exit /b 1
)

REM ============================================================
REM Step 1: Compile server to native exe (skip if exists)
REM ============================================================
echo.
echo [1/4] Compiling server to native exe...
if exist "%SERVER_EXE%" (
    echo   server.exe already exists - skipping compile.
    echo   ^(delete "%SERVER_EXE%" to force a rebuild^)
) else (
    pushd "%SERVER_DIR%"
    if not exist ".dart_tool\package_config.json" (
        echo   Running dart pub get...
        call dart pub get
        if errorlevel 1 (
            echo ERROR: dart pub get failed.
            popd
            pause
            exit /b 1
        )
    )
    call dart compile exe bin\server.dart -o bin\server.exe
    if errorlevel 1 (
        echo ERROR: dart compile exe failed.
        popd
        pause
        exit /b 1
    )
    popd
    echo   OK - %SERVER_EXE%
)
echo   [step 1 complete]

REM ============================================================
REM Step 2: Build Flutter web app (skip if exists)
REM ============================================================
echo.
echo [2/4] Building Flutter web app...
if exist "%WEB_ROOT%\index.html" (
    echo   build\web\index.html already exists - skipping build.
    echo   ^(delete "%WEB_ROOT%" to force a rebuild^)
) else (
    pushd "%REPO_DIR%"
    if exist "build.bat" (
        call build.bat build web
    ) else (
        call flutter build web --pwa-strategy=none
    )
    if errorlevel 1 (
        echo ERROR: flutter build web failed.
        popd
        pause
        exit /b 1
    )
    popd
    if not exist "%WEB_ROOT%\index.html" (
        echo ERROR: %WEB_ROOT%\index.html not found after build.
        pause
        exit /b 1
    )
    echo   OK - %WEB_ROOT%
)
echo   [step 2 complete]

REM ============================================================
REM Step 3: Prompt for Windows account + password
REM ============================================================
echo.
echo [3/4] Service account credentials
echo The service needs a Windows account to run as. This account must
echo be able to run "pip install --user" mediapipe etc. (see
echo check_python_deps.bat) so the face-landmark sidecar works.
echo.
echo Format the username as DOMAIN\USERNAME.
echo   - Local account:  .\USERNAME           (the "." means "this machine")
echo   - Domain account: MYDOMAIN\USERNAME
echo   - Microsoft account: AzureAD\USERNAME  (or your tenant prefix)
echo.
echo Defaults to the currently logged-in user: .\%USERNAME%
echo Press Enter to accept, or type a different account.
echo.
set "SERVICE_USER="
set /p "SERVICE_USER=Service account [.\%USERNAME%]: "
if "!SERVICE_USER!"=="" set "SERVICE_USER=.\%USERNAME%"

REM Split DOMAIN\USERNAME into SERVICE_DOMAIN + SERVICE_ACCOUNT.
REM If the user typed a bare name with no backslash, treat it as local (".").
set "SERVICE_DOMAIN="
set "SERVICE_ACCOUNT="
for /f "tokens=1,* delims=\" %%a in ("!SERVICE_USER!") do (
    set "SERVICE_DOMAIN=%%a"
    set "SERVICE_ACCOUNT=%%b"
)
if "!SERVICE_ACCOUNT!"=="" (
    set "SERVICE_DOMAIN=."
    set "SERVICE_ACCOUNT=!SERVICE_USER!"
)
echo   Using domain:   !SERVICE_DOMAIN!
echo   Using username: !SERVICE_ACCOUNT!
echo.
echo The password will be written into %WINSW_XML%.
echo (that file is ACL-restricted to Administrators only)
echo.
echo NOTE: the password will be echoed as you type. That's a deliberate
echo trade-off for reliability - the silent prompt was breaking the script.
echo.
set "SERVICE_PASS="
set /p "SERVICE_PASS=Windows password for !SERVICE_DOMAIN!\!SERVICE_ACCOUNT!: "
if "!SERVICE_PASS!"=="" (
    echo ERROR: No password entered.
    pause
    exit /b 1
)
echo   [step 3 complete]

REM Ensure log + data dirs exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

REM ============================================================
REM Step 4: Write WinSW xml config, install + start service
REM ============================================================
echo.
echo [4/4] Writing WinSW config and installing service...

REM Stop + uninstall any prior service (re-run safe)
sc query %SERVICE_ID% >nul 2>&1
if not errorlevel 1 (
    echo   Stopping existing service...
    "%WINSW_EXE%" stop >nul 2>&1
    echo   Uninstalling existing service...
    "%WINSW_EXE%" uninstall >nul 2>&1
)

REM XML-escape any password chars that would break XML (&, <, >).
REM Most Windows passwords don't include these but be safe.
set "ESC_PASS=!SERVICE_PASS!"
set "ESC_PASS=!ESC_PASS:&=&amp;!"
set "ESC_PASS=!ESC_PASS:<=&lt;!"
set "ESC_PASS=!ESC_PASS:>=&gt;!"

REM ------------------------------------------------------------
REM Resolve an absolute Python interpreter path so the service
REM finds it even when the sidecar-time PATH is missing the user
REM PATH entries where python was installed. Written into the
REM WinSW XML as DART_GAMES_PYTHON. The Dart FaceLandmarksService
REM checks this env var first before probing py/python/python3.
REM ------------------------------------------------------------
set "PY_ABS_PATH="
where py >nul 2>&1
if !errorlevel! equ 0 (
    for /f "usebackq tokens=*" %%P in (`py -c "import sys; print(sys.executable)" 2^>nul`) do (
        set "PY_ABS_PATH=%%P"
    )
)
if "!PY_ABS_PATH!"=="" (
    where python >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "usebackq tokens=*" %%P in (`python -c "import sys; print(sys.executable)" 2^>nul`) do (
            set "PY_ABS_PATH=%%P"
        )
    )
)
if "!PY_ABS_PATH!"=="" (
    where python3 >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "usebackq tokens=*" %%P in (`python3 -c "import sys; print(sys.executable)" 2^>nul`) do (
            set "PY_ABS_PATH=%%P"
        )
    )
)

REM Reject Windows Store shim paths - services can't reach WindowsApps.
if not "!PY_ABS_PATH!"=="" (
    echo !PY_ABS_PATH! | findstr /i "WindowsApps" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   Skipping Store-shim Python at !PY_ABS_PATH!
        set "PY_ABS_PATH="
    )
)

REM ------------------------------------------------------------
REM Also detect the interpreter's user-site-packages dir so we
REM can pin PYTHONPATH into the service env. Windows services
REM don't load the user profile by default, so %APPDATA% in the
REM service token isn't the interactive user's roaming dir -
REM which means site.getusersitepackages() resolves to an empty
REM path even when 'pip install --user' put mediapipe/cv2 in
REM the operator's real user-site. Pinning PYTHONPATH bypasses
REM that entirely.
REM ------------------------------------------------------------
set "PY_USER_SITE="
if not "!PY_ABS_PATH!"=="" (
    for /f "usebackq tokens=*" %%S in (`"!PY_ABS_PATH!" -c "import site; print(site.getusersitepackages())" 2^>nul`) do (
        set "PY_USER_SITE=%%S"
    )
    if not "!PY_USER_SITE!"=="" (
        if not exist "!PY_USER_SITE!\cv2" if not exist "!PY_USER_SITE!\mediapipe" (
            echo   User-site !PY_USER_SITE! has no cv2/mediapipe - skipping PYTHONPATH.
            set "PY_USER_SITE="
        )
    )
)

if "!PY_ABS_PATH!"=="" (
    echo   WARNING: Could not resolve a Python interpreter path.
    echo   The Treasure Divide face-landmarks feature will report
    echo   'python-not-found' until Python 3.9+ is installed and
    echo   this installer is re-run. Everything else will still work.
) else (
    echo   Sidecar Python: !PY_ABS_PATH!
    if not "!PY_USER_SITE!"=="" echo   Pinning PYTHONPATH: !PY_USER_SITE!
    echo   ^(if the service runs as a different account, that account
    echo    must also be able to execute this interpreter and read
    echo    the packages dir^)
)

REM Generate the WinSW config (overwrites)
> "%WINSW_XML%" (
  echo ^<?xml version="1.0" encoding="UTF-8"?^>
  echo ^<service^>
  echo   ^<id^>%SERVICE_ID%^</id^>
  echo   ^<name^>Dart Games Server^</name^>
  echo   ^<description^>Dart Games backend + Flutter web app on port %SERVICE_PORT%.^</description^>
  if not "!PY_ABS_PATH!"=="" echo   ^<env name="DART_GAMES_PYTHON" value="!PY_ABS_PATH!" /^>
  if not "!PY_USER_SITE!"=="" echo   ^<env name="PYTHONPATH" value="!PY_USER_SITE!" /^>
  echo   ^<executable^>%SERVER_EXE%^</executable^>
  echo   ^<arguments^>--port %SERVICE_PORT% --web-root "%WEB_ROOT%" --data-dir "%DATA_DIR%" --db-path "%DATA_DIR%\dart_games.db"^</arguments^>
  echo   ^<workingdirectory^>%SERVER_DIR%^</workingdirectory^>
  echo   ^<startmode^>Automatic^</startmode^>
  echo   ^<onfailure action="restart" delay="5 sec"/^>
  echo   ^<log mode="roll-by-size"^>
  echo     ^<sizeThreshold^>10240^</sizeThreshold^>
  echo     ^<keepFiles^>5^</keepFiles^>
  echo   ^</log^>
  echo   ^<logpath^>%LOG_DIR%^</logpath^>
  echo   ^<serviceaccount^>
  echo     ^<domain^>!SERVICE_DOMAIN!^</domain^>
  echo     ^<user^>!SERVICE_ACCOUNT!^</user^>
  echo     ^<password^>!ESC_PASS!^</password^>
  echo     ^<allowservicelogon^>true^</allowservicelogon^>
  echo   ^</serviceaccount^>
  echo ^</service^>
)

REM Don't keep the plaintext password in env vars longer than needed
set "SERVICE_PASS="
set "ESC_PASS="
set "SERVICE_USER="
set "SERVICE_DOMAIN="
set "SERVICE_ACCOUNT="

REM Lock down the XML to Administrators only (it contains the password)
icacls "%WINSW_XML%" /inheritance:r /grant:r "*S-1-5-32-544:F" "*S-1-5-18:F" >nul 2>&1
if errorlevel 1 (
    echo WARNING: Could not restrict ACL on %WINSW_XML%.
    echo The file contains your Windows password. Restrict it manually:
    echo   icacls "%WINSW_XML%" /inheritance:r /grant:r "Administrators:F" "SYSTEM:F"
)

echo   Installing service...
"%WINSW_EXE%" install
if errorlevel 1 ( echo ERROR: winsw install failed. & pause & exit /b 1 )

echo   Starting service...
"%WINSW_EXE%" start
if errorlevel 1 (
    echo ERROR: Service installed but failed to start.
    echo Check logs at %LOG_DIR%
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  SUCCESS
echo ============================================================
echo  Service '%SERVICE_ID%' is installed and running.
echo.
echo  This machine:        http://localhost:%SERVICE_PORT%/
echo  Other devices:       http://^<this-machine-ip^>:%SERVICE_PORT%/
echo.
echo  Manage:
echo    "%WINSW_EXE%" status
echo    "%WINSW_EXE%" restart
echo    "%WINSW_EXE%" stop
echo    services.msc           ^(GUI^)
echo.
echo  Logs:
echo    %LOG_DIR%\
echo.
echo  Update after git pull:  update_service.bat
echo  Remove service:         uninstall_service.bat
echo ============================================================

endlocal
pause
exit /b 0
