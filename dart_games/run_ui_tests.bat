@echo off
setlocal enabledelayedexpansion

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
echo Running UI Automation Tests (76 tests, ~43 minutes)
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

REM ----------------------------------------------------------
REM Test 1: Target Tag Menu and Mechanics
REM ----------------------------------------------------------
set /a test_count+=1
echo [!test_count!/6] Running Target Tag Menu and Mechanics Test (23 tests, ~12 min)...
echo Starting ChromeDriver...
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
timeout /t 5 /nobreak >nul
set _LOG=integration_test_output\01_target_tag_menu_and_mechanics.log
set _TARGET=integration_test/target_tag_menu_and_mechanics_test.dart
echo Running: !_TARGET! > !_LOG!
echo Started at %time% >> !_LOG!
echo. >> !_LOG!
start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(!$done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
if !errorlevel! equ 0 (
    echo PASSED >> !_LOG! 2>nul
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> !_LOG! 2>nul
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> !_LOG! 2>nul
echo.
echo Restarting ChromeDriver for next test...
taskkill /F /IM chromedriver.exe >nul 2>&1
timeout /t 3 /nobreak >nul

REM ----------------------------------------------------------
REM Test 2: Target Tag Visual Validation
REM ----------------------------------------------------------
set /a test_count+=1
echo [!test_count!/6] Running Target Tag Visual Validation Test (4 tests, ~2 min)...
echo Starting ChromeDriver...
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
timeout /t 5 /nobreak >nul
set _LOG=integration_test_output\02_target_tag_visual_validation.log
set _TARGET=integration_test/target_tag_visual_validation_test.dart
echo Running: !_TARGET! > !_LOG!
echo Started at %time% >> !_LOG!
echo. >> !_LOG!
start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(!$done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
if !errorlevel! equ 0 (
    echo PASSED >> !_LOG! 2>nul
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> !_LOG! 2>nul
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> !_LOG! 2>nul
echo.
echo Restarting ChromeDriver for next test...
taskkill /F /IM chromedriver.exe >nul 2>&1
timeout /t 3 /nobreak >nul

REM ----------------------------------------------------------
REM Test 3: Target Tag Gameplay
REM ----------------------------------------------------------
set /a test_count+=1
echo [!test_count!/6] Running Target Tag Gameplay Test (13 tests, ~10 min)...
echo Starting ChromeDriver...
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
timeout /t 5 /nobreak >nul
set _LOG=integration_test_output\03_target_tag_gameplay.log
set _TARGET=integration_test/target_tag_gameplay_test.dart
echo Running: !_TARGET! > !_LOG!
echo Started at %time% >> !_LOG!
echo. >> !_LOG!
start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(!$done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
if !errorlevel! equ 0 (
    echo PASSED >> !_LOG! 2>nul
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> !_LOG! 2>nul
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> !_LOG! 2>nul
echo.
echo Restarting ChromeDriver for next test...
taskkill /F /IM chromedriver.exe >nul 2>&1
timeout /t 3 /nobreak >nul

REM ----------------------------------------------------------
REM Test 4: Target Tag Add Player
REM ----------------------------------------------------------
set /a test_count+=1
echo [!test_count!/6] Running Target Tag Add Player Test (6 tests, ~2 min)...
echo Starting ChromeDriver...
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
timeout /t 5 /nobreak >nul
set _LOG=integration_test_output\04_target_tag_add_player.log
set _TARGET=integration_test/target_tag_add_player_test.dart
echo Running: !_TARGET! > !_LOG!
echo Started at %time% >> !_LOG!
echo. >> !_LOG!
start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(!$done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
if !errorlevel! equ 0 (
    echo PASSED >> !_LOG! 2>nul
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> !_LOG! 2>nul
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> !_LOG! 2>nul
echo.
echo Restarting ChromeDriver for next test...
taskkill /F /IM chromedriver.exe >nul 2>&1
timeout /t 3 /nobreak >nul

REM ----------------------------------------------------------
REM Test 5: Target Tag Results Screen
REM ----------------------------------------------------------
set /a test_count+=1
echo [!test_count!/6] Running Target Tag Results Screen Test (6 tests, ~5.5 min)...
echo Starting ChromeDriver...
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
timeout /t 5 /nobreak >nul
set _LOG=integration_test_output\05_target_tag_results_screen.log
set _TARGET=integration_test/target_tag_results_screen_test.dart
echo Running: !_TARGET! > !_LOG!
echo Started at %time% >> !_LOG!
echo. >> !_LOG!
start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(!$done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
if !errorlevel! equ 0 (
    echo PASSED >> !_LOG! 2>nul
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> !_LOG! 2>nul
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> !_LOG! 2>nul
echo.
echo Restarting ChromeDriver for next test...
taskkill /F /IM chromedriver.exe >nul 2>&1
timeout /t 3 /nobreak >nul

REM ----------------------------------------------------------
REM Test 6: Carnival Derby UI
REM ----------------------------------------------------------
set /a test_count+=1
echo [!test_count!/6] Running Carnival Derby UI Test (24 tests, ~12 min)...
echo Starting ChromeDriver...
start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1
timeout /t 5 /nobreak >nul
set _LOG=integration_test_output\06_carnival_derby_ui.log
set _TARGET=integration_test/carnival_derby_ui_test.dart
echo Running: !_TARGET! > !_LOG!
echo Started at %time% >> !_LOG!
echo. >> !_LOG!
start /B "" cmd /C "flutter drive --driver=test_driver/integration_test.dart --target=!_TARGET! -d chrome >> !_LOG! 2>&1"
powershell -NoProfile -Command "$log='!_LOG!';$done=$false;$elapsed=0;while(!$done -and $elapsed -lt 1800){Start-Sleep 3;$elapsed+=3;try{$c=[System.IO.File]::ReadAllText($log);if($c -match 'All tests passed|Some tests failed|Application finished'){$done=$true}}catch{}};Start-Sleep 10;Get-Process chrome -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue;Start-Sleep 10;$found=$false;for($i=0;$i -lt 30;$i++){try{$c=[System.IO.File]::ReadAllText($log);$found=$c -match 'All tests passed';break}catch{Start-Sleep 1}};exit $(if($found){0}else{1})"
if !errorlevel! equ 0 (
    echo PASSED >> !_LOG! 2>nul
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> !_LOG! 2>nul
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> !_LOG! 2>nul
echo.

REM Generate summary
echo ========================================
echo Test Suite Complete
echo ========================================
echo.
echo Total Tests: 6
echo Passed: !pass_count!
echo Failed: !fail_count!
echo.

echo ======================================== >> integration_test_output\summary.txt
echo Test Suite Summary >> integration_test_output\summary.txt
echo ======================================== >> integration_test_output\summary.txt
echo Completed at %date% %time% >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo Total Test Files: 6 >> integration_test_output\summary.txt
echo Passed: !pass_count! >> integration_test_output\summary.txt
echo Failed: !fail_count! >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo Test Results: >> integration_test_output\summary.txt
echo   1. Target Tag Menu and Mechanics (23 tests) >> integration_test_output\summary.txt
echo   2. Target Tag Visual Validation (4 tests) >> integration_test_output\summary.txt
echo   3. Target Tag Gameplay (13 tests) >> integration_test_output\summary.txt
echo   4. Target Tag Add Player (6 tests) >> integration_test_output\summary.txt
echo   5. Target Tag Results Screen (6 tests) >> integration_test_output\summary.txt
echo   6. Carnival Derby UI (24 tests) >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo Total UI Tests: 76 tests >> integration_test_output\summary.txt
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
