@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Dart Games UI Automation Test Runner (Dynamic File Scanner)
REM ============================================================
REM Automatically discovers and runs all *_test.dart files under
REM integration_test/. Each test file runs in its own flutter
REM drive process. ChromeDriver and backend server are shared per
REM game category. Per-session database isolation (X-DB-Session)
REM ensures tests cannot pollute each other's data.
REM ============================================================

REM Check for help request
if "%1"=="/?" goto :show_help
if "%1"=="/help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help

REM ============================================================
REM Parse command line arguments
REM ============================================================
REM Filters are path fragments matched against the full test file path.
REM Each arg is matched independently (OR logic). Backslashes are normalised
REM to forward slashes; the .dart extension is optional.
REM Examples:
REM   carnival_derby                              -> all carnival derby tests
REM   carnival_derby\save_resume                  -> all save/resume tests
REM   carnival_derby\save_resume\resume_modal_loads_game_test -> one file
REM   carnival_derby\save_resume\resume_modal_loads_game_test carnival_derby\save_resume\resume_modal_resave_overwrites_test -> two files
REM ============================================================
set "run_all=1"
set "token_count=0"

if not "%~1"=="" (
    set "run_all=0"
    for %%T in (%*) do (
        set /a token_count+=1
        set "_nt=%%T"
        set "_nt=!_nt:\=/!"
        set "_nt=!_nt:.dart=!"
        set "tok!token_count!=!_nt!"
    )
)

REM ============================================================
REM Pre-flight checks
REM ============================================================
echo ========================================
echo Dart Games UI Automation Test Runner
echo ========================================
echo.

if not exist "integration_test_output" mkdir integration_test_output

echo Cleaning previous test results...
del /Q integration_test_output\*.txt 2>nul
del /Q integration_test_output\*.log 2>nul

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
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM dart.exe >nul 2>&1
call :kill_server
if exist "ui_test_data" rmdir /S /Q "ui_test_data" >nul 2>&1
for /d %%d in ("integration_test_output\test_data_*") do rmdir /S /Q "%%d" >nul 2>&1
timeout /t 2 /nobreak >nul

if not exist "chromedriver\chromedriver-win64\chromedriver.exe" (
    echo ERROR: ChromeDriver not found at chromedriver\chromedriver-win64\chromedriver.exe
    pause
    exit /b 1
)

REM ============================================================
REM Initialize summary
REM ============================================================
echo ======================================== > integration_test_output\summary.txt
echo Dart Games UI Automation Test Results >> integration_test_output\summary.txt
echo ======================================== >> integration_test_output\summary.txt
echo Test suite started at %date% %time% >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt

set test_count=0
set pass_count=0
set fail_count=0
set retry_count=0
set cat_count=0

echo ========================================
if "!run_all!"=="1" (
    echo Running All UI Automation Tests
) else (
    echo Running Filtered UI Automation Tests:
    for /l %%i in (1,1,!token_count!) do echo   [%%i] !tok%%i!
)
echo ========================================
echo.
echo NOTE: ChromeDriver and backend server are shared per game category.
echo       Chrome is killed after each test ^(GCM thread hang fix^).
echo       Per-session DB isolation ensures no cross-test pollution.
echo.

REM Skip over helper function definitions
goto :discover_tests

REM ============================================================
REM HELPER FUNCTIONS
REM ============================================================

:kill_server
for /f "tokens=5" %%a in ('netstat -aon ^| findstr "LISTENING" ^| findstr ":8080 "') do taskkill /F /PID %%a >nul 2>&1
exit /b

REM Kill backend server listening on the port passed as %1
:kill_server_port
for /f "tokens=5" %%a in ('netstat -aon ^| findstr "LISTENING" ^| findstr ":%~1 "') do taskkill /F /PID %%a >nul 2>&1
exit /b

:kill_services
taskkill /F /IM chromedriver.exe >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
timeout /t 2 /nobreak >nul
exit /b

