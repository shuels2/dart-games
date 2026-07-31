@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Dart Games - Update Running Service
REM ============================================================
REM Prompts you to pick a branch from origin, checks it out,
REM pulls, recompiles the server, rebuilds the Flutter web app,
REM and restarts the DartGamesServer service.
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
echo [1/5] Choosing branch and pulling latest code...
pushd "%REPO_DIR%\.."

REM ---- Fetch every ref from origin so the branch menu is current ----
echo   Fetching remote refs...
git fetch --all --prune
if errorlevel 1 ( echo ERROR: git fetch failed. & popd & pause & exit /b 1 )

REM ---- Record the currently-checked-out branch to use as default ----
set "CURRENT_BRANCH="
for /f "usebackq tokens=*" %%B in (`git branch --show-current 2^>nul`) do set "CURRENT_BRANCH=%%B"

REM ---- Build a numbered list of branches available on origin ----
REM     Skips the 'origin/HEAD' symbolic ref; each remaining branch
REM     is offered as an option. The current branch (if it matches
REM     an origin/ ref) is flagged and becomes the default when the
REM     operator just hits Enter.
set /a _BRANCH_COUNT=0
set "_DEFAULT_CHOICE="
echo.
echo Available branches on origin:
REM     Do NOT caret-escape the parens in --format. Inside a `for /f`
REM     backtick set the carets are NOT consumed, so git receives a
REM     literal "%^(refname:short^)" and echoes the placeholder back
REM     verbatim instead of expanding it. Plain double quotes are
REM     enough to protect the parens from the `in (...)` parser.
REM     `strip=3` drops "refs/remotes/origin/", leaving the bare
REM     branch name, so no substring surgery is needed afterwards.
for /f "usebackq tokens=*" %%B in (`git for-each-ref --format="%%(refname:strip=3)" "refs/remotes/origin/*"`) do (
    set "_LOCAL=%%B"
    REM origin/HEAD is a symbolic ref pointing at the default branch,
    REM not a checkout-able branch of its own - skip it. (With
    REM refname:short it would have shortened to plain "origin" and
    REM slipped past this filter.)
    if /i not "!_LOCAL!"=="HEAD" (
        set /a _BRANCH_COUNT+=1
        set "_BRANCH_!_BRANCH_COUNT!=!_LOCAL!"
        if /i "!_LOCAL!"=="!CURRENT_BRANCH!" (
            echo   [!_BRANCH_COUNT!] !_LOCAL!  ^(current^)
            set "_DEFAULT_CHOICE=!_BRANCH_COUNT!"
        ) else (
            echo   [!_BRANCH_COUNT!] !_LOCAL!
        )
    )
)

if !_BRANCH_COUNT! equ 0 (
    echo ERROR: No branches found on origin. Is the remote configured?
    popd
    pause
    exit /b 1
)

echo.
if defined _DEFAULT_CHOICE (
    set "_CHOICE="
    set /p "_CHOICE=Choose a branch number [!_DEFAULT_CHOICE!]: "
    if "!_CHOICE!"=="" set "_CHOICE=!_DEFAULT_CHOICE!"
) else (
    set "_CHOICE="
    set /p "_CHOICE=Choose a branch number: "
    if "!_CHOICE!"=="" (
        echo ERROR: No branch chosen.
        popd
        pause
        exit /b 1
    )
)

REM ---- Look up the chosen number in _BRANCH_<N> ----
set "_TARGET_BRANCH=!_BRANCH_%_CHOICE%!"
if "!_TARGET_BRANCH!"=="" (
    REM Delayed-expansion form for the array index lookup.
    call set "_TARGET_BRANCH=%%_BRANCH_!_CHOICE!%%"
)
if "!_TARGET_BRANCH!"=="" (
    echo ERROR: Invalid choice '!_CHOICE!'.
    popd
    pause
    exit /b 1
)

echo   Selected: !_TARGET_BRANCH!

REM ---- Switch branches if needed ----
REM     `git checkout <branch>` creates a local tracking branch on
REM     first use when a matching remote-only ref exists (default git
REM     2.x behaviour). If the working tree has local edits that
REM     would conflict, this fails loudly and we bail — the operator
REM     needs to resolve manually rather than have us discard work.
if /i not "!_TARGET_BRANCH!"=="!CURRENT_BRANCH!" (
    echo   Switching from !CURRENT_BRANCH! to !_TARGET_BRANCH!...
    git checkout !_TARGET_BRANCH!
    if errorlevel 1 (
        echo ERROR: git checkout failed.
        echo Local changes may prevent switching. Resolve with:
        echo   git status
        popd
        pause
        exit /b 1
    )
)

REM ---- Pull. --ff-only refuses to merge divergent history, which
REM     surfaces a real problem instead of silently making a merge
REM     commit on the kiosk.
echo   Pulling !_TARGET_BRANCH!...
git pull --ff-only
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
