@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Dart Games UI Automation Test Runner - Parallel Worker
REM ============================================================
REM Runs all tests for a single game category. Called by the
REM parallel orchestrator (run_ui_tests_parallel.bat).
REM
REM Arguments:
REM   %1 = game name (e.g. target_tag)
REM   %2 = ChromeDriver port (e.g. 4444)
REM   %3 = backend server port (e.g. 9001)
REM   %4 = output directory (e.g. integration_test_output\parallel)
REM   %5+ = optional filter tokens
REM
REM Environment:
REM   STUB_MODE=1  - simulate tests (1s delay, mocked results)
REM   STUB_FAIL=1  - in STUB_MODE, simulate failures
REM ============================================================

REM Parse positional args
set "_GAME=%~1"
set "_CD_PORT=%~2"
set "_SERVER_PORT=%~3"
set "_OUTPUT_DIR=%~4"
set "_WORKTREE_PATH=%~5"

if "%_GAME%"=="" (
    echo ERROR: Game name is required.
    echo Usage: run_ui_tests_parallel_worker.bat ^<game^> ^<cd_port^> ^<srv_port^> ^<output_dir^> [filters...]
    exit /b 1
)
if "%_CD_PORT%"=="" (
    echo ERROR: ChromeDriver port is required.
    exit /b 1
)
if "%_SERVER_PORT%"=="" (
    echo ERROR: Server port is required.
    exit /b 1
)
if "%_OUTPUT_DIR%"=="" (
    echo ERROR: Output directory is required.
    exit /b 1
)
if "%_WORKTREE_PATH%"=="" (
    echo ERROR: Worktree path is required.
    exit /b 1
)

call "%~dp0check_python_deps.bat"
if !errorlevel! neq 0 exit /b 1

REM Parse optional filter tokens (args 6+)
set "run_all=1"
set "token_count=0"
set "_argnum=0"
for %%T in (%*) do (
    set /a _argnum+=1
    if !_argnum! gtr 5 (
        set "run_all=0"
        set /a token_count+=1
        set "_nt=%%T"
        set "_nt=!_nt:\=/!"
        set "_nt=!_nt:.dart=!"
        set "tok!token_count!=!_nt!"
    )
)

REM Compute absolute output dir so log paths work when flutter drive
REM runs from a different directory (the worktree).
if not exist "%_OUTPUT_DIR%" mkdir "%_OUTPUT_DIR%"
pushd "%_OUTPUT_DIR%"
set "_OUTPUT_DIR_ABS=%CD%"
popd

REM Derive a unique web-server port from the ChromeDriver port so parallel
REM flutter drive instances don't fight over the default web port.
REM We use -d web-server (not -d chrome) to avoid Flutter's dual-Chrome bug
REM where a redundant "runner Chrome" conflicts with ChromeDriver's Chrome.
set /a "_WEB_PORT=%_CD_PORT%+36000"

REM Initialize
set "_GAME_DIR=integration_test\%_GAME%"
set "_CAT_DATADIR=%_OUTPUT_DIR%\test_data_%_GAME%"
set "_CAT_SERVER_LOG=%_OUTPUT_DIR%\server_%_GAME%.log"
set "test_count=0"
set "pass_count=0"
set "fail_count=0"
set "retry_count=0"
set "failed_tests="

if not exist "%_OUTPUT_DIR%" mkdir "%_OUTPUT_DIR%"

REM Record start time (epoch seconds)
for /f %%t in ('powershell -NoProfile -Command "Write-Output ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"') do set "_START_EPOCH=%%t"

echo ========================================
echo [WORKER] Game: %_GAME%
if defined STUB_MODE echo          [STUB MODE]
echo   ChromeDriver port: %_CD_PORT%
echo   Web server port: %_WEB_PORT%
echo   Backend server port: %_SERVER_PORT%
echo   Output: %_OUTPUT_DIR%
if not defined STUB_MODE echo   Worktree: %_WORKTREE_PATH%
if "!run_all!"=="0" (
    echo   Filters:
    for /l %%i in (1,1,!token_count!) do echo     [%%i] !tok%%i!
)
echo ========================================
echo.