:wait_for_server
set "_wfs_count=0"
:wait_for_server_loop
set /a _wfs_count+=1
if !_wfs_count! gtr 15 (
    echo   ERROR: Backend server did not start in time.
    exit /b 1
)
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/api/v1/health/' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>&1
if !errorlevel! equ 0 (
    echo   Backend server is ready.
    exit /b 0
)
timeout /t 1 /nobreak >nul
goto :wait_for_server_loop

REM Wait for backend server on port %1 to become healthy
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
timeout /t 1 /nobreak >nul
goto :wait_for_server_port_loop

:wait_for_chromedriver
set "_wfc_count=0"
:wait_for_chromedriver_loop
set /a _wfc_count+=1
if !_wfc_count! gtr 10 (
    echo   ERROR: ChromeDriver did not start in time.
    exit /b 1
)
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:4444/status' -UseBasicParsing -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch {}; exit 1" >nul 2>&1
if !errorlevel! equ 0 (
    echo   ChromeDriver is ready.
    exit /b 0
)
timeout /t 1 /nobreak >nul
goto :wait_for_chromedriver_loop

REM Start ChromeDriver only (backend server is started per-category in the game loop)
:start_services
set "_ss_attempt=0"
:start_services_loop
set /a _ss_attempt+=1
if !_ss_attempt! gtr 3 (
    echo   ERROR: Failed to start ChromeDriver after 3 attempts.
    exit /b 1
)
if !_ss_attempt! gtr 1 (
    echo   Retry attempt !_ss_attempt!/3...
    taskkill /F /IM chromedriver.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
)
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
call :wait_for_chromedriver
if !errorlevel! neq 0 (
    echo   ChromeDriver failed to start, retrying...
    goto :start_services_loop
)
exit /b 0

REM ============================================================
REM Run a single test file (with one automatic retry on infrastructure failures)
REM Uses the category-level backend server (shared across all
REM tests in the category). Per-session DB isolation via
REM X-DB-Session header ensures no cross-test pollution.
REM On AppConnectionException or SocketException, ChromeDriver and
REM the backend server are restarted and the test is retried once.
REM %1 = test file path (e.g. integration_test/target_tag/gameplay/hero_bonus_test.dart)
REM %2 = test driver (integration_test.dart or screenshot_test.dart)
REM ============================================================
:run_single_test
set "_RST_TARGET=%~1"
set "_RST_DRIVER=%~2"
set /a test_count+=1
set "_RST_ATTEMPT=0"

REM Build log filename from path: replace / and \ with _
set "_RST_LOGNAME=%_RST_TARGET:integration_test/=%"
set "_RST_LOGNAME=%_RST_LOGNAME:/=_%"
set "_RST_LOGNAME=%_RST_LOGNAME:\=_%"
set "_RST_LOGNAME=%_RST_LOGNAME:.dart=%"
set "_RST_LOG=integration_test_output\%_RST_LOGNAME%.log"

echo ----------------------------------------
echo [!test_count!] !_RST_TARGET!
echo   Server port: !_CAT_PORT!
echo Start: %time%

echo ---------------------------------------- >> integration_test_output\summary.txt
echo [!test_count!] !_RST_TARGET! >> integration_test_output\summary.txt
echo Start Time: %date% %time% >> integration_test_output\summary.txt

echo Running: !_RST_TARGET! > "!_RST_LOG!"
echo Started at %date% %time% >> "!_RST_LOG!"
echo Server port: !_CAT_PORT! >> "!_RST_LOG!"
echo. >> "!_RST_LOG!"

:run_single_test_attempt
set /a _RST_ATTEMPT+=1

