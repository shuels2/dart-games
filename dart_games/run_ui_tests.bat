@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Check for help request
REM ============================================================
if "%1"=="/?" goto :show_help
if "%1"=="/help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help

REM ============================================================
REM Parse command line arguments to get list of files to run
REM ============================================================
set "file_list="
set "run_all=1"

REM If any parameters provided, disable run_all and build file list
if not "%~1"=="" set "run_all=0"
if not "%~1"=="" goto :parse_args
goto :done_parsing

:parse_args
if "%~1"=="" goto :done_parsing
set "file_list=!file_list! %~1"
shift
goto :parse_args

:done_parsing

REM ============================================================
REM Start Test Suite
REM ============================================================
echo ========================================
echo Dart Games UI Automation Test Runner
echo ========================================
echo.

REM Create output folder if it doesn't exist
if not exist "integration_test_output" (
    echo Creating integration_test_output folder...
    mkdir integration_test_output
)

REM Clean previous test results
echo Cleaning previous test results...
del /Q integration_test_output\*.txt 2>nul
del /Q integration_test_output\*.log 2>nul

REM Ensure ChromeDriver matches installed Chrome version
echo Verifying ChromeDriver version matches Chrome...
call update_chromedriver.bat
if !errorlevel! neq 0 (
    echo.
    echo ERROR: ChromeDriver version check failed. Cannot proceed with tests.
    echo Please resolve the issue above and try again.
    pause
    exit /b 1
)

REM Verify server exists
if not exist "server\bin\server.dart" (
    echo ERROR: Backend server not found at server\bin\server.dart
    echo Please ensure the server is set up correctly.
    pause
    exit /b 1
)

REM Ensure Flutter dependencies are resolved (always run — fast when cached,
REM but catches stale paths from other machines or after pub cache clean)
echo Resolving Flutter dependencies...
call flutter pub get
if !errorlevel! neq 0 (
    echo ERROR: Failed to resolve Flutter dependencies.
    pause
    exit /b 1
)
echo Flutter dependencies resolved.

REM Ensure server dependencies are resolved
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
echo Server dependencies resolved.

REM Kill any existing chromedriver/chrome/server processes
echo Stopping any existing ChromeDriver, Chrome, and Backend Server instances...
taskkill /F /IM chromedriver.exe >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
call :kill_server
REM Clean up stale data from previous runs
if exist "ui_test_data" rmdir /S /Q "ui_test_data" >nul 2>&1
for /d %%d in ("integration_test_output\test_data_*") do rmdir /S /Q "%%d" >nul 2>&1
timeout /t 2 /nobreak >nul

REM Verify chromedriver exists
if not exist "chromedriver\chromedriver-win64\chromedriver.exe" (
    echo ERROR: ChromeDriver not found at chromedriver\chromedriver-win64\chromedriver.exe
    echo Please ensure ChromeDriver is installed in the correct location.
    pause
    exit /b 1
)

REM Record start time
echo ======================================== > integration_test_output\summary.txt
echo Dart Games UI Automation Test Results >> integration_test_output\summary.txt
echo ======================================== >> integration_test_output\summary.txt
echo Test suite started at %date% %time% >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt

set test_count=0
set pass_count=0
set fail_count=0

echo ========================================
if "!run_all!"=="1" (
    echo Running All UI Automation Tests ^(272 tests, ~173 minutes^)
) else (
    echo Running Selected UI Automation Tests
)
echo ========================================
echo.
echo NOTE: ChromeDriver and Backend Server are restarted between each
echo       test suite for a clean session. Chrome is killed after each
echo       suite to unblock flutter drive (GCM background thread hang).
echo.

REM ============================================================
REM APPROACH:
REM   Each test runs flutter drive in the background. A PowerShell
REM   monitor reads the log every 3 seconds looking for the terminal
REM   markers "All tests passed", "Some tests failed", or
REM   "Application finished" - much more reliable than watching
REM   file size which gave false positives during quiet test phases.
REM   After completion is detected, Chrome is killed (to handle the
REM   GCM hang), then the log is re-read to determine pass/fail.
REM   ChromeDriver and Backend Server are restarted between tests
REM   so each suite gets a clean WebDriver session and fresh database.
REM ============================================================