REM Skip helper functions
goto :discover_tests

REM ============================================================
REM HELPER FUNCTIONS
REM ============================================================

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
timeout /t 1 /nobreak >nul 2>&1
goto :wait_for_chromedriver_port_loop

REM Wait for backend server on port %1
:wait_for_server_port
set "_wfsp_port=%~1"
set "_wfsp_count=0"
:wait_for_server_port_loop
set /a _wfsp_count+=1
if !_wfsp_count! gtr 15 (
    echo   ERROR: Backend server did not start on port !_wfsp_port! in time.
    exit /b 1
)
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:!_wfsp_port!/api/v1/health/' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>&1
if !errorlevel! equ 0 (
    echo   Backend server ready on port !_wfsp_port!.
    exit /b 0
)
timeout /t 1 /nobreak >nul 2>&1
goto :wait_for_server_port_loop

REM Kill Chrome processes spawned by this worker's ChromeDriver
:kill_chrome_for_port
set "_kcfp_port=%~1"
powershell -NoProfile -Command "$cdPid=(Get-NetTCPConnection -LocalPort !_kcfp_port! -State Listen -ErrorAction SilentlyContinue).OwningProcess|Select-Object -First 1;if($cdPid){Get-CimInstance Win32_Process|Where-Object{$_.ParentProcessId -eq $cdPid -and $_.Name -eq 'chrome.exe'}|ForEach-Object{Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}}"
exit /b

REM Kill process listening on port %1
:kill_port
for /f "tokens=5" %%a in ('netstat -aon ^| findstr "LISTENING" ^| findstr ":%~1 "') do taskkill /F /PID %%a >nul 2>&1
exit /b

REM ============================================================
REM Run a single test (with retry on infrastructure failures)
REM %1 = test file path
REM %2 = test driver (integration_test.dart or screenshot_test.dart)
REM ============================================================
:run_single_test
set "_RST_TARGET=%~1"
set "_RST_DRIVER=%~2"
set /a test_count+=1
set "_RST_ATTEMPT=0"

REM Build log filename from path (absolute so it works from the worktree dir)
set "_RST_LOGNAME=%_RST_TARGET:integration_test/=%"
set "_RST_LOGNAME=%_RST_LOGNAME:/=_%"
set "_RST_LOGNAME=%_RST_LOGNAME:\=_%"
set "_RST_LOGNAME=%_RST_LOGNAME:.dart=%"
set "_RST_LOG=%_OUTPUT_DIR_ABS%\%_RST_LOGNAME%.log"

echo ----------------------------------------
echo [%_GAME% !test_count!] !_RST_TARGET!
echo   ChromeDriver: %_CD_PORT%  Web: %_WEB_PORT%  Server: %_SERVER_PORT%
echo Start: %time%

:run_single_test_attempt
set /a _RST_ATTEMPT+=1
set "_RST_ABORT=0"

