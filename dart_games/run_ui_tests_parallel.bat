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

REM Test categories. Variable is named GAMES for historical reasons but it
REM lists every top-level subdirectory under integration_test/ that holds
REM tests, including non-game categories (home_screen, pause_modal).
REM Adding entries here automatically:
REM   - assigns the next port (server = 9000+N, chromedriver = 4443+N)
REM   - reserves a worker slot (one parallel worker per entry)
REM   - includes the dir in pre-run worktree cleanup (loop below at ~line 283)
set "GAMES=target_tag carnival_derby monster_mash reef_royale clockwork_quest lunar_lander pirates_grid gladiator_arena tiki_golf home_screen pause_modal treasure_divide"

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
REM
REM MAX_WORKERS handling — batched dispatcher:
REM   Default 5, overridable via MAX_WORKERS env var, or via a
REM   `--max-workers=N` CLI flag (highest precedence). Args other than
REM   `--max-workers=` are treated as filter tokens like before, so
REM   the flag does NOT set run_all=0 by itself — a run of
REM   `run_ui_tests_parallel.bat --max-workers=3` still runs every
REM   game (in batches of 3), matching the "no args = run all" idiom.
REM ============================================================
if not defined MAX_WORKERS set "MAX_WORKERS=5"

set "run_all=1"
set "token_count=0"
set "filter_args="