set "_RST_ABORT=0"
if !_RST_ATTEMPT! gtr 1 (
    echo   Infrastructure failure detected ^(attempt !_RST_ATTEMPT!/2^) - restarting ChromeDriver and server...
    echo. >> "!_RST_LOG!"
    echo ===== RETRY ATTEMPT !_RST_ATTEMPT! at %date% %time% ===== >> "!_RST_LOG!"
    taskkill /F /IM chrome.exe >nul 2>&1
    taskkill /F /IM chromedriver.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
    call :start_services
    if !errorlevel! neq 0 (
        echo   ERROR: ChromeDriver failed to restart. Marking test as failed.
        set "_RST_PASS=0"
        set "_RST_ABORT=1"
    )
    if "!_RST_ABORT!"=="0" (
        call :wait_for_server_port !_CAT_PORT!
        if !errorlevel! neq 0 (
            echo   Backend server also down - restarting...
            call :kill_server_port !_CAT_PORT!
            start /B "" cmd /C "cd server && dart run bin/server.dart --port !_CAT_PORT! --data-dir ..\!_CAT_DATADIR! >> ..\!_CAT_SERVER_LOG! 2>&1"
            call :wait_for_server_port !_CAT_PORT!
            if !errorlevel! neq 0 (
                echo   ERROR: Backend server failed to restart. Marking test as failed.
                set "_RST_PASS=0"
                set "_RST_ABORT=1"
            )
        )
    )
)
if "!_RST_ABORT!"=="1" goto :run_single_test_done

start /B "" cmd /C "flutter drive --driver=test_driver/!_RST_DRIVER! --target=!_RST_TARGET! -d chrome --dart-define=SERVER_PORT=!_CAT_PORT! --web-browser-flag=--start-maximized >> "!_RST_LOG!" 2>&1"

powershell -NoProfile -Command "$log='!_RST_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 600){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"

if !errorlevel! equ 0 (set "_RST_PASS=1") else (set "_RST_PASS=0")

REM On first failure, check for infrastructure errors and retry once
set "_RST_RETRY=0"
if "!_RST_PASS!"=="0" if !_RST_ATTEMPT! lss 2 (
    findstr /C:"AppConnectionException" /C:"SocketException" /C:"Target crashed" "!_RST_LOG!" >nul 2>&1
    if !errorlevel! equ 0 set "_RST_RETRY=1"
)
if "!_RST_RETRY!"=="1" goto :run_single_test_attempt

:run_single_test_done
echo End: %time%
echo End Time: %date% %time% >> integration_test_output\summary.txt

set "_RST_RESULT=FAILED"
if "!_RST_PASS!"=="1" set "_RST_RESULT=PASSED"
if "!_RST_PASS!"=="1" if !_RST_ATTEMPT! gtr 1 set "_RST_RESULT=PASSED (on retry)"

echo Result: !_RST_RESULT!
echo Result: !_RST_RESULT! >> integration_test_output\summary.txt
echo !_RST_RESULT! >> "!_RST_LOG!" 2>nul

if "!_RST_PASS!"=="1" if !_RST_ATTEMPT! gtr 1 set /a retry_count+=1
if "!_RST_PASS!"=="1" set /a pass_count+=1
if not "!_RST_PASS!"=="1" set /a fail_count+=1

echo Completed at %date% %time% >> "!_RST_LOG!" 2>nul
echo. >> integration_test_output\summary.txt
exit /b

REM ============================================================
REM DISCOVER AND RUN TESTS
REM ============================================================
:discover_tests

REM Define game categories in execution order
set "GAMES=target_tag carnival_derby monster_mash reef_royale clockwork_quest"

for %%G in (%GAMES%) do (
    set "_GAME=%%G"
    set "_GAME_DIR=integration_test\%%G"

    REM A game matches when run_all=1, OR when at least one token either:
    REM   (a) is a substring of the game name  (e.g. "carnival" matches "carnival_derby")
    REM   (b) contains the game name            (e.g. "carnival_derby/save_resume" contains "carnival_derby")
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
        set /a cat_count+=1
        set /a _CAT_PORT=9000+cat_count
        set "_CAT_DATADIR=integration_test_output\test_data_%%G"
        set "_CAT_SERVER_LOG=integration_test_output\server_%%G.log"

        echo.
        echo ========================================
        echo Game: %%G
        echo   Server port: !_CAT_PORT!  Data dir: !_CAT_DATADIR!
        echo ========================================

        echo. >> integration_test_output\summary.txt
        echo ======================================== >> integration_test_output\summary.txt
        echo Game: %%G >> integration_test_output\summary.txt
        echo ======================================== >> integration_test_output\summary.txt

        echo Starting ChromeDriver...
        call :start_services

        echo Starting backend server for %%G on port !_CAT_PORT!...
        if not exist "!_CAT_DATADIR!" mkdir "!_CAT_DATADIR!"
        start /B "" cmd /C "cd server && dart run bin/server.dart --port !_CAT_PORT! --data-dir ..\!_CAT_DATADIR! >> ..\!_CAT_SERVER_LOG! 2>&1"
        call :wait_for_server_port !_CAT_PORT!
        set "_cat_ok=1"
        if !errorlevel! neq 0 (
            echo   ERROR: Backend server failed to start on port !_CAT_PORT! for %%G. Skipping category.
            echo Server failed to start >> integration_test_output\summary.txt
            call :kill_services
            set "_cat_ok=0"
        )

        if "!_cat_ok!"=="1" (
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

            echo.
            echo Stopping backend server and ChromeDriver for next game...
            call :kill_server_port !_CAT_PORT!
            timeout /t 1 /nobreak >nul
            call :kill_services
        )
    )
)