REM Skip over helper function definitions
goto :start_tests

REM ============================================================
REM Helper function to check if a file should run
REM ============================================================
REM Sets should_run=1 if file should run, 0 otherwise
REM %1 = filename to check
:check_should_run
set "should_run=0"
if "!run_all!"=="1" (
    set "should_run=1"
    exit /b
)
REM Check if any user argument is a substring of the test filename
echo %~1 | findstr /i !file_list! >nul
if !errorlevel! equ 0 (
    set "should_run=1"
)
exit /b

REM ============================================================
REM Helper function to kill backend server by port
REM ============================================================
:kill_server
for /f "tokens=5" %%a in ('netstat -aon ^| findstr "LISTENING" ^| findstr ":8080 "') do taskkill /F /PID %%a >nul 2>&1
exit /b

REM ============================================================
REM Helper function to kill all services (chromedriver + chrome + server)
REM ============================================================
:kill_services
taskkill /F /IM chromedriver.exe >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
call :kill_server
timeout /t 2 /nobreak >nul
exit /b

REM ============================================================
REM Helper function to wait for backend server to be ready
REM ============================================================
REM Polls the health endpoint up to 15 times (1 second apart).
REM Exits /b 0 on success, /b 1 on timeout.
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

REM ============================================================
REM Helper function to wait for ChromeDriver to be ready
REM ============================================================
REM Polls the /status endpoint up to 10 times (1 second apart).
REM Exits /b 0 on success, /b 1 on timeout.
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

REM ============================================================
REM Helper function to start services with retry
REM ============================================================
REM Starts chromedriver and server. If either fails health check,
REM kills both and retries (up to 3 attempts).
:start_services
set "_ss_attempt=0"
:start_services_loop
set /a _ss_attempt+=1
if !_ss_attempt! gtr 3 (
    echo   ERROR: Failed to start services after 3 attempts.
    exit /b 1
)
if !_ss_attempt! gtr 1 (
    echo   Retry attempt !_ss_attempt!/3...
    call :kill_services
)
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
start /B "" cmd /C "cd server && dart run bin/server.dart --data-dir ../ui_test_data >> ../integration_test_output/server.log 2>&1"
call :wait_for_chromedriver
if !errorlevel! neq 0 (
    echo   ChromeDriver failed to start, retrying...
    goto :start_services_loop
)
call :wait_for_server
if !errorlevel! neq 0 (
    echo   Backend server failed to start, retrying...
    goto :start_services_loop
)
exit /b 0

:start_tests
REM ----------------------------------------------------------
REM Test 1: Target Tag Menu and Mechanics
REM ----------------------------------------------------------
call :check_should_run "target_tag_menu_and_mechanics_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Target Tag Menu and Mechanics Test
    echo ========================================
    echo File: target_tag_menu_and_mechanics_test.dart
    echo Tests: 24 tests
    echo Expected Duration: ~16 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Menu and Mechanics Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_menu_and_mechanics_test.dart >> integration_test_output\summary.txt
    echo Tests: 24 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~16 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\01_target_tag_menu_and_mechanics.log
    set _TARGET=integration_test/target_tag/target_tag_menu_and_mechanics_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 2: Target Tag Visual Validation
REM ----------------------------------------------------------
call :check_should_run "target_tag_visual_validation_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Target Tag Visual Validation Test
    echo ========================================
    echo File: target_tag_visual_validation_test.dart
    echo Tests: 4 tests
    echo Expected Duration: ~5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Visual Validation Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_visual_validation_test.dart >> integration_test_output\summary.txt
    echo Tests: 4 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\02_target_tag_visual_validation.log
    set _TARGET=integration_test/target_tag/target_tag_visual_validation_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 3: Target Tag Gameplay
REM ----------------------------------------------------------
call :check_should_run "target_tag_gameplay_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Target Tag Gameplay Test
    echo ========================================
    echo File: target_tag_gameplay_test.dart
    echo Tests: 13 tests
    echo Expected Duration: ~9 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Gameplay Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_gameplay_test.dart >> integration_test_output\summary.txt
    echo Tests: 13 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~9 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\03_target_tag_gameplay.log
    set _TARGET=integration_test/target_tag/target_tag_gameplay_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 4: Target Tag Add Player
