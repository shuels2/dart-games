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
if not "%~1"=="" (
    set "run_all=0"
    :parse_args
    if "%~1"=="" goto :done_parsing
    set "file_list=!file_list! %~1"
    shift
    goto :parse_args
    :done_parsing
)

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

REM Kill any existing chromedriver/chrome processes
echo Stopping any existing ChromeDriver and Chrome instances...
taskkill /F /IM chromedriver.exe >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
timeout /t 2 /nobreak >nul

REM Verify chromedriver exists
if not exist "chromedriver\chromedriver-win64\chromedriver.exe" (
    echo ERROR: ChromeDriver not found at chromedriver\chromedriver-win64\chromedriver.exe
    echo Please ensure ChromeDriver is installed in the correct location.
    pause
    exit /b 1
)

REM Record start time
echo Test suite started at %date% %time% > integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt

set test_count=0
set pass_count=0
set fail_count=0

echo ========================================
if "!run_all!"=="1" (
    echo Running All UI Automation Tests (77 tests, ~51 minutes)
) else (
    echo Running Selected UI Automation Tests
)
echo ========================================
echo.
echo NOTE: ChromeDriver is restarted between each test suite for a
echo       clean session. Chrome is killed after each suite to unblock
echo       flutter drive which hangs due to GCM background threads.
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
REM   ChromeDriver is restarted between tests so each suite gets a
REM   clean WebDriver session.
REM ============================================================

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
REM Check if filename is in file_list
echo !file_list! | findstr /i /c:"%~1" >nul
if !errorlevel! equ 0 (
    set "should_run=1"
)
exit /b

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
    echo Expected Duration: ~12 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.
    echo Starting ChromeDriver...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
    timeout /t 5 /nobreak >nul
    set _LOG=integration_test_output\01_target_tag_menu_and_mechanics.log
    set _TARGET=integration_test/target_tag_menu_and_mechanics_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='%_LOG%';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo.
    echo Restarting ChromeDriver for next test...
    taskkill /F /IM chromedriver.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
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
    echo Expected Duration: ~2 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.
    echo Starting ChromeDriver...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
    timeout /t 5 /nobreak >nul
    set _LOG=integration_test_output\02_target_tag_visual_validation.log
    set _TARGET=integration_test/target_tag_visual_validation_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='%_LOG%';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo.
    echo Restarting ChromeDriver for next test...
    taskkill /F /IM chromedriver.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
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
    echo Expected Duration: ~10 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.
    echo Starting ChromeDriver...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
    timeout /t 5 /nobreak >nul
    set _LOG=integration_test_output\03_target_tag_gameplay.log
    set _TARGET=integration_test/target_tag_gameplay_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='%_LOG%';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo.
    echo Restarting ChromeDriver for next test...
    taskkill /F /IM chromedriver.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
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
    echo Expected Duration: ~2 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.
    echo Starting ChromeDriver...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
    timeout /t 5 /nobreak >nul
    set _LOG=integration_test_output\04_target_tag_add_player.log
    set _TARGET=integration_test/target_tag_add_player_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='%_LOG%';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo.
    echo Restarting ChromeDriver for next test...
    taskkill /F /IM chromedriver.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
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
    echo Expected Duration: ~5.5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.
    echo Starting ChromeDriver...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
    timeout /t 5 /nobreak >nul
    set _LOG=integration_test_output\05_target_tag_results_screen.log
    set _TARGET=integration_test/target_tag_results_screen_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='%_LOG%';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
    echo.
    echo Restarting ChromeDriver for next test...
    taskkill /F /IM chromedriver.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
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
    echo Expected Duration: ~12 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.
    echo Starting ChromeDriver...
    start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
    timeout /t 5 /nobreak >nul
    set _LOG=integration_test_output\06_carnival_derby_ui.log
    set _TARGET=integration_test/carnival_derby_ui_test.dart
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
    powershell -NoProfile -Command "$log='%_LOG%';$done=$false;$elapsed=0;while(-not $done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished|Failed to compile application'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
    echo End Time: %date% %time%
    if !errorlevel! equ 0 (
        echo Result: PASSED
        echo PASSED >> !_LOG! 2>nul
        set /a pass_count+=1
    ) else (
        echo Result: FAILED - Check log file for details
        echo FAILED >> !_LOG! 2>nul
        set /a fail_count+=1
    )
    echo Completed at %date% %time% >> !_LOG! 2>nul
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
echo Test Results: >> integration_test_output\summary.txt
echo   1. Target Tag Menu and Mechanics (24 tests) >> integration_test_output\summary.txt
echo   2. Target Tag Visual Validation (4 tests) >> integration_test_output\summary.txt
echo   3. Target Tag Gameplay (13 tests) >> integration_test_output\summary.txt
echo   4. Target Tag Add Player (6 tests) >> integration_test_output\summary.txt
echo   5. Target Tag Results Screen (6 tests) >> integration_test_output\summary.txt
echo   6. Carnival Derby UI (24 tests) >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo Total UI Tests: 77 tests >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo See individual log files for detailed results. >> integration_test_output\summary.txt

echo Results saved to integration_test_output folder
echo Summary: integration_test_output\summary.txt
echo.

echo Stopping ChromeDriver...
taskkill /F /IM chromedriver.exe >nul 2>&1
echo ChromeDriver stopped
echo.

if !fail_count! gtr 0 (
    echo WARNING: !fail_count! test file(s) failed. Check log files for details.
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
echo   By default, runs all 6 test files (77 total tests, ~51 minutes).
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
echo   Run all Target Tag tests:
echo     run_ui_tests.bat target_tag_menu target_tag_visual target_tag_gameplay target_tag_add target_tag_results
echo.
echo NOTES:
echo   - ChromeDriver must be installed at chromedriver\chromedriver-win64\chromedriver.exe
echo   - Test results are saved to integration_test_output folder
echo   - Each test file runs in a clean ChromeDriver session
echo   - Chrome is automatically killed after each test to prevent hangs
echo.
exit /b 0
