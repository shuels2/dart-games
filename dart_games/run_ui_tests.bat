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

REM Kill any existing chromedriver processes
echo Stopping any existing ChromeDriver instances...
taskkill /F /IM chromedriver.exe >nul 2>&1

REM Wait a moment for processes to terminate
timeout /t 2 /nobreak >nul

REM Start ChromeDriver in the background
echo Starting ChromeDriver on port 4444...
if not exist "chromedriver\chromedriver-win64\chromedriver.exe" (
    echo ERROR: ChromeDriver not found at chromedriver\chromedriver-win64\chromedriver.exe
    echo Please ensure ChromeDriver is installed in the correct location.
    pause
    exit /b 1
)

start /B "" "chromedriver\chromedriver-win64\chromedriver.exe" --port=4444 >nul 2>&1

REM Wait for ChromeDriver to initialize
echo Waiting for ChromeDriver to initialize...
timeout /t 5 /nobreak >nul

REM Verify ChromeDriver is running
netstat -ano | findstr ":4444" >nul
if %errorlevel% neq 0 (
    echo ERROR: ChromeDriver failed to start on port 4444
    echo Check if Chrome browser is installed or if port 4444 is blocked.
    pause
    exit /b 1
)

echo ChromeDriver started successfully on port 4444
echo.

REM Record start time
echo Test suite started at %date% %time% > integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt

REM Define test files array
set test_count=0
set pass_count=0
set fail_count=0

echo ========================================
echo Running UI Automation Tests (76 tests, ~43 minutes)
echo ========================================
echo.

REM Test 1: Target Tag Menu and Mechanics
set /a test_count+=1
echo [%test_count%/6] Running Target Tag Menu and Mechanics Test (23 tests, ~12 min)...
echo Running: target_tag_menu_and_mechanics_test.dart > integration_test_output\01_target_tag_menu_and_mechanics.log
echo Started at %time% >> integration_test_output\01_target_tag_menu_and_mechanics.log
echo. >> integration_test_output\01_target_tag_menu_and_mechanics.log
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_menu_and_mechanics_test.dart -d chrome >> integration_test_output\01_target_tag_menu_and_mechanics.log 2>&1
if %errorlevel% equ 0 (
    echo PASSED >> integration_test_output\01_target_tag_menu_and_mechanics.log
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> integration_test_output\01_target_tag_menu_and_mechanics.log
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> integration_test_output\01_target_tag_menu_and_mechanics.log
echo.

REM Test 2: Target Tag Visual Validation
set /a test_count+=1
echo [%test_count%/6] Running Target Tag Visual Validation Test (4 tests, ~2 min)...
echo Running: target_tag_visual_validation_test.dart > integration_test_output\02_target_tag_visual_validation.log
echo Started at %time% >> integration_test_output\02_target_tag_visual_validation.log
echo. >> integration_test_output\02_target_tag_visual_validation.log
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_visual_validation_test.dart -d chrome >> integration_test_output\02_target_tag_visual_validation.log 2>&1
if %errorlevel% equ 0 (
    echo PASSED >> integration_test_output\02_target_tag_visual_validation.log
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> integration_test_output\02_target_tag_visual_validation.log
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> integration_test_output\02_target_tag_visual_validation.log
echo.

REM Test 3: Target Tag Gameplay
set /a test_count+=1
echo [%test_count%/6] Running Target Tag Gameplay Test (13 tests, ~10 min)...
echo Running: target_tag_gameplay_test.dart > integration_test_output\03_target_tag_gameplay.log
echo Started at %time% >> integration_test_output\03_target_tag_gameplay.log
echo. >> integration_test_output\03_target_tag_gameplay.log
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_gameplay_test.dart -d chrome >> integration_test_output\03_target_tag_gameplay.log 2>&1
if %errorlevel% equ 0 (
    echo PASSED >> integration_test_output\03_target_tag_gameplay.log
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> integration_test_output\03_target_tag_gameplay.log
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> integration_test_output\03_target_tag_gameplay.log
echo.

REM Test 4: Target Tag Add Player
set /a test_count+=1
echo [%test_count%/6] Running Target Tag Add Player Test (6 tests, ~2 min)...
echo Running: target_tag_add_player_test.dart > integration_test_output\04_target_tag_add_player.log
echo Started at %time% >> integration_test_output\04_target_tag_add_player.log
echo. >> integration_test_output\04_target_tag_add_player.log
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome >> integration_test_output\04_target_tag_add_player.log 2>&1
if %errorlevel% equ 0 (
    echo PASSED >> integration_test_output\04_target_tag_add_player.log
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> integration_test_output\04_target_tag_add_player.log
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> integration_test_output\04_target_tag_add_player.log
echo.

REM Test 5: Target Tag Results Screen
set /a test_count+=1
echo [%test_count%/6] Running Target Tag Results Screen Test (6 tests, ~5.5 min)...
echo Running: target_tag_results_screen_test.dart > integration_test_output\05_target_tag_results_screen.log
echo Started at %time% >> integration_test_output\05_target_tag_results_screen.log
echo. >> integration_test_output\05_target_tag_results_screen.log
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_results_screen_test.dart -d chrome >> integration_test_output\05_target_tag_results_screen.log 2>&1
if %errorlevel% equ 0 (
    echo PASSED >> integration_test_output\05_target_tag_results_screen.log
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> integration_test_output\05_target_tag_results_screen.log
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> integration_test_output\05_target_tag_results_screen.log
echo.

REM Test 6: Carnival Derby UI
set /a test_count+=1
echo [%test_count%/6] Running Carnival Derby UI Test (24 tests, ~12 min)...
echo Running: carnival_derby_ui_test.dart > integration_test_output\06_carnival_derby_ui.log
echo Started at %time% >> integration_test_output\06_carnival_derby_ui.log
echo. >> integration_test_output\06_carnival_derby_ui.log
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/carnival_derby_ui_test.dart -d chrome >> integration_test_output\06_carnival_derby_ui.log 2>&1
if %errorlevel% equ 0 (
    echo PASSED >> integration_test_output\06_carnival_derby_ui.log
    echo   [PASSED]
    set /a pass_count+=1
) else (
    echo FAILED >> integration_test_output\06_carnival_derby_ui.log
    echo   [FAILED] - Check log file for details
    set /a fail_count+=1
)
echo Completed at %time% >> integration_test_output\06_carnival_derby_ui.log
echo.

REM Generate summary
echo ========================================
echo Test Suite Complete
echo ========================================
echo.
echo Total Tests: 6
echo Passed: %pass_count%
echo Failed: %fail_count%
echo.

REM Write summary to file
echo ======================================== >> integration_test_output\summary.txt
echo Test Suite Summary >> integration_test_output\summary.txt
echo ======================================== >> integration_test_output\summary.txt
echo Completed at %date% %time% >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt
echo Total Test Files: 6 >> integration_test_output\summary.txt
echo Passed: %pass_count% >> integration_test_output\summary.txt
echo Failed: %fail_count% >> integration_test_output\summary.txt
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

REM Stop ChromeDriver
echo Stopping ChromeDriver...
taskkill /F /IM chromedriver.exe >nul 2>&1
echo ChromeDriver stopped
echo.

if %fail_count% gtr 0 (
    echo WARNING: %fail_count% test file(s) failed. Check log files for details.
    exit /b 1
) else (
    echo SUCCESS: All test files passed!
    exit /b 0
)