REM ----------------------------------------------------------
call :check_should_run "target_tag_add_player_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Target Tag Add Player Test
    echo ========================================
    echo File: target_tag_add_player_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~3 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Add Player Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_add_player_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~3 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\04_target_tag_add_player.log
    set _TARGET=integration_test/target_tag/target_tag_add_player_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 5: Target Tag Results Screen
REM ----------------------------------------------------------
call :check_should_run "target_tag_results_screen_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Target Tag Results Screen Test
    echo ========================================
    echo File: target_tag_results_screen_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~7 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Results Screen Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_results_screen_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~7 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\05_target_tag_results_screen.log
    set _TARGET=integration_test/target_tag/target_tag_results_screen_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 6: Carnival Derby UI
REM ----------------------------------------------------------
call :check_should_run "carnival_derby_ui_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Carnival Derby UI Test
    echo ========================================
    echo File: carnival_derby_ui_test.dart
    echo Tests: 24 tests
    echo Expected Duration: ~14 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Carnival Derby UI Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: carnival_derby_ui_test.dart >> integration_test_output\summary.txt
    echo Tests: 24 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~14 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\06_carnival_derby_ui.log
    set _TARGET=integration_test/carnival_derby/carnival_derby_ui_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

REM ----------------------------------------------------------
REM Test 7: Monster Mash Add Player
REM ----------------------------------------------------------
call :check_should_run "monster_mash_add_player_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Monster Mash Add Player Test
    echo ========================================
    echo File: monster_mash_add_player_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~3 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Add Player Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_add_player_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~3 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\07_monster_mash_add_player.log
    set _TARGET=integration_test/monster_mash/monster_mash_add_player_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 8: Monster Mash Menu and Settings
REM ----------------------------------------------------------
call :check_should_run "monster_mash_menu_and_settings_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Monster Mash Menu and Settings Test
    echo ========================================
    echo File: monster_mash_menu_and_settings_test.dart
    echo Tests: 8 tests
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Menu and Settings Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_menu_and_settings_test.dart >> integration_test_output\summary.txt
    echo Tests: 8 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\08_monster_mash_menu_and_settings.log
    set _TARGET=integration_test/monster_mash/monster_mash_menu_and_settings_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 9: Monster Mash Gameplay
REM ----------------------------------------------------------
call :check_should_run "monster_mash_gameplay_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Monster Mash Gameplay Test
    echo ========================================
    echo File: monster_mash_gameplay_test.dart
    echo Tests: 20 tests
    echo Expected Duration: ~11 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Gameplay Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_gameplay_test.dart >> integration_test_output\summary.txt
    echo Tests: 20 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~11 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\09_monster_mash_gameplay.log
    set _TARGET=integration_test/monster_mash/monster_mash_gameplay_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 10: Monster Mash Edit Score
REM ----------------------------------------------------------
call :check_should_run "monster_mash_edit_score_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Monster Mash Edit Score Test
    echo ========================================
    echo File: monster_mash_edit_score_test.dart
    echo Tests: 5 tests
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Edit Score Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_edit_score_test.dart >> integration_test_output\summary.txt
    echo Tests: 5 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\10_monster_mash_edit_score.log
    set _TARGET=integration_test/monster_mash/monster_mash_edit_score_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 11: Monster Mash Results Screen
REM ----------------------------------------------------------
call :check_should_run "monster_mash_results_screen_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Monster Mash Results Screen Test
    echo ========================================
    echo File: monster_mash_results_screen_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Results Screen Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_results_screen_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\11_monster_mash_results_screen.log
    set _TARGET=integration_test/monster_mash/monster_mash_results_screen_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 12: Monster Mash Visual Validation
REM ----------------------------------------------------------
call :check_should_run "monster_mash_visual_validation_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Monster Mash Visual Validation Test
    echo ========================================
    echo File: monster_mash_visual_validation_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Visual Validation Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_visual_validation_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\12_monster_mash_visual_validation.log
    set _TARGET=integration_test/monster_mash/monster_mash_visual_validation_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 13: Reef Royale Add Player
