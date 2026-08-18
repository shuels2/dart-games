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
    call :hold
    exit /b 1
)

if not exist "%WINSW_EXE%" (
    echo ERROR: Service does not appear to be installed.
    echo Run install_service.bat first.
    call :hold
    exit /b 1
)

echo.
echo [1/5] Choosing branch and pulling latest code...
pushd "%REPO_DIR%\.."

REM ---- Fetch every ref from origin so the branch menu is current ----
echo   Fetching remote refs...
git fetch --all --prune
if errorlevel 1 ( echo ERROR: git fetch failed. & popd & call :hold & exit /b 1 )

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
    call :hold
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
        call :hold
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
    call :hold
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
        call :hold
        exit /b 1
    )
)

REM ---- Pull. --ff-only refuses to merge divergent history, which
REM     surfaces a real problem instead of silently making a merge
REM     commit on the kiosk.
echo   Pulling !_TARGET_BRANCH!...
git pull --ff-only
if errorlevel 1 ( echo ERROR: git pull failed. & popd & call :hold & exit /b 1 )
popd

echo.
echo [2/5] Stopping service...
"%WINSW_EXE%" stop
REM Ignore errorlevel - service may not be running, that's OK

echo.
echo [3/5] Recompiling server...
pushd "%SERVER_DIR%"
call dart pub get
if errorlevel 1 ( echo ERROR: dart pub get failed. & popd & call :hold & exit /b 1 )
call dart compile exe bin\server.dart -o bin\server.exe
if errorlevel 1 ( echo ERROR: dart compile exe failed. & popd & call :hold & exit /b 1 )
popd

echo.
echo [4/5] Rebuilding Flutter web app...
pushd "%REPO_DIR%"

REM ---- Which build is currently deployed? Stamped into
REM      build\web\build_number.txt by this script at the end of the
REM      previous successful run. Absent on the first run after this
REM      feature landed, hence the 'unknown' default.
set "PREV_BUILD=unknown"
if exist "build\web\build_number.txt" set /p PREV_BUILD=<build\web\build_number.txt

REM ---- Compute BUILD_NUMBER exactly the way build.bat does
REM      (git rev-list --count HEAD, from inside the repo). This is the
REM      value baked into the bundle via --dart-define and rendered as
REM      "Build N" at the bottom of the Options -> System Settings
REM      sidebar, so it is what the operator verifies against.
set "BUILD_NUMBER="
for /f %%i in ('git rev-list --count HEAD') do set "BUILD_NUMBER=%%i"
if "%BUILD_NUMBER%"=="" set "BUILD_NUMBER=dev"

set "COMMIT_SHORT="
for /f %%i in ('git rev-parse --short HEAD') do set "COMMIT_SHORT=%%i"

echo   Currently deployed: Build %PREV_BUILD%
echo   Building:           Build %BUILD_NUMBER%  ^(commit %COMMIT_SHORT%^)
echo.

if exist "build.bat" (
    call build.bat build web
) else (
    call flutter build web --pwa-strategy=none
)
if errorlevel 1 ( echo ERROR: flutter build web failed. & popd & call :hold & exit /b 1 )

REM ---- Stamp what we just deployed so the next run can report
REM      old -^> new. Lives under build\ which is gitignored.
> "build\web\build_number.txt" echo %BUILD_NUMBER%
popd

echo.
echo [5/5] Starting service...
"%WINSW_EXE%" start
if errorlevel 1 (
    echo ERROR: Failed to start service after update.
    echo Check logs in logs\service\
    call :hold
    exit /b 1
)

REM ---- Summary. Also written to last_update.txt so the details
REM      survive even if the console window is lost.
> "%REPO_DIR%\last_update.txt" (
    echo Dart Games - last service update
    echo.
    echo Branch:   !_TARGET_BRANCH!
    echo Commit:   %COMMIT_SHORT%
    echo Build:    %BUILD_NUMBER%   ^(previous: %PREV_BUILD%^)
    echo.
    echo Verify in the app: Options -^> System Settings, bottom of the
    echo left sidebar. It should read "Build %BUILD_NUMBER%".
)

echo.
echo ============================================================
echo  Update complete. Service is running with new code.
echo ============================================================
echo.
echo    Branch:   !_TARGET_BRANCH!
echo    Commit:   %COMMIT_SHORT%
echo    Build:    %BUILD_NUMBER%      ^(was: %PREV_BUILD%^)
echo.
echo  ------------------------------------------------------------
echo   HOW TO CONFIRM THE UPDATE WORKED
echo  ------------------------------------------------------------
echo    1. Open the app:  http://localhost/
echo    2. Go to  Options  -^>  System Settings
echo    3. Look at the BOTTOM of the left sidebar
echo    4. It must read:
echo.
echo             Build %BUILD_NUMBER%
echo.
REM ---- Only meaningful when the number actually moved. Re-running the
REM      updater with no new commits leaves them equal.
if not "%PREV_BUILD%"=="%BUILD_NUMBER%" (
    echo    Still showing "Build %PREV_BUILD%"? The browser is serving a
    echo    cached bundle - hard-refresh with Ctrl+F5.
    echo.
)
echo    This summary is also saved to:
echo      %REPO_DIR%\last_update.txt
echo ============================================================

endlocal
call :hold
exit /b 0

REM ============================================================
REM  :hold - keep the console window open until a key is pressed.
REM
REM  A bare `pause` is not enough here. `pause` reads stdin, and the
REM  child processes this script runs (`flutter build web`, `dart pub
REM  get`) leave the inherited stdin handle at EOF. `pause` then reads
REM  EOF, returns instantly, and the window vanishes before the
REM  operator can read the summary. Redirecting from CON reattaches
REM  the real console keyboard so it blocks as intended.
REM ============================================================
:hold
echo.
pause <CON
exit /b 0
