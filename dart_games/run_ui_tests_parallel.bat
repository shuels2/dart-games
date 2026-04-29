@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Dart Games UI Automation Test Runner (PARALLEL)
REM ============================================================
REM Runs game categories in parallel, one worker per game.
REM Each worker gets its own ChromeDriver and backend server.
REM Uses PID-scoped Chrome killing for parallel safety.
REM
REM Supports STUB_MODE env var for testing orchestration without
REM real infrastructure (set by run_ui_tests_parallel_stub.bat).
REM ============================================================

set "GAMES=target_tag carnival_derby monster_mash reef_royale clockwork_quest"

REM Strip trailing backslash from script directory to avoid \" quoting
REM issues when paths contain spaces (e.g. /D "path\" breaks start).
set "_SCRIPT_DIR=%~dp0"
if "!_SCRIPT_DIR:~-1!"=="\" set "_SCRIPT_DIR=!_SCRIPT_DIR:~0,-1!"

REM Check for help request
if "%1"=="/?" goto :show_help
if "%1"=="/help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help

REM ============================================================
REM Parse command line arguments
REM ============================================================
REM Same two-level filter logic as run_ui_tests.bat:
REM   Game level  - determines which workers to launch
REM   File level  - passed through to workers for per-file filtering
REM ============================================================
set "run_all=1"
set "token_count=0"
set "filter_args="

if not "%~1"=="" (
    set "run_all=0"
    for %%T in (%*) do (
        set /a token_count+=1
        set "_nt=%%T"
        set "_nt=!_nt:\=/!"
        set "_nt=!_nt:.dart=!"
        set "tok!token_count!=!_nt!"
        if "!filter_args!"=="" (
            set "filter_args=%%T"
        ) else (
            set "filter_args=!filter_args! %%T"
        )
    )
)

REM ============================================================
REM Pre-flight checks
REM ============================================================
echo ========================================
echo Dart Games UI Automation Test Runner
echo          [PARALLEL MODE]
if defined STUB_MODE echo          [STUB MODE]
echo ========================================
echo.

set "_PARALLEL_DIR=integration_test_output\parallel"
if not exist "integration_test_output" mkdir integration_test_output
if not exist "%_PARALLEL_DIR%" mkdir "%_PARALLEL_DIR%"

echo Cleaning previous parallel test results...
del /Q "%_PARALLEL_DIR%\*.txt" 2>nul
del /Q "%_PARALLEL_DIR%\*.log" 2>nul
for /d %%d in ("%_PARALLEL_DIR%\test_data_*") do rmdir /S /Q "%%d" >nul 2>&1

if defined STUB_MODE goto :skip_preflight

echo Verifying ChromeDriver version matches Chrome...
call update_chromedriver.bat
if !errorlevel! neq 0 (
    echo ERROR: ChromeDriver version check failed.
    pause
    exit /b 1
)

if not exist "server\bin\server.dart" (
    echo ERROR: Backend server not found at server\bin\server.dart
    pause
    exit /b 1
)

echo Resolving Flutter dependencies...
call flutter pub get
if !errorlevel! neq 0 (
    echo ERROR: Failed to resolve Flutter dependencies.
    pause
    exit /b 1
)

echo Resolving server dependencies...
pushd server
call dart pub get
if !errorlevel! neq 0 (
    echo ERROR: Failed to resolve server dependencies.
    popd
    pause
    exit /b 1
)
popd

echo Stopping any existing ChromeDriver, Chrome, and Backend Server instances...
taskkill /F /IM chromedriver.exe >nul 2>&1
taskkill /F /IM dart.exe >nul 2>&1
for /l %%P in (9001,1,9010) do call :kill_port %%P
for /l %%P in (4444,1,4453) do call :kill_port %%P
powershell -NoProfile -Command "Start-Sleep 2" >nul 2>&1

if not exist "chromedriver\chromedriver-win64\chromedriver.exe" (
    echo ERROR: ChromeDriver not found at chromedriver\chromedriver-win64\chromedriver.exe
    pause
    exit /b 1
)

:skip_preflight

REM ============================================================
REM Determine which games to run
REM ============================================================
set "worker_count=0"
set "game_list="

for %%G in (%GAMES%) do (
    REM A game matches when run_all=1, OR when at least one token either:
    REM   - is a substring of the game name, or
    REM   - contains the game name
    set "_game_matches=0"
    if "!run_all!"=="1" set "_game_matches=1"
    if "!_game_matches!"=="0" (
        for /l %%i in (1,1,!token_count!) do (
            if "!_game_matches!"=="0" (
                echo %%G | findstr /i /C:"!tok%%i!" >nul 2>&1
                if !errorlevel! equ 0 set "_game_matches=1"
            )
            if "!_game_matches!"=="0" (
                echo !tok%%i! | findstr /i /C:"%%G" >nul 2>&1
                if !errorlevel! equ 0 set "_game_matches=1"
            )
        )
    )

    if "!_game_matches!"=="1" (
        set /a worker_count+=1
        set "game!worker_count!=%%G"
        if "!game_list!"=="" (
            set "game_list=%%G"
        ) else (
            set "game_list=!game_list! %%G"
        )
    )
)

if !worker_count! equ 0 (
    echo ERROR: No games matched the specified filters.
    exit /b 1
)

echo.
if "!run_all!"=="1" (
    echo Running All UI Automation Tests [PARALLEL]
) else (
    echo Running Filtered UI Automation Tests [PARALLEL]:
    for /l %%i in (1,1,!token_count!) do echo   [%%i] !tok%%i!
)
echo.
echo Games: !game_list!
echo Workers: !worker_count!
echo Output: %_PARALLEL_DIR%
echo.
echo Port Assignments:
for /l %%N in (1,1,!worker_count!) do (
    set /a "_cd_port=4443+%%N"
    set /a "_srv_port=9000+%%N"
    echo   !game%%N!: ChromeDriver=!_cd_port! Server=!_srv_port!
)
echo.

set "_WORKTREE_BASE=integration_test_output\parallel\worktrees"

REM Detect subdirectory offset from git root to the Flutter project.
REM Worktrees mirror the full repo; flutter commands must run from
REM the project subdirectory inside each worktree (e.g. worktree\dart_games).
set "_GIT_PREFIX="
for /f "delims=" %%r in ('git rev-parse --show-prefix 2^>nul') do set "_GIT_PREFIX=%%r"
if not "!_GIT_PREFIX!"=="" (
    set "_GIT_PREFIX=!_GIT_PREFIX:/=\!"
    if "!_GIT_PREFIX:~-1!"=="\" set "_GIT_PREFIX=!_GIT_PREFIX:~0,-1!"
)

REM Skip helper functions
goto :start_infrastructure

REM ============================================================
REM HELPER FUNCTIONS
REM ============================================================

REM Kill process listening on port %1
:kill_port
for /f "tokens=5" %%a in ('netstat -aon ^| findstr "LISTENING" ^| findstr ":%~1 "') do taskkill /F /PID %%a >nul 2>&1
exit /b

REM Wait for ChromeDriver on port %1
:wait_for_chromedriver_port
set "_wfcp_port=%~1"
set "_wfcp_count=0"
:wait_for_chromedriver_port_loop
set /a _wfcp_count+=1
if !_wfcp_count! gtr 10 (
    echo   ERROR: ChromeDriver did not start on port !_wfcp_port! in time.
    exit /b 1
)
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:!_wfcp_port!/status' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>&1
if !errorlevel! equ 0 (
    echo   ChromeDriver ready on port !_wfcp_port!.
    exit /b 0
)
powershell -NoProfile -Command "Start-Sleep 1" >nul 2>&1
goto :wait_for_chromedriver_port_loop

REM Wait for backend server on port %1
:wait_for_server_port
set "_wfsp_port=%~1"
set "_wfsp_count=0"
:wait_for_server_port_loop
set /a _wfsp_count+=1
if !_wfsp_count! gtr 30 (
    echo   ERROR: Backend server did not start on port !_wfsp_port! in time.
    exit /b 1
)
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:!_wfsp_port!/api/v1/health/' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>&1
if !errorlevel! equ 0 (
    echo   Backend server ready on port !_wfsp_port!.
    exit /b 0
)
powershell -NoProfile -Command "Start-Sleep 1" >nul 2>&1
goto :wait_for_server_port_loop

REM Kill Chrome children of ChromeDriver on port %1
:kill_chrome_for_port
set "_kcfp_port=%~1"
powershell -NoProfile -Command "$cdPid=(Get-NetTCPConnection -LocalPort !_kcfp_port! -State Listen -ErrorAction SilentlyContinue).OwningProcess|Select-Object -First 1;if($cdPid){Get-CimInstance Win32_Process|Where-Object{$_.ParentProcessId -eq $cdPid -and $_.Name -eq 'chrome.exe'}|ForEach-Object{Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}}"
exit /b

REM ============================================================
REM START INFRASTRUCTURE
REM ============================================================
:start_infrastructure

if defined STUB_MODE goto :skip_infrastructure

REM ============================================================
REM Create worker worktrees (one per game for build isolation)
REM Each worktree gets its own build/ and .dart_tool/ so workers
REM never fight over the Flutter build cache or build/web/ output.
REM ============================================================
echo ========================================
echo Creating Worker Worktrees
echo ========================================
echo.

REM Remove any leftover worktrees from a previous failed run
if exist "!_WORKTREE_BASE!" (
    echo Cleaning up previous worker worktrees...
    for %%G in (target_tag carnival_derby monster_mash reef_royale clockwork_quest) do (
        git worktree remove --force "!_WORKTREE_BASE!\%%G" >nul 2>&1
    )
    git worktree prune >nul 2>&1
    rmdir /S /Q "!_WORKTREE_BASE!" >nul 2>&1
)
if not exist "!_WORKTREE_BASE!" mkdir "!_WORKTREE_BASE!"

set "_wt_ok=1"
for /l %%N in (1,1,!worker_count!) do (
    if "!_wt_ok!"=="1" (
        set "_g=!game%%N!"
        set "_wt=!_WORKTREE_BASE!\!_g!"
        echo [%%N/!worker_count!] Creating worktree for !_g!...
        git worktree add "!_wt!" HEAD >nul 2>&1
        if !errorlevel! neq 0 (
            echo ERROR: Failed to create worktree for !_g!. Aborting.
            set "_wt_ok=0"
        )
        if "!_wt_ok!"=="1" (
            set "_wt_proj=!_wt!"
            if not "!_GIT_PREFIX!"=="" set "_wt_proj=!_wt!\!_GIT_PREFIX!"
            pushd "!_wt_proj!"
            echo   Resolving dependencies...
            call flutter pub get >nul 2>&1
            echo   Pre-building Flutter web app ^(warms compiler cache^)...
            call flutter build web >nul 2>&1
            popd
            set "worktree%%N=!_wt_proj!"
            echo   Ready.
        )
    )
)
if "!_wt_ok!"=="0" goto :cleanup
echo.
echo All worktrees ready.
echo.

REM ============================================================
echo ========================================
echo Starting Infrastructure
echo ========================================
echo.

REM Start ChromeDrivers and backend servers for each game
for /l %%N in (1,1,!worker_count!) do (
    set "_g=!game%%N!"
    set /a "_cd_port=4443+%%N"
    set /a "_srv_port=9000+%%N"
    set "_data_dir=%_PARALLEL_DIR%\test_data_!_g!"
    set "_server_log=%_PARALLEL_DIR%\server_!_g!.log"

    echo Starting ChromeDriver on port !_cd_port! for !_g!...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=!_cd_port! >nul 2>&1

    echo Starting backend server on port !_srv_port! for !_g!...
    if not exist "!_data_dir!" mkdir "!_data_dir!"
    start /B "" cmd /C "cd server && dart run bin/server.dart --port !_srv_port! --data-dir ..\!_data_dir! >> ..\!_server_log! 2>&1"
)

echo.
echo Health-checking all services...

REM Wait for all ChromeDrivers
for /l %%N in (1,1,!worker_count!) do (
    set /a "_cd_port=4443+%%N"
    call :wait_for_chromedriver_port !_cd_port!
    if !errorlevel! neq 0 (
        echo ERROR: ChromeDriver failed to start on port !_cd_port!. Aborting.
        goto :cleanup
    )
)

REM Wait for all backend servers
for /l %%N in (1,1,!worker_count!) do (
    set /a "_srv_port=9000+%%N"
    call :wait_for_server_port !_srv_port!
    if !errorlevel! neq 0 (
        echo ERROR: Backend server failed to start on port !_srv_port!. Aborting.
        goto :cleanup
    )
)

echo.
echo All infrastructure ready.
echo.
goto :skip_infrastructure_end

:skip_infrastructure
echo [STUB] Skipping infrastructure startup.
echo.

:skip_infrastructure_end

REM ============================================================
REM Launch workers
REM ============================================================
echo ========================================
echo Launching Workers
echo ========================================
echo.

for /l %%N in (1,1,!worker_count!) do (
    set "_g=!game%%N!"
    set /a "_cd_port=4443+%%N"
    set /a "_srv_port=9000+%%N"
    set "_wt=!worktree%%N!"
    if "!_wt!"=="" set "_wt=stub"

    echo Launching worker for !_g! ^(CD=!_cd_port! SRV=!_srv_port!^)...
    start "Worker: !_g!" /D "!_SCRIPT_DIR!" cmd /C ""!_SCRIPT_DIR!\run_ui_tests_parallel_worker.bat" !_g! !_cd_port! !_srv_port! %_PARALLEL_DIR% !_wt! !filter_args!"
)

echo.
echo All !worker_count! workers launched. Waiting for completion...
echo.

REM ============================================================
REM Wait for workers (poll for result files)
REM ============================================================
set "_poll_count=0"

:poll_workers
set "_all_done=1"
set "_done_count=0"
for /l %%N in (1,1,!worker_count!) do (
    set "_g=!game%%N!"
    if exist "%_PARALLEL_DIR%\!_g!_results.txt" (
        set /a _done_count+=1
    ) else (
        set "_all_done=0"
    )
)

if "!_all_done!"=="1" goto :workers_done

REM 6-hour timeout: 2160 polls * 10 seconds = 21600 seconds
set /a _poll_count+=1
if !_poll_count! gtr 2160 (
    echo.
    echo ERROR: 6-hour global timeout reached.
    echo Workers completed: !_done_count!/!worker_count!
    for /l %%N in (1,1,!worker_count!) do (
        set "_g=!game%%N!"
        if not exist "%_PARALLEL_DIR%\!_g!_results.txt" (
            echo   TIMED OUT: !_g!
        )
    )
    goto :workers_done
)

REM Progress update every 6 polls (60 seconds)
set /a "_poll_mod=_poll_count %% 6"
if !_poll_mod! equ 0 (
    set /a "_elapsed_min=_poll_count * 10 / 60"
    echo   [!_elapsed_min!m] Workers completed: !_done_count!/!worker_count!
)

powershell -NoProfile -Command "Start-Sleep 10" >nul 2>&1
goto :poll_workers

:workers_done
echo.
echo All workers completed.
echo.

REM ============================================================
REM Aggregate results
REM ============================================================
echo ========================================
echo Parallel Test Results
echo ========================================
echo.

set "_total_total=0"
set "_total_passed=0"
set "_total_failed=0"
set "_total_retried=0"
set "_any_failure=0"

REM Initialize summary file
echo ======================================== > "%_PARALLEL_DIR%\summary.txt"
echo Dart Games UI Automation Test Results [PARALLEL] >> "%_PARALLEL_DIR%\summary.txt"
if defined STUB_MODE echo [STUB MODE] >> "%_PARALLEL_DIR%\summary.txt"
echo ======================================== >> "%_PARALLEL_DIR%\summary.txt"
echo Completed at %date% %time% >> "%_PARALLEL_DIR%\summary.txt"
echo. >> "%_PARALLEL_DIR%\summary.txt"

for /l %%N in (1,1,!worker_count!) do (
    set "_g=!game%%N!"
    set "_r_file=%_PARALLEL_DIR%\!_g!_results.txt"
    set "_g_total=0"
    set "_g_passed=0"
    set "_g_failed=0"
    set "_g_retried=0"
    set "_g_duration=0"
    set "_g_failed_tests="

    if exist "!_r_file!" (
        for /f "usebackq tokens=1,2 delims==" %%A in ("!_r_file!") do (
            if "%%A"=="TOTAL" set "_g_total=%%B"
            if "%%A"=="PASSED" set "_g_passed=%%B"
            if "%%A"=="FAILED" set "_g_failed=%%B"
            if "%%A"=="RETRIED" set "_g_retried=%%B"
            if "%%A"=="DURATION" set "_g_duration=%%B"
            if "%%A"=="FAILED_TESTS" set "_g_failed_tests=%%B"
        )

        set /a "_g_dur_min=_g_duration / 60"
        echo   !_g!: !_g_total! tests, !_g_passed! passed, !_g_failed! failed ^(!_g_dur_min!m^)
        if !_g_retried! gtr 0 echo     Retried: !_g_retried!
        if not "!_g_failed_tests!"=="" echo     Failed: !_g_failed_tests!

        echo ---------------------------------------- >> "%_PARALLEL_DIR%\summary.txt"
        echo Game: !_g! >> "%_PARALLEL_DIR%\summary.txt"
        echo Total: !_g_total!  Passed: !_g_passed!  Failed: !_g_failed!  Duration: !_g_duration!s >> "%_PARALLEL_DIR%\summary.txt"
        if !_g_retried! gtr 0 echo Retried: !_g_retried! >> "%_PARALLEL_DIR%\summary.txt"
        if not "!_g_failed_tests!"=="" echo Failed Tests: !_g_failed_tests! >> "%_PARALLEL_DIR%\summary.txt"
        echo. >> "%_PARALLEL_DIR%\summary.txt"

        set /a _total_total+=_g_total
        set /a _total_passed+=_g_passed
        set /a _total_failed+=_g_failed
        set /a _total_retried+=_g_retried
        if !_g_failed! gtr 0 set "_any_failure=1"
    ) else (
        echo   !_g!: NO RESULTS - worker timed out or crashed
        echo ---------------------------------------- >> "%_PARALLEL_DIR%\summary.txt"
        echo Game: !_g! - NO RESULTS >> "%_PARALLEL_DIR%\summary.txt"
        echo. >> "%_PARALLEL_DIR%\summary.txt"
        set "_any_failure=1"
    )
)

echo.
echo ========================================
echo Total: !_total_total! tests
echo Passed: !_total_passed!
if !_total_retried! gtr 0 echo Passed ^(on retry^): !_total_retried!
echo Failed: !_total_failed!
echo ========================================

echo ======================================== >> "%_PARALLEL_DIR%\summary.txt"
echo Overall Summary >> "%_PARALLEL_DIR%\summary.txt"
echo ======================================== >> "%_PARALLEL_DIR%\summary.txt"
echo Total: !_total_total! >> "%_PARALLEL_DIR%\summary.txt"
echo Passed: !_total_passed! >> "%_PARALLEL_DIR%\summary.txt"
if !_total_retried! gtr 0 echo Retried: !_total_retried! >> "%_PARALLEL_DIR%\summary.txt"
echo Failed: !_total_failed! >> "%_PARALLEL_DIR%\summary.txt"
echo. >> "%_PARALLEL_DIR%\summary.txt"

echo.
echo Results saved to %_PARALLEL_DIR%\
echo Summary: %_PARALLEL_DIR%\summary.txt
echo.

REM ============================================================
REM Cleanup
REM ============================================================
:cleanup
echo Stopping all parallel infrastructure...

if defined STUB_MODE goto :skip_cleanup

REM Kill Chrome children of each ChromeDriver (PID-scoped)
for /l %%N in (1,1,!worker_count!) do (
    set /a "_cd_port=4443+%%N"
    call :kill_chrome_for_port !_cd_port!
)

REM Kill all ChromeDrivers and servers by port
for /l %%N in (1,1,!worker_count!) do (
    set /a "_cd_port=4443+%%N"
    set /a "_srv_port=9000+%%N"
    call :kill_port !_cd_port!
    call :kill_port !_srv_port!
)
taskkill /F /IM chromedriver.exe >nul 2>&1

:skip_cleanup

echo Removing worker worktrees...
for /l %%N in (1,1,!worker_count!) do (
    set "_g=!game%%N!"
    git worktree remove --force "!_WORKTREE_BASE!\!_g!" >nul 2>&1
)
git worktree prune >nul 2>&1
if exist "!_WORKTREE_BASE!" rmdir /S /Q "!_WORKTREE_BASE!" >nul 2>&1

echo Infrastructure stopped.
echo.

if "!_any_failure!"=="1" (
    echo WARNING: Some tests failed or workers did not complete. Check logs for details.
    exit /b 1
) else if !_total_total! equ 0 (
    echo WARNING: No tests were executed.
    exit /b 1
) else (
    echo SUCCESS: All !_total_passed! test files passed!
    exit /b 0
)

REM ============================================================
REM Help Section
REM ============================================================
:show_help
echo.
echo ========================================
echo Dart Games UI Automation Test Runner
echo          [PARALLEL MODE]
echo ========================================
echo.
echo USAGE:
echo   run_ui_tests_parallel.bat [filter1] [filter2] ...
echo   run_ui_tests_parallel.bat /?
echo.
echo DESCRIPTION:
echo   Runs UI automation tests for all game categories in parallel,
echo   reducing wall-clock time from ~588 minutes to ~170 minutes.
echo   Each game gets its own ChromeDriver, backend server, and git
echo   worktree so Flutter builds are fully isolated (no shared
echo   build cache or build/web/ output directory conflicts).
echo.
echo PORT ASSIGNMENTS (auto-assigned by position in GAMES list):
set "_help_n=0"
for %%G in (!GAMES!) do (
    set /a "_help_n+=1"
    set /a "_help_cd=4443+_help_n"
    set /a "_help_srv=9000+_help_n"
    echo   %%G: ChromeDriver=!_help_cd! Server=!_help_srv!
)
echo.
echo FILTERING:
echo   Same filter syntax as run_ui_tests.bat.
echo   Without arguments, runs ALL test files across all games.
echo   Filters apply at two levels:
echo     1. Game level  - determines which workers to launch
echo     2. File level  - within each worker, which test files to run
echo.
echo EXAMPLES:
echo   Run all tests in parallel:
echo     run_ui_tests_parallel.bat
echo.
echo   Run only Target Tag tests:
echo     run_ui_tests_parallel.bat target_tag
echo.
echo   Run two games in parallel:
echo     run_ui_tests_parallel.bat target_tag monster_mash
echo.
echo   Run only save/resume tests across all games:
echo     run_ui_tests_parallel.bat save_resume
echo.
echo   Run a specific game's gameplay tests:
echo     run_ui_tests_parallel.bat reef_royale/gameplay
echo.
echo   Run a specific test file:
echo     run_ui_tests_parallel.bat save_modal_back_0_darts
echo.
echo NOTES:
echo   - Requires 16GB+ RAM recommended for all games
echo   - Results saved to integration_test_output\parallel\
echo   - PID-scoped Chrome killing prevents cross-worker interference
echo   - Per-session DB isolation (X-DB-Session) prevents data pollution
echo   - 6-hour global timeout for all workers
echo   - Use run_ui_tests.bat for sequential debugging of single tests
echo.
exit /b 0