REM ----------------------------------------------------------
call :check_should_run "reef_royale_add_player_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Add Player Test
    echo ========================================
    echo File: reef_royale_add_player_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~2 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Add Player Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_add_player_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~2 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\13_reef_royale_add_player.log
    set _TARGET=integration_test/reef_royale/reef_royale_add_player_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 14: Reef Royale Menu and Settings
REM ----------------------------------------------------------
call :check_should_run "reef_royale_menu_and_settings_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Menu and Settings Test
    echo ========================================
    echo File: reef_royale_menu_and_settings_test.dart
    echo Tests: 10 tests
    echo Expected Duration: ~3 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Menu and Settings Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_menu_and_settings_test.dart >> integration_test_output\summary.txt
    echo Tests: 10 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~3 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\14_reef_royale_menu_and_settings.log
    set _TARGET=integration_test/reef_royale/reef_royale_menu_and_settings_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 15: Reef Royale Gameplay
REM ----------------------------------------------------------
call :check_should_run "reef_royale_gameplay_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Gameplay Test
    echo ========================================
    echo File: reef_royale_gameplay_test.dart
    echo Tests: 25 tests
    echo Expected Duration: ~12 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Gameplay Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_gameplay_test.dart >> integration_test_output\summary.txt
    echo Tests: 25 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~12 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\15_reef_royale_gameplay.log
    set _TARGET=integration_test/reef_royale/reef_royale_gameplay_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 16: Reef Royale Edit Score
REM ----------------------------------------------------------
call :check_should_run "reef_royale_edit_score_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Edit Score Test
    echo ========================================
    echo File: reef_royale_edit_score_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Edit Score Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_edit_score_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\16_reef_royale_edit_score.log
    set _TARGET=integration_test/reef_royale/reef_royale_edit_score_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 17: Reef Royale Results Screen
REM ----------------------------------------------------------
call :check_should_run "reef_royale_results_screen_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Results Screen Test
    echo ========================================
    echo File: reef_royale_results_screen_test.dart
    echo Tests: 6 tests
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Results Screen Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_results_screen_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\17_reef_royale_results_screen.log
    set _TARGET=integration_test/reef_royale/reef_royale_results_screen_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 18: Reef Royale Visual Validation
REM ----------------------------------------------------------
call :check_should_run "reef_royale_visual_validation_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Visual Validation Test
    echo ========================================
    echo File: reef_royale_visual_validation_test.dart
    echo Tests: 7 tests
    echo Expected Duration: ~3 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Visual Validation Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_visual_validation_test.dart >> integration_test_output\summary.txt
    echo Tests: 7 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~3 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\18_reef_royale_visual_validation.log
    set _TARGET=integration_test/reef_royale/reef_royale_visual_validation_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 19: Reef Royale Showcase
REM ----------------------------------------------------------
call :check_should_run "reef_royale_showcase_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Showcase Test
    echo ========================================
    echo File: reef_royale_showcase_test.dart
    echo Tests: 1 test
    echo Expected Duration: ~1 minute
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Showcase Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_showcase_test.dart >> integration_test_output\summary.txt
    echo Tests: 1 test >> integration_test_output\summary.txt
    echo Expected Duration: ~1 minute >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\19_reef_royale_showcase.log
    set _TARGET=integration_test/reef_royale/reef_royale_showcase_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

REM ----------------------------------------------------------
REM Test 20: Carnival Derby Save & Resume
REM ----------------------------------------------------------
call :check_should_run "carnival_derby_save_resume_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Carnival Derby Save ^& Resume Test
    echo ========================================
    echo File: carnival_derby_save_resume_test.dart
    echo Tests: 9 tests
    echo Expected Duration: ~8 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Carnival Derby Save ^& Resume Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: carnival_derby_save_resume_test.dart >> integration_test_output\summary.txt
    echo Tests: 9 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~8 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\20_carnival_derby_save_resume.log
    set _TARGET=integration_test/carnival_derby/carnival_derby_save_resume_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 21: Target Tag Save & Resume