if !_RST_ATTEMPT! gtr 1 (
    echo   Infrastructure failure detected ^(attempt !_RST_ATTEMPT!/2^) - restarting services...
    echo. >> "!_RST_LOG!"
    echo ===== RETRY ATTEMPT !_RST_ATTEMPT! at %date% %time% ===== >> "!_RST_LOG!"

    REM Kill only this worker's Chrome - PID-scoped
    call :kill_chrome_for_port %_CD_PORT%

    REM Restart this worker's ChromeDriver
    call :kill_port %_CD_PORT%
    timeout /t 3 /nobreak >nul 2>&1
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=%_CD_PORT% >nul 2>&1
    call :wait_for_chromedriver_port %_CD_PORT%
    if !errorlevel! neq 0 (
        echo   ERROR: ChromeDriver failed to restart on port %_CD_PORT%. Marking test as failed.
        set "_RST_PASS=0"
        set "_RST_ABORT=1"
    )

    REM Check/restart this worker's server
    if "!_RST_ABORT!"=="0" (
        call :wait_for_server_port %_SERVER_PORT%
        if !errorlevel! neq 0 (
            echo   Backend server down - restarting on port %_SERVER_PORT%...
            call :kill_port %_SERVER_PORT%
            start /B "" cmd /C "cd server && dart run bin/server.dart --port %_SERVER_PORT% --data-dir ..\%_CAT_DATADIR% >> ..\%_CAT_SERVER_LOG% 2>&1"
            call :wait_for_server_port %_SERVER_PORT%
            if !errorlevel! neq 0 (
                echo   ERROR: Backend server failed to restart on port %_SERVER_PORT%. Marking test as failed.
                set "_RST_PASS=0"
                set "_RST_ABORT=1"
            )
        )
    )
)
if "!_RST_ABORT!"=="1" goto :run_single_test_done

if defined STUB_MODE (
    REM Stub mode: simulate test execution
    echo [STUB] Simulating: flutter drive --target=!_RST_TARGET! --driver-port=%_CD_PORT% --dart-define=SERVER_PORT=%_SERVER_PORT% > "!_RST_LOG!"
    echo Started at %date% %time% >> "!_RST_LOG!"
    timeout /t 1 /nobreak >nul 2>&1

    if defined STUB_FAIL (
        echo Some tests failed >> "!_RST_LOG!"
        set "_RST_PASS=0"
    ) else (
        echo All tests passed >> "!_RST_LOG!"
        set "_RST_PASS=1"
    )
) else (
    REM Real mode: run flutter drive from the isolated worktree directory.
    REM Each worker has its own worktree with its own build/ and .dart_tool/
    REM so builds never conflict across parallel workers.
    echo Running: !_RST_TARGET! > "!_RST_LOG!"
    echo Started at %date% %time% >> "!_RST_LOG!"
    echo ChromeDriver port: %_CD_PORT%  Web port: %_WEB_PORT%  Server port: %_SERVER_PORT% >> "!_RST_LOG!"
    echo Worktree: %_WORKTREE_PATH% >> "!_RST_LOG!"
    echo. >> "!_RST_LOG!"

    start /B "" cmd /C "cd /d %_WORKTREE_PATH% && flutter drive --driver=test_driver/!_RST_DRIVER! --target=!_RST_TARGET! -d web-server --browser-name=chrome --driver-port=%_CD_PORT% --web-port=%_WEB_PORT% --dart-define=SERVER_PORT=%_SERVER_PORT% --dart-define=OVERFLOW_TRAP=true --browser-dimension=1920x1080 >> "!_RST_LOG!" 2>&1"

    REM Reap the finished test. Historically this was two unconditional
    REM 10-second sleeps (teardown grace, then port-release grace) — ~20s of
    REM constant overhead per file, ~29 min per full single-game run. They
    REM guarded real races: killing Chrome mid-graceful-shutdown leaves
    REM crash-recovery state, and starting the next flutter drive before the
    REM previous one releases the fixed web port is a bind-failure flake.
    REM Both are now CONDITION POLLS with the same 10s ceilings:
    REM   1. after the log shows a terminal marker, poll (500ms) until the
    REM      drive's dart.exe (identified by --web-port on its command line)
    REM      exits, cap 10s. Graceful exit -> the Chrome kill below no-ops.
    REM      Still alive at 10s -> it's the hung-WebDriver.quit case, and the
    REM      kill unsticks it exactly as before.
    REM   2. after the kill, poll (500ms) until that process is gone AND the
    REM      web port has no listener, cap 10s, before reading the verdict
    REM      and letting the next file start.
    REM Worst case is identical to the old constants; the common case
    REM (teardown completes in ~1-2s) no longer pays the full 20s.
    REM The marker poll also tightened 3s -> 1s (same 600s watchdog budget).
    powershell -NoProfile -Command "$log='!_RST_LOG!';$cdPort=!_CD_PORT!;$webPort=!_WEB_PORT!;$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 600){Start-Sleep 1;$elapsed+=1;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};$dl=(Get-Date).AddSeconds(10);while(((Get-Date) -lt $dl) -and (Get-CimInstance Win32_Process | Where-Object{$_.Name -eq 'dart.exe' -and $_.CommandLine -match ('web-port='+$webPort)})){Start-Sleep -Milliseconds 500};$cdPid=(Get-NetTCPConnection -LocalPort $cdPort -State Listen -ErrorAction SilentlyContinue).OwningProcess|Select-Object -First 1;if($cdPid){Get-CimInstance Win32_Process|Where-Object{$_.ParentProcessId -eq $cdPid -and $_.Name -eq 'chrome.exe'}|ForEach-Object{Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}};$dl=(Get-Date).AddSeconds(10);while(((Get-Date) -lt $dl) -and ((Get-CimInstance Win32_Process | Where-Object{$_.Name -eq 'dart.exe' -and $_.CommandLine -match ('web-port='+$webPort)}) -or (Get-NetTCPConnection -LocalPort $webPort -State Listen -ErrorAction SilentlyContinue))){Start-Sleep -Milliseconds 500};$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed')) -and (-not ($c -match 'Failure Details:'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"

    if !errorlevel! equ 0 (set "_RST_PASS=1") else (set "_RST_PASS=0")
)