REM ============================================================
REM Summary
REM ============================================================
echo.
echo ========================================
echo Test Suite Complete
echo ========================================
echo.
echo Total Test Files: !test_count!
echo Passed: !pass_count!
if !retry_count! gtr 0 echo Passed ^(on retry^): !retry_count!
echo Failed: !fail_count!
echo.

echo ======================================== >> integration_test_output\summary.txt
echo Test Suite Summary >> integration_test_output\summary.txt
echo ======================================== >> integration_test_output\summary.txt
echo Completed at %date% %time% >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo Total Test Files: !test_count! >> integration_test_output\summary.txt
echo Passed: !pass_count! >> integration_test_output\summary.txt
if !retry_count! gtr 0 echo Passed ^(on retry^): !retry_count! >> integration_test_output\summary.txt
echo Failed: !fail_count! >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt

echo Results saved to integration_test_output folder
echo Summary: integration_test_output\summary.txt
echo.

echo Stopping any remaining ChromeDriver and Chrome...
call :kill_services
if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_final" >nul 2>&1
echo Services stopped.
echo.

if !fail_count! gtr 0 (
    echo WARNING: !fail_count! test file^(s^) failed. Check log files for details.
    exit /b 1
) else if !test_count! equ 0 (
    echo WARNING: No test files matched the filter "!filter!"
    exit /b 1
) else (
    echo SUCCESS: All !pass_count! test files passed!
    exit /b 0
)

REM ============================================================
REM Help Section
REM ============================================================
:show_help
echo.
echo ========================================
echo Dart Games UI Automation Test Runner
echo ========================================
echo.
echo USAGE:
echo   run_ui_tests.bat [filter1] [filter2] ...
echo   run_ui_tests.bat /?
echo.
echo DESCRIPTION:
echo   Runs UI automation tests for the Dart Games application.
echo   Automatically discovers all *_test.dart files under integration_test/.
echo   Each test file runs in its own flutter drive process.
echo.
echo FILTERING:
echo   Without arguments, runs ALL test files.
echo   With arguments, runs only files whose path matches any filter.
echo.
echo EXAMPLES:
echo   Run all tests:
echo     run_ui_tests.bat
echo.
echo   Run all Target Tag tests:
echo     run_ui_tests.bat target_tag
echo.
echo   Run only save/resume tests:
echo     run_ui_tests.bat save_resume
echo.
echo   Run a specific game's gameplay tests:
echo     run_ui_tests.bat reef_royale/gameplay
echo.
echo   Run multiple categories:
echo     run_ui_tests.bat target_tag monster_mash
echo.
echo   Run a specific test file:
echo     run_ui_tests.bat save_modal_back_0_darts
echo.
echo NOTES:
echo   - ChromeDriver must be at chromedriver\chromedriver-win64\chromedriver.exe
echo   - Results saved to integration_test_output\
echo   - ChromeDriver and backend server restart between game categories
echo   - Chrome killed after each test (GCM thread hang fix)
echo   - Per-session DB isolation (X-DB-Session) prevents cross-test pollution
echo   - Summary saved to integration_test_output\summary.txt
echo.
exit /b 0