REM ----------------------------------------------------------
call :check_should_run "target_tag_save_resume_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Target Tag Save ^& Resume Test
    echo ========================================
    echo File: target_tag_save_resume_test.dart
    echo Tests: 9 tests
    echo Expected Duration: ~8 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Save ^& Resume Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_save_resume_test.dart >> integration_test_output\summary.txt
    echo Tests: 9 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~8 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\21_target_tag_save_resume.log
    set _TARGET=integration_test/target_tag/target_tag_save_resume_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 22: Monster Mash Save & Resume
REM ----------------------------------------------------------
call :check_should_run "monster_mash_save_resume_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Monster Mash Save ^& Resume Test
    echo ========================================
    echo File: monster_mash_save_resume_test.dart
    echo Tests: 9 tests
    echo Expected Duration: ~8 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Save ^& Resume Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_save_resume_test.dart >> integration_test_output\summary.txt
    echo Tests: 9 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~8 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\22_monster_mash_save_resume.log
    set _TARGET=integration_test/monster_mash/monster_mash_save_resume_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
    echo Restarting ChromeDriver and Backend Server for next test...
    call :kill_services
    echo.
)

REM ----------------------------------------------------------
REM Test 23: Reef Royale Save & Resume
REM ----------------------------------------------------------
call :check_should_run "reef_royale_save_resume_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Reef Royale Save ^& Resume Test
    echo ========================================
    echo File: reef_royale_save_resume_test.dart
    echo Tests: 9 tests
    echo Expected Duration: ~8 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Save ^& Resume Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_save_resume_test.dart >> integration_test_output\summary.txt
    echo Tests: 9 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~8 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\23_reef_royale_save_resume.log
    set _TARGET=integration_test/reef_royale/reef_royale_save_resume_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

REM ==================================================================
REM Clockwork Quest UI Tests (7 files, 105 tests, ~57 minutes)
REM ==================================================================

call :check_should_run "clockwork_quest_add_player_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Clockwork Quest Add Player Test
    echo ========================================
    echo File: clockwork_quest_add_player_test.dart
    echo Tests: 10 tests
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Clockwork Quest Add Player Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: clockwork_quest_add_player_test.dart >> integration_test_output\summary.txt
    echo Tests: 10 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\24_clockwork_quest_add_player.log
    set _TARGET=integration_test/clockwork_quest/clockwork_quest_add_player_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

call :check_should_run "clockwork_quest_menu_and_settings_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Clockwork Quest Menu and Settings Test
    echo ========================================
    echo File: clockwork_quest_menu_and_settings_test.dart
    echo Tests: 20 tests
    echo Expected Duration: ~7 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Clockwork Quest Menu and Settings Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: clockwork_quest_menu_and_settings_test.dart >> integration_test_output\summary.txt
    echo Tests: 20 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~7 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\25_clockwork_quest_menu_and_settings.log
    set _TARGET=integration_test/clockwork_quest/clockwork_quest_menu_and_settings_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

call :check_should_run "clockwork_quest_gameplay_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Clockwork Quest Gameplay Test
    echo ========================================
    echo File: clockwork_quest_gameplay_test.dart
    echo Tests: 36 tests
    echo Expected Duration: ~17 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Clockwork Quest Gameplay Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: clockwork_quest_gameplay_test.dart >> integration_test_output\summary.txt
    echo Tests: 36 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~17 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\26_clockwork_quest_gameplay.log
    set _TARGET=integration_test/clockwork_quest/clockwork_quest_gameplay_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

call :check_should_run "clockwork_quest_edit_score_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Clockwork Quest Edit Score Test
    echo ========================================
    echo File: clockwork_quest_edit_score_test.dart
    echo Tests: 11 tests
    echo Expected Duration: ~6 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Clockwork Quest Edit Score Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: clockwork_quest_edit_score_test.dart >> integration_test_output\summary.txt
    echo Tests: 11 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~6 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\27_clockwork_quest_edit_score.log
    set _TARGET=integration_test/clockwork_quest/clockwork_quest_edit_score_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