REM On first failure, check for infrastructure errors and retry once.
REM Patterns include WebDriver/connection drops (AppConnectionException,
REM SocketException, Target crashed, InvalidSessionIdException, DriverError
REM — the last two cover Chrome sessions that die before the test can
REM produce an assertion), parallel SDK-cache file lock races (Dart-side
REM PathAccessException AND PowerShell-side Set-Content errors on
REM engine.realm — the engine.realm filename is the most specific marker
REM of this race), transient network failures fetching Google Fonts
REM assets ("Failed to load font" / "Failed to fetch" / "ClientException"),
REM which are flake-prone, setup-helper races where the app webserver
REM comes up faster than the provider/state bootstrap finishes
REM (signature: stack frame referencing "shared/game_setup_helpers.dart"
REM in a DDC stack trace — real product bugs would crash in lib/... frames,
REM and a real helper bug would fail many tests at once, so a single test
REM with this frame is the classic flake shape), AND results-screen render-
REM timing races where the navigation to the results screen has not
REM completed when a button-presence helper runs ("should be present on
REM results screen" is the exact reason text used by every button-presence
REM assertion in shared/results_helpers.dart — it only appears in that one
REM infrastructure-side helper, never in test-body assertions or product
REM code, so it's a tight signal for results-screen render-timing flakes).
set "_RST_RETRY=0"
if "!_RST_PASS!"=="0" if !_RST_ATTEMPT! lss 2 (
    if not defined STUB_MODE (
        findstr /C:"AppConnectionException" /C:"SocketException" /C:"Target crashed" /C:"InvalidSessionIdException" /C:"DriverError" /C:"FormatException" /C:"PathAccessException" /C:"engine.realm" /C:"GetContentWriterIOError" /C:"Failed to load font" /C:"Failed to fetch" /C:"ClientException" /C:"shared/game_setup_helpers.dart" /C:"should be present on results screen" "!_RST_LOG!" >nul 2>&1
        if !errorlevel! equ 0 set "_RST_RETRY=1"
    )
)
if "!_RST_RETRY!"=="1" goto :run_single_test_attempt

:run_single_test_done
echo End: %time%

set "_RST_RESULT=FAILED"
if "!_RST_PASS!"=="1" set "_RST_RESULT=PASSED"
if "!_RST_PASS!"=="1" if !_RST_ATTEMPT! gtr 1 set "_RST_RESULT=PASSED (on retry)"

echo Result: !_RST_RESULT!
echo !_RST_RESULT! >> "!_RST_LOG!" 2>nul
echo Completed at %date% %time% >> "!_RST_LOG!" 2>nul

if "!_RST_PASS!"=="1" if !_RST_ATTEMPT! gtr 1 set /a retry_count+=1
if "!_RST_PASS!"=="1" (
    set /a pass_count+=1
) else (
    set /a fail_count+=1
    if "!failed_tests!"=="" (
        set "failed_tests=!_RST_TARGET!"
    ) else (
        set "failed_tests=!failed_tests!,!_RST_TARGET!"
    )
)
exit /b

REM ============================================================
REM DISCOVER AND RUN TESTS
REM ============================================================
:discover_tests

REM Run test files directly in the game directory (screenshot/showcase tests)
for %%F in ("!_GAME_DIR!\*_test.dart") do (
    set "_test_path=%%F"
    set "_test_path=!_test_path:\=/!"

    REM A file matches when run_all=1 OR any token is a substring of its path
    set "_file_matches=0"
    if "!run_all!"=="1" set "_file_matches=1"
    if "!_file_matches!"=="0" (
        for /l %%i in (1,1,!token_count!) do (
            if "!_file_matches!"=="0" (
                echo !_test_path! | findstr /i /C:"!tok%%i!" >nul 2>&1
                if !errorlevel! equ 0 set "_file_matches=1"
            )
        )
    )

    if "!_file_matches!"=="1" (
        set "_driver=integration_test.dart"
        echo %%~nF | findstr /i "screenshot" >nul 2>&1
        if !errorlevel! equ 0 set "_driver=screenshot_test.dart"

        call :run_single_test "!_test_path!" "!_driver!"
    )
)

REM Run test files in subdirectories
for /d %%D in ("!_GAME_DIR!\*") do (
    for %%F in ("%%D\*_test.dart") do (
        set "_test_path=%%F"
        set "_test_path=!_test_path:\=/!"

        set "_file_matches=0"
        if "!run_all!"=="1" set "_file_matches=1"
        if "!_file_matches!"=="0" (
            for /l %%i in (1,1,!token_count!) do (
                if "!_file_matches!"=="0" (
                    echo !_test_path! | findstr /i /C:"!tok%%i!" >nul 2>&1
                    if !errorlevel! equ 0 set "_file_matches=1"
                )
            )
        )

        if "!_file_matches!"=="1" (
            set "_driver=integration_test.dart"
            echo %%~nF | findstr /i "screenshot" >nul 2>&1
            if !errorlevel! equ 0 set "_driver=screenshot_test.dart"

            call :run_single_test "!_test_path!" "!_driver!"
        )
    )
)

REM ============================================================
REM Write result file
REM ============================================================
for /f %%t in ('powershell -NoProfile -Command "Write-Output ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"') do set "_END_EPOCH=%%t"
set /a _DURATION=_END_EPOCH - _START_EPOCH

echo.
echo ========================================
echo [WORKER] %_GAME% Complete
echo ========================================
echo Total: !test_count!  Passed: !pass_count!  Failed: !fail_count!
if !retry_count! gtr 0 echo Retried: !retry_count!
echo Duration: !_DURATION!s
echo.

(
echo GAME=%_GAME%
echo TOTAL=!test_count!
echo PASSED=!pass_count!
echo FAILED=!fail_count!
echo RETRIED=!retry_count!
echo DURATION=!_DURATION!
echo FAILED_TESTS=!failed_tests!
) > "%_OUTPUT_DIR_ABS%\%_GAME%_results.txt"

if !fail_count! gtr 0 exit /b 1
if !test_count! equ 0 exit /b 1
exit /b 0