if not "%~1"=="" (
    for %%T in (%*) do (
        set "_arg=%%T"
        REM Match `--max-workers=<N>` prefix (14 chars).
        if /i "!_arg:~0,14!"=="--max-workers=" (
            set "MAX_WORKERS=!_arg:~14!"
        ) else (
            set "run_all=0"
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
)

REM Validate MAX_WORKERS is a positive integer. Silently coerce
REM anything invalid back to the default rather than aborting the run.
set /a "_mw_test=MAX_WORKERS" 2>nul
if !_mw_test! lss 1 (
    echo WARNING: MAX_WORKERS=!MAX_WORKERS! invalid, using default 5.
    set "MAX_WORKERS=5"
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

call "%~dp0check_python_deps.bat"
if !errorlevel! neq 0 exit /b 1

set "_PARALLEL_DIR=integration_test_output\parallel"
if not exist "integration_test_output" mkdir integration_test_output
if not exist "%_PARALLEL_DIR%" mkdir "%_PARALLEL_DIR%"

echo Cleaning previous parallel test results...
del /Q "%_PARALLEL_DIR%\*.txt" 2>nul
del /Q "%_PARALLEL_DIR%\*.log" 2>nul
for /d %%d in ("%_PARALLEL_DIR%\test_data_*") do rmdir /S /Q "%%d" >nul 2>&1

REM ============================================================
REM Pre-flight: kill leftover test processes from a prior run.
REM
REM A previous run that was force-killed (Ctrl+C, OS reboot, parent
REM cmd window closed) leaves orphaned chromedriver.exe and
REM flutter_tester.exe processes plus dart.exe servers on the test
REM ports. They hold worktree files open, blocking rmdir cleanup, and
REM bind ports we need. Past failure: 8+ leftover chromedriver.exe
REM processes blocked the next run's worktree creation entirely.
REM
REM Safe-to-kill blanket:
REM   - chromedriver.exe (test-only, no other use on this machine)
REM   - flutter_tester.exe (left over by crashed flutter test runs)
REM
REM Port-scoped (DO NOT blanket-kill dart.exe — user may have an
REM IDE-launched dart server on a different port):
REM   - dart.exe instances bound to ports 9001-9020 (our test port range)
REM ============================================================
echo Killing leftover test processes from prior runs...
taskkill /F /IM chromedriver.exe >nul 2>&1
taskkill /F /IM flutter_tester.exe >nul 2>&1
for /l %%P in (9001,1,9020) do (
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr "LISTENING" ^| findstr ":%%P "') do taskkill /F /PID %%a >nul 2>&1
)
REM Brief settle so killed processes release file handles before rmdir.
timeout /t 1 /nobreak >nul

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

REM Wipe flutter_tools frontend-server kernel cache. flutter_tools keeps an
REM app.dill snapshot in %LOCALAPPDATA%\Temp\flutter_tools.<hash>\flutter_tool.<hash>\
REM that survives `flutter clean` and per-worktree .dart_tool resets. When a
REM method is added to a file already in the cached kernel, the next
REM `flutter drive` reuses the stale kernel and reports "Member not found".
REM Removing this directory before any worker runs forces every worker to
REM recompile against the current source. Must happen before worktree
REM creation so workers don't inherit a still-warm cache.
echo Wiping stale flutter_tools kernel cache ^(%%LOCALAPPDATA%%\Temp\flutter_tools.*^)...
for /d %%D in ("%LOCALAPPDATA%\Temp\flutter_tools.*") do rmdir /S /Q "%%D" >nul 2>&1

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

REM Clamp slot count — one worker slot per concurrent game, but never
REM more than there are games to run. Games rotate through the slots
REM as each finishes (see :dispatch_loop below).
set "slot_count=!MAX_WORKERS!"
if !slot_count! gtr !worker_count! set "slot_count=!worker_count!"

echo.
if "!run_all!"=="1" (
    echo Running All UI Automation Tests [PARALLEL]
) else (
    echo Running Filtered UI Automation Tests [PARALLEL]:
    for /l %%i in (1,1,!token_count!) do echo   [%%i] !tok%%i!
)
echo.
echo Games:    !game_list!
echo Games:    !worker_count! total
echo Slots:    !slot_count! concurrent ^(MAX_WORKERS=!MAX_WORKERS!^)
echo Output:   %_PARALLEL_DIR%
echo.
echo Slot Port Assignments ^(games rotate through these ports as slots free up^):
for /l %%N in (1,1,!slot_count!) do (
    set /a "_cd_port=4443+%%N"
    set /a "_web_port=_cd_port+36000"
    set /a "_srv_port=9000+%%N"
    echo   slot %%N: ChromeDriver=!_cd_port! Web=!_web_port! Server=!_srv_port!
)
echo.

REM Make worktree base ABSOLUTE so cwd shifts (pushd/popd, sub-process
REM working dirs) don't break path resolution. Past failure: relative
REM `_WORKTREE_BASE` worked for git worktree add (which was called from
REM the bat's cwd) but flutter sub-processes inherited a different cwd
REM and `flutter pub get` printed "The system cannot find the path
REM specified." for every worker.
set "_WORKTREE_BASE=!_SCRIPT_DIR!\integration_test_output\parallel\worktrees"

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

REM ============================================================
REM Worktree setup is FAIL-LOUD by design.
REM
REM Past failure: silent `git worktree add ... >nul 2>&1` masked errors so
REM half the workers ran in non-existent paths. Tests then fail with
REM "the system cannot find the path specified" and the runner has no
REM idea why. Every worktree-setup operation now writes to a setup log,
REM and a post-creation existence check aborts the run if any worktree
REM dir is missing.
REM ============================================================
REM Absolute log path — relative paths break after pushd into a worktree.
REM Past failure: relative _WT_LOG appended to `<wt>\dart_games\integration_test_output\parallel\worktree_setup.log`
REM after pushd, which doesn't exist, so every `>> "!_WT_LOG!" 2>&1` line
REM emitted "The system cannot find the path specified." — once for each
REM flutter pub get and flutter build web call inside the loop.
set "_WT_LOG=!_SCRIPT_DIR!\!_PARALLEL_DIR!\worktree_setup.log"
echo === Worktree setup log === > "!_WT_LOG!"

REM Prune stale .git/worktrees/<name> metadata FIRST. If a previous run was
REM force-killed mid-cleanup, git's metadata can point at directories that
REM no longer exist; subsequent `git worktree add` then fails with cryptic
REM errors. `git worktree prune` is safe to run unconditionally.
echo Pruning stale git worktree metadata...
git worktree prune >> "!_WT_LOG!" 2>&1

REM Remove any leftover worktrees from a previous failed run
if exist "!_WORKTREE_BASE!" (
    echo Cleaning up previous worker worktrees...
    REM Keep this list in sync with the GAMES variable at the top of the file.
    for %%G in (target_tag carnival_derby monster_mash reef_royale clockwork_quest lunar_lander pirates_grid gladiator_arena tiki_golf home_screen pause_modal treasure_divide) do (
        git worktree remove --force "!_WORKTREE_BASE!\%%G" >> "!_WT_LOG!" 2>&1
    )
    git worktree prune >> "!_WT_LOG!" 2>&1
    rmdir /S /Q "!_WORKTREE_BASE!" >> "!_WT_LOG!" 2>&1
)

REM If rmdir couldn't fully delete (some files locked by a prior run's
REM chromedriver/dart process that's still alive), surface that loudly
REM rather than press on. A leftover dir at !_WORKTREE_BASE!\<game>\ will
REM make `git worktree add` fail because the destination already exists.
if exist "!_WORKTREE_BASE!" (
    for /d %%G in ("!_WORKTREE_BASE!\*") do (
        echo ERROR: leftover worktree dir not removed: %%G >> "!_WT_LOG!"
        echo ERROR: leftover worktree dir not removed: %%G
        echo        Likely cause: a chromedriver/dart process from a prior
        echo        run has the dir locked. Kill all chromedriver.exe and
        echo        dart.exe processes, then re-run.
        set "_wt_ok=0"
    )
)
if not exist "!_WORKTREE_BASE!" mkdir "!_WORKTREE_BASE!"

if not defined _wt_ok set "_wt_ok=1"
for /l %%N in (1,1,!worker_count!) do (
    if "!_wt_ok!"=="1" (
        set "_g=!game%%N!"
        set "_wt=!_WORKTREE_BASE!\!_g!"
        echo [%%N/!worker_count!] Creating worktree for !_g!...
        echo --- worktree add: !_g! --- >> "!_WT_LOG!"
        git worktree add "!_wt!" HEAD >> "!_WT_LOG!" 2>&1
        if !errorlevel! neq 0 (
            echo ERROR: Failed to create worktree for !_g!. See !_WT_LOG! for details.
            type "!_WT_LOG!" | findstr /C:"--- worktree add: !_g! ---" /C:"fatal" /C:"error"
            set "_wt_ok=0"
        )
        if "!_wt_ok!"=="1" (
            set "_wt_proj=!_wt!"
            if not "!_GIT_PREFIX!"=="" set "_wt_proj=!_wt!\!_GIT_PREFIX!"
            REM Diagnostic — log exact path before pushd so failures are
            REM debuggable. If pushd reports "The system cannot find the
            REM path specified.", inspecting !_WT_LOG! reveals what path
            REM was actually attempted.
            echo --- pushd to: [!_wt_proj!] --- >> "!_WT_LOG!"
            if not exist "!_wt_proj!\pubspec.yaml" (
                echo ERROR: project root missing pubspec.yaml: !_wt_proj!
                echo        worktree was created but does not contain a
                echo        Flutter project at the expected path. Likely
                echo        cause: _GIT_PREFIX [!_GIT_PREFIX!] doesn't match
                echo        the actual project subdirectory layout.
                set "_wt_ok=0"
            ) else (
                pushd "!_wt_proj!" 2>> "!_WT_LOG!"
                if !errorlevel! neq 0 (
                    echo ERROR: pushd failed for !_g!: !_wt_proj!
                    echo        See !_WT_LOG! for details.
                    set "_wt_ok=0"
                ) else (
                    echo   Resolving dependencies...
                    call flutter pub get >> "!_WT_LOG!" 2>&1
                    echo   Pre-building Flutter web app ^(warms compiler cache^)...
                    call flutter build web >> "!_WT_LOG!" 2>&1
                    popd
                    set "worktree%%N=!_wt_proj!"
                    echo   Ready.
                )
            )
        )
    )
)
if "!_wt_ok!"=="0" goto :cleanup

REM Existence check — every expected worktree project dir must exist on
REM disk AND contain a `pubspec.yaml` (the canonical Flutter project
REM marker) before we launch workers. A worker pointed at a missing path
REM runs flutter drive in a non-existent cwd, which fails with "the
REM system cannot find the path specified" for every test in that game's
REM pack — and the runner has no idea why because git worktree errors
REM were swallowed.
echo.
echo Verifying all worktrees exist on disk...
set "_wt_missing=0"
for /l %%N in (1,1,!worker_count!) do (
    set "_g=!game%%N!"
    set "_wt_check=!worktree%%N!"
    if not exist "!_wt_check!\pubspec.yaml" (
        echo ERROR: worktree for !_g! missing or incomplete: !_wt_check!
        echo        Expected pubspec.yaml at !_wt_check!\pubspec.yaml.
        echo        Worker !_g! would run flutter drive in a non-existent
        echo        / non-Flutter directory and every test in its pack
        echo        would fail with "the system cannot find the path".
        set "_wt_missing=1"
    )
)
if "!_wt_missing!"=="1" (
    echo.
    echo One or more worktrees missing or incomplete — aborting before
    echo workers spawn. See !_WT_LOG! for the git worktree add output.
    set "_wt_ok=0"
    goto :cleanup
)

echo.
echo All worktrees ready.
echo.

REM ============================================================
echo ========================================
echo Starting Infrastructure
echo ========================================
echo.

REM Start slot_count ChromeDriver + backend server pairs — one per
REM SLOT (not per game). Games rotate through these fixed ports as
REM the dispatcher assigns them. Server data-dirs stay per-game and
REM are created lazily by the worker when it starts a new game;
REM shared server state is reset between games via the worker's
REM `UITestHelpers.resetServerState()` call at the start of each
REM test file.
for /l %%N in (1,1,!slot_count!) do (
    set /a "_cd_port=4443+%%N"
    set /a "_srv_port=9000+%%N"
    set "_data_dir=%_PARALLEL_DIR%\test_data_slot%%N"
    set "_server_log=%_PARALLEL_DIR%\server_slot%%N.log"

    echo Starting ChromeDriver on port !_cd_port! for slot %%N...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=!_cd_port! >nul 2>&1

    echo Starting backend server on port !_srv_port! for slot %%N...
    if not exist "!_data_dir!" mkdir "!_data_dir!"
    start /B "" cmd /C "cd server && dart run bin/server.dart --port !_srv_port! --data-dir ..\!_data_dir! >> ..\!_server_log! 2>&1"
)

echo.
echo Health-checking all services...

REM Wait for all ChromeDrivers (per slot)
for /l %%N in (1,1,!slot_count!) do (
    set /a "_cd_port=4443+%%N"
    call :wait_for_chromedriver_port !_cd_port!
    if !errorlevel! neq 0 (
        echo ERROR: ChromeDriver failed to start on port !_cd_port!. Aborting.
        goto :cleanup
    )
)

REM Wait for all backend servers (per slot)
for /l %%N in (1,1,!slot_count!) do (
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
REM Dispatch loop — batched worker scheduler
REM ============================================================
REM Rolling FIFO scheduler: the queue is game1..game<worker_count>,
REM the pool is slot1..slot<slot_count>. Each iteration:
REM   (a) reaps finished slots by looking for <game>_results.txt,
REM   (b) fills any free slot from the queue head (2s stagger between
REM       successive launches this tick, matching the SDK-cache race
REM       protection the old launch loop had),
REM   (c) exits when every slot is free AND the queue is drained.
REM
REM Slots own the fixed port pair (CD=4443+N, SRV=9000+N) established
REM during infrastructure startup — games rotate through those ports.
REM
REM Global timeout: 14 hours (5040 polls * 10s = 50,400s). Longer than
REM the old 6h to account for batched wall-clock being N/slot_count
REM times the single-fastest-game runtime instead of the max.
echo ========================================
echo Dispatch Loop ^(rolling batches^)
echo ========================================
echo.
echo Slot count: !slot_count!   Queue length: !worker_count!
echo.

REM Queue state: queue_head=1..worker_count is the next game to dequeue.
set "queue_head=1"
set /a "queue_tail=!worker_count!"

REM Slot state: slot_<N>_game is empty when the slot is free, or holds
REM the currently-running game name.
for /l %%N in (1,1,!slot_count!) do set "slot_%%N_game="

REM Capture the wall-clock start time (seconds since midnight)
for /f %%T in ('powershell -NoProfile -Command "$n=Get-Date; $n.Hour*3600+$n.Minute*60+$n.Second"') do set "_start_s=%%T"
set "_start_stamp=%date% %time%"

echo Started at !_start_stamp!
echo.

set "_poll_count=0"
set "_total_launches=0"

:dispatch_loop
REM ---- (a) Reap finished slots first so we can refill them below ----
for /l %%N in (1,1,!slot_count!) do (
    if not "!slot_%%N_game!"=="" (
        set "_reap_g=!slot_%%N_game!"
        if exist "%_PARALLEL_DIR%\!_reap_g!_results.txt" (
            echo   Slot %%N freed ^(!_reap_g! finished^).
            set "slot_%%N_game="
        )
    )
)

REM ---- (b) Fill any free slot from the queue head (FIFO) ----
set "_launched_this_tick=0"
for /l %%N in (1,1,!slot_count!) do (
    if "!slot_%%N_game!"=="" (
        if !queue_head! leq !queue_tail! (
            REM Indirect variable expansion — %%I becomes the literal
            REM value of queue_head, then !game<value>! resolves.
            for %%I in (!queue_head!) do set "_deq_g=!game%%I!"
            set "slot_%%N_game=!_deq_g!"
            set /a "_cd_port=4443+%%N"
            set /a "_srv_port=9000+%%N"
            REM Resolve the worktree path directly from the game name
            REM instead of by index. Path is deterministic:
            REM   <_WORKTREE_BASE>\<game>[\<_GIT_PREFIX>]
            REM In STUB_MODE the worktree base is skipped; workers are
            REM tolerant of "stub" as the placeholder path.
            if defined STUB_MODE (
                set "_wt=stub"
            ) else (
                set "_wt=!_WORKTREE_BASE!\!_deq_g!"
                if not "!_GIT_PREFIX!"=="" set "_wt=!_wt!\!_GIT_PREFIX!"
            )

            REM 2s stagger between successive launches this tick so the
            REM first worker's flutter bootstrap finishes writing the
            REM shared SDK cache (engine.realm) before the next worker
            REM boots — same protection the old launch loop had, moved
            REM inside the dispatcher.
            if !_launched_this_tick! gtr 0 (
                timeout /t 2 /nobreak >nul 2>&1
            )

            echo   Slot %%N launching: !_deq_g! ^(CD=!_cd_port! SRV=!_srv_port!^)
            start "Worker: !_deq_g!" /D "!_SCRIPT_DIR!" cmd /C ""!_SCRIPT_DIR!\run_ui_tests_parallel_worker.bat" !_deq_g! !_cd_port! !_srv_port! "%_PARALLEL_DIR%" "!_wt!" !filter_args!"

            set /a queue_head+=1
            set /a _launched_this_tick+=1
            set /a _total_launches+=1
        )
    )
)

REM ---- (c) Compute progress + exit condition ----
set "_active=0"
for /l %%N in (1,1,!slot_count!) do (
    if not "!slot_%%N_game!"=="" set /a _active+=1
)
set "_done_count=0"
for /l %%N in (1,1,!worker_count!) do (
    set "_g=!game%%N!"
    if exist "%_PARALLEL_DIR%\!_g!_results.txt" set /a _done_count+=1
)
set /a "_queued=queue_tail - queue_head + 1"
if !_queued! lss 0 set "_queued=0"

if !_active! equ 0 if !_queued! equ 0 goto :workers_done

REM 14-hour global timeout: 5040 polls * 10 seconds = 50,400 seconds
set /a _poll_count+=1
if !_poll_count! gtr 5040 (
    echo.
    echo ERROR: 14-hour global timeout reached.
    echo Games completed: !_done_count!/!worker_count!   Still running: !_active!   Still queued: !_queued!
    for /l %%N in (1,1,!worker_count!) do (
        set "_g=!game%%N!"
        if not exist "%_PARALLEL_DIR%\!_g!_results.txt" (
            echo   TIMED OUT or QUEUED: !_g!
        )
    )
    goto :workers_done
)

REM Progress update every 6 polls (60 seconds)
set /a "_poll_mod=_poll_count %% 6"
if !_poll_mod! equ 0 (
    set /a "_elapsed_min=_poll_count * 10 / 60"
    echo   [!_elapsed_min!m] Completed: !_done_count!/!worker_count!   Running: !_active!/!slot_count!   Queued: !_queued!
)

powershell -NoProfile -Command "Start-Sleep 10" >nul 2>&1
goto :dispatch_loop

:workers_done

REM Capture the wall-clock end time and compute elapsed duration
for /f %%T in ('powershell -NoProfile -Command "$n=Get-Date; $n.Hour*3600+$n.Minute*60+$n.Second"') do set "_end_s=%%T"
set "_end_stamp=%date% %time%"
set /a "_wall_s=_end_s - _start_s"
if !_wall_s! lss 0 set /a "_wall_s+=86400"
set /a "_wall_h=_wall_s / 3600"
set /a "_wall_m=(_wall_s %% 3600) / 60"
set /a "_wall_sec=_wall_s %% 60"

echo.
echo All workers completed.
echo.
echo ========================================
echo Wall-Clock Duration
echo ========================================
echo   Started:  !_start_stamp!
echo   Finished: !_end_stamp!
echo   Elapsed:  !_wall_h!h !_wall_m!m !_wall_sec!s
echo ========================================
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
set "_total_duration=0"
set "_any_failure=0"

REM Initialize summary file
echo ======================================== > "%_PARALLEL_DIR%\summary.txt"
echo Dart Games UI Automation Test Results [PARALLEL] >> "%_PARALLEL_DIR%\summary.txt"
if defined STUB_MODE echo [STUB MODE] >> "%_PARALLEL_DIR%\summary.txt"
echo ======================================== >> "%_PARALLEL_DIR%\summary.txt"
echo Started:   !_start_stamp! >> "%_PARALLEL_DIR%\summary.txt"
echo Finished:  !_end_stamp! >> "%_PARALLEL_DIR%\summary.txt"
echo Wall-Clock: !_wall_h!h !_wall_m!m !_wall_sec!s >> "%_PARALLEL_DIR%\summary.txt"
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
        set /a _total_duration+=_g_duration
        if !_g_failed! gtr 0 set "_any_failure=1"
    ) else (
        echo   !_g!: NO RESULTS - worker timed out or crashed
        echo ---------------------------------------- >> "%_PARALLEL_DIR%\summary.txt"
        echo Game: !_g! - NO RESULTS >> "%_PARALLEL_DIR%\summary.txt"
        echo. >> "%_PARALLEL_DIR%\summary.txt"
        set "_any_failure=1"
    )
)

set /a "_cum_h=_total_duration / 3600"
set /a "_cum_m=(_total_duration %% 3600) / 60"
set /a "_cum_sec=_total_duration %% 60"

echo.
echo ========================================
echo Total: !_total_total! tests
echo Passed: !_total_passed!
if !_total_retried! gtr 0 echo Passed ^(on retry^): !_total_retried!
echo Failed: !_total_failed!
echo ----------------------------------------
echo Wall-Clock Time:  !_wall_h!h !_wall_m!m !_wall_sec!s
echo Cumulative Time:  !_cum_h!h !_cum_m!m !_cum_sec!s
echo ========================================

echo ======================================== >> "%_PARALLEL_DIR%\summary.txt"
echo Overall Summary >> "%_PARALLEL_DIR%\summary.txt"
echo ======================================== >> "%_PARALLEL_DIR%\summary.txt"
echo Total: !_total_total! >> "%_PARALLEL_DIR%\summary.txt"
echo Passed: !_total_passed! >> "%_PARALLEL_DIR%\summary.txt"
if !_total_retried! gtr 0 echo Retried: !_total_retried! >> "%_PARALLEL_DIR%\summary.txt"
echo Failed: !_total_failed! >> "%_PARALLEL_DIR%\summary.txt"
echo. >> "%_PARALLEL_DIR%\summary.txt"
echo Wall-Clock Time:  !_wall_h!h !_wall_m!m !_wall_sec!s >> "%_PARALLEL_DIR%\summary.txt"
echo Cumulative Time:  !_cum_h!h !_cum_m!m !_cum_sec!s >> "%_PARALLEL_DIR%\summary.txt"
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

REM Kill Chrome children of each slot's ChromeDriver (PID-scoped).
REM Infrastructure teardown is now slot-scoped, not game-scoped —
REM ChromeDriver + backend server pairs are allocated per slot and
REM rotate games through them (see :dispatch_loop above).
for /l %%N in (1,1,!slot_count!) do (
    set /a "_cd_port=4443+%%N"
    call :kill_chrome_for_port !_cd_port!
)

REM Kill each slot's ChromeDriver + backend server by port.
for /l %%N in (1,1,!slot_count!) do (
    set /a "_cd_port=4443+%%N"
    set /a "_srv_port=9000+%%N"
    call :kill_port !_cd_port!
    call :kill_port !_srv_port!
)
taskkill /F /IM chromedriver.exe >nul 2>&1

:skip_cleanup

REM Worktrees remain per-game (one per queued game) so games never
REM share a checkout across the dispatcher's rotation.
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
echo   run_ui_tests_parallel.bat [--max-workers=N] [filter1] [filter2] ...
echo   run_ui_tests_parallel.bat /?
echo.
echo DESCRIPTION:
echo   Runs UI automation tests across game categories with a rolling
echo   batched dispatcher. Up to MAX_WORKERS games run at once; as each
echo   worker finishes, the next queued game rotates into its slot
echo   without waiting for the batch. Minimizes wall-clock while
echo   capping simultaneous resource use.
echo.
echo   Each game runs in its own git worktree (Flutter builds are
echo   fully isolated — no shared build cache or build/web/ output
echo   directory conflicts). ChromeDriver + backend server pairs are
echo   allocated PER SLOT, and games rotate through those fixed
echo   ports as slots free up.
echo.
echo CONCURRENCY CONTROL:
echo   --max-workers=N   Cap concurrent workers. Default 5. Highest
echo                     precedence — overrides MAX_WORKERS env var.
echo   MAX_WORKERS       Env var override for the default. Applies
echo                     when --max-workers=N is not passed.
echo.
echo SLOT PORT ASSIGNMENTS (fixed per slot, games rotate through):
set "_help_n=0"
for /l %%S in (1,1,10) do (
    set /a "_help_cd=4443+%%S"
    set /a "_help_srv=9000+%%S"
    echo   slot %%S: ChromeDriver=!_help_cd! Server=!_help_srv!
)
echo   (only the first MAX_WORKERS slots are actually started)
echo.
echo FILTERING:
echo   Same filter syntax as run_ui_tests.bat.
echo   Without arguments, runs ALL test files across all games.
echo   Filters apply at two levels:
echo     1. Game level  - determines which games are queued
echo     2. File level  - within each game, which test files to run
echo.
echo EXAMPLES:
echo   Run all tests in parallel (5 slots concurrent, default):
echo     run_ui_tests_parallel.bat
echo.
echo   Run all tests with 3-slot concurrency cap:
echo     run_ui_tests_parallel.bat --max-workers=3
echo.
echo   Run only Target Tag tests:
echo     run_ui_tests_parallel.bat target_tag
echo.
echo   Run two games with 2-slot cap (effectively equivalent to 2):
echo     run_ui_tests_parallel.bat --max-workers=2 target_tag monster_mash
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
echo   - Requires 16GB+ RAM recommended when MAX_WORKERS >= 5
echo   - Results saved to integration_test_output\parallel\
echo   - PID-scoped Chrome killing prevents cross-worker interference
echo   - Per-session DB isolation (X-DB-Session) prevents data pollution
echo   - 14-hour global timeout across the whole run (dispatcher)
echo   - Use run_ui_tests.bat for sequential debugging of single tests
echo.
exit /b 0