call :check_should_run "clockwork_quest_results_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Clockwork Quest Results Test
    echo ========================================
    echo File: clockwork_quest_results_test.dart
    echo Tests: 11 tests
    echo Expected Duration: ~9 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Clockwork Quest Results Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: clockwork_quest_results_test.dart >> integration_test_output\summary.txt
    echo Tests: 11 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~9 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\28_clockwork_quest_results.log
    set _TARGET=integration_test/clockwork_quest/clockwork_quest_results_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

call :check_should_run "clockwork_quest_save_resume_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Clockwork Quest Save ^& Resume Test
    echo ========================================
    echo File: clockwork_quest_save_resume_test.dart
    echo Tests: 16 tests
    echo Expected Duration: ~10 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Clockwork Quest Save ^& Resume Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: clockwork_quest_save_resume_test.dart >> integration_test_output\summary.txt
    echo Tests: 16 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~10 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\29_clockwork_quest_save_resume.log
    set _TARGET=integration_test/clockwork_quest/clockwork_quest_save_resume_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

call :check_should_run "clockwork_quest_screenshot_test.dart"
if "!should_run!"=="1" (
    set /a test_count+=1
    echo ========================================
    echo [!test_count!] Clockwork Quest Screenshot Test
    echo ========================================
    echo File: clockwork_quest_screenshot_test.dart
    echo Tests: 1 test
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    REM Write to summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Clockwork Quest Screenshot Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: clockwork_quest_screenshot_test.dart >> integration_test_output\summary.txt
    echo Tests: 1 test >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    echo Starting ChromeDriver and Backend Server...
    if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!test_count!" >nul 2>&1
    call :start_services
    set _LOG=integration_test_output\30_clockwork_quest_screenshot.log
    set _TARGET=integration_test/clockwork_quest/clockwork_quest_screenshot_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/screenshot_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=($c -match 'All tests passed') -and (-not ($c -match 'Some tests failed'));break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    echo End Time: %date% %time% >> integration_test_output\summary.txt
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo Result: PASSED >> integration_test_output\summary.txt
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo Result: FAILED >> integration_test_output\summary.txt
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo. >> integration_test_output\summary.txt
    echo.
)

REM Generate summary
echo ========================================
echo Test Suite Complete
echo ========================================
echo.
echo Total Test Files: !test_count!
echo Passed: !pass_count!
echo Failed: !fail_count!
echo.

echo ======================================== >> integration_test_output\summary.txt
echo Test Suite Summary >> integration_test_output\summary.txt
echo ======================================== >> integration_test_output\summary.txt
echo Completed at %date% %time% >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo Total Test Files: !test_count! >> integration_test_output\summary.txt
echo Passed: !pass_count! >> integration_test_output\summary.txt
echo Failed: !fail_count! >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt

echo Results saved to integration_test_output folder
echo Summary: integration_test_output\summary.txt
echo.

echo Stopping ChromeDriver, Chrome, and Backend Server...
call :kill_services
REM Preserve last test's data for investigation
set /a _last_test=!test_count!+1
if exist "ui_test_data" move "ui_test_data" "integration_test_output\test_data_!_last_test!_final" >nul 2>&1
echo ChromeDriver and Backend Server stopped
echo.

if !fail_count! gtr 0 (
    echo WARNING: !fail_count! test file^(s^) failed. Check log files for details.
    exit /b 1
) else (
    echo SUCCESS: All test files passed!
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
echo   run_ui_tests.bat [test_file1] [test_file2] ... [test_fileN]
echo   run_ui_tests.bat /?
echo   run_ui_tests.bat /help
echo.
echo DESCRIPTION:
echo   Runs UI automation tests for the Dart Games application.
echo   By default, runs all 30 test files (272 total tests, ~173 minutes).
echo   You can optionally specify which test files to run.
echo.
echo PARAMETERS:
echo   test_file    Name of test file(s) to run. You can specify one or more files.
echo                File names are case-insensitive and can be partial matches.
echo   /?, /help    Show this help message
echo.
echo AVAILABLE TEST FILES:
echo   1. target_tag_menu_and_mechanics_test.dart    (24 tests, ~12 min)
echo   2. target_tag_visual_validation_test.dart     (4 tests,  ~2 min)
echo   3. target_tag_gameplay_test.dart              (13 tests, ~10 min)
echo   4. target_tag_add_player_test.dart            (6 tests,  ~2 min)
echo   5. target_tag_results_screen_test.dart        (6 tests,  ~5.5 min)
echo   6. carnival_derby_ui_test.dart                (24 tests, ~12 min)
echo   7. monster_mash_add_player_test.dart          (6 tests,  ~4 min)
echo   8. monster_mash_menu_and_settings_test.dart   (8 tests,  ~6 min)
echo   9. monster_mash_gameplay_test.dart            (20 tests, ~15 min)
echo  10. monster_mash_edit_score_test.dart           (5 tests,  ~5 min)
echo  11. monster_mash_results_screen_test.dart       (6 tests,  ~5 min)
echo  12. monster_mash_visual_validation_test.dart    (6 tests,  ~5 min)
echo  13. reef_royale_add_player_test.dart            (6 tests,  ~4 min)
echo  14. reef_royale_menu_and_settings_test.dart     (10 tests, ~6 min)
echo  15. reef_royale_gameplay_test.dart              (30 tests, ~12 min)
echo  16. reef_royale_edit_score_test.dart            (6 tests,  ~5 min)
echo  17. reef_royale_results_screen_test.dart        (6 tests,  ~5 min)
echo  18. reef_royale_visual_validation_test.dart     (7 tests,  ~5 min)
echo  19. reef_royale_showcase_test.dart              (1 test,   ~3 min)
echo  20. carnival_derby_save_resume_test.dart        (9 tests,  ~8 min)
echo  21. target_tag_save_resume_test.dart            (9 tests,  ~8 min)
echo  22. monster_mash_save_resume_test.dart          (9 tests,  ~8 min)
echo  23. reef_royale_save_resume_test.dart           (9 tests,  ~8 min)
echo  24. clockwork_quest_add_player_test.dart        (10 tests, ~4 min)
echo  25. clockwork_quest_menu_and_settings_test.dart (20 tests, ~7 min)
echo  26. clockwork_quest_gameplay_test.dart          (36 tests, ~17 min)
echo  27. clockwork_quest_edit_score_test.dart        (11 tests, ~6 min)
echo  28. clockwork_quest_results_test.dart           (11 tests, ~9 min)
echo  29. clockwork_quest_save_resume_test.dart       (16 tests, ~10 min)
echo  30. clockwork_quest_screenshot_test.dart        (1 test,   ~4 min)
echo.
echo EXAMPLES:
echo   Run all tests (default):
echo     run_ui_tests.bat
echo.
echo   Run only Target Tag Menu and Mechanics test:
echo     run_ui_tests.bat target_tag_menu_and_mechanics_test.dart
echo.
echo   Run only Carnival Derby test:
echo     run_ui_tests.bat carnival_derby_ui_test.dart
echo.
echo   Run multiple specific tests:
echo     run_ui_tests.bat target_tag_menu_and_mechanics_test.dart carnival_derby_ui_test.dart
echo.
echo   Partial file names also work (case-insensitive):
echo     run_ui_tests.bat menu_and_mechanics
echo     run_ui_tests.bat gameplay
echo     run_ui_tests.bat carnival
echo.
echo   Run all Monster Mash tests:
echo     run_ui_tests.bat monster_mash
echo.
echo   Run all Reef Royale tests:
echo     run_ui_tests.bat reef_royale
echo.
echo   Run all Clockwork Quest tests:
echo     run_ui_tests.bat clockwork_quest
echo.
echo   Run all Target Tag tests:
echo     run_ui_tests.bat target_tag_menu target_tag_visual target_tag_gameplay target_tag_add target_tag_results
echo.
echo NOTES:
echo   - ChromeDriver must be installed at chromedriver\chromedriver-win64\chromedriver.exe
echo   - Test results are saved to integration_test_output folder
echo   - Each test file runs in a clean ChromeDriver and Backend Server session
echo   - Chrome is automatically killed after each test to prevent hangs
echo   - Backend Server uses isolated test data directory (ui_test_data)
echo   - Summary of all tests (with detailed timings) saved to integration_test_output\summary.txt
echo.
exit /b 0
