@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM STUB VERSION of run_ui_tests.bat
REM Tests the full control flow without running actual tests.
REM Each test simulates ~2 seconds then returns a result.
REM
REM To test the FAILED path, change "cmd /c exit 0" to
REM "cmd /c exit 1" for any test block below.
REM ============================================================

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
echo [STUB MODE - No real tests run]
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

REM Record start time
echo ======================================== > integration_test_output\summary.txt
echo Dart Games UI Automation Test Results >> integration_test_output\summary.txt
echo [STUB MODE] >> integration_test_output\summary.txt
echo ======================================== >> integration_test_output\summary.txt
echo Test suite started at %date% %time% >> integration_test_output\summary.txt
echo. >> integration_test_output\summary.txt

set test_count=0
set pass_count=0
set fail_count=0

echo ========================================
if "!run_all!"=="1" (
    echo Running All UI Automation Tests ^(STUB - ~24 seconds^)
) else (
    echo Running Selected UI Automation Tests ^(STUB^)
)
echo ========================================
echo.
echo NOTE: STUB MODE - flutter drive is simulated. Each test
echo       completes in ~2 seconds with a mocked PASSED result.
echo.

REM Skip over helper function definitions
goto :start_tests

REM ============================================================
REM Helper function to check if a file should run
REM ============================================================
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
    echo Expected Duration: ~12 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Menu and Mechanics Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_menu_and_mechanics_test.dart >> integration_test_output\summary.txt
    echo Tests: 24 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~12 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\01_target_tag_menu_and_mechanics.log
    set _TARGET=integration_test/target_tag_menu_and_mechanics_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +25: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Visual Validation Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_visual_validation_test.dart >> integration_test_output\summary.txt
    echo Tests: 4 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~2 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\02_target_tag_visual_validation.log
    set _TARGET=integration_test/target_tag_visual_validation_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +5: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Gameplay Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_gameplay_test.dart >> integration_test_output\summary.txt
    echo Tests: 13 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~10 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\03_target_tag_gameplay.log
    set _TARGET=integration_test/target_tag_gameplay_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +14: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Add Player Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_add_player_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~2 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\04_target_tag_add_player.log
    set _TARGET=integration_test/target_tag_add_player_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +7: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Target Tag Results Screen Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: target_tag_results_screen_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5.5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\05_target_tag_results_screen.log
    set _TARGET=integration_test/target_tag_results_screen_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +7: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Carnival Derby UI Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: carnival_derby_ui_test.dart >> integration_test_output\summary.txt
    echo Tests: 24 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~12 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\06_carnival_derby_ui.log
    set _TARGET=integration_test/carnival_derby_ui_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +25: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Add Player Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_add_player_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\07_monster_mash_add_player.log
    set _TARGET=integration_test/monster_mash_add_player_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +7: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~6 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Menu and Settings Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_menu_and_settings_test.dart >> integration_test_output\summary.txt
    echo Tests: 8 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~6 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\08_monster_mash_menu_and_settings.log
    set _TARGET=integration_test/monster_mash_menu_and_settings_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +9: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~15 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Gameplay Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_gameplay_test.dart >> integration_test_output\summary.txt
    echo Tests: 20 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~15 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\09_monster_mash_gameplay.log
    set _TARGET=integration_test/monster_mash_gameplay_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +21: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Edit Score Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_edit_score_test.dart >> integration_test_output\summary.txt
    echo Tests: 5 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\10_monster_mash_edit_score.log
    set _TARGET=integration_test/monster_mash_edit_score_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +6: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Results Screen Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_results_screen_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\11_monster_mash_results_screen.log
    set _TARGET=integration_test/monster_mash_results_screen_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +7: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Monster Mash Visual Validation Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: monster_mash_visual_validation_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\12_monster_mash_visual_validation.log
    set _TARGET=integration_test/monster_mash_visual_validation_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +7: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~4 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Add Player Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_add_player_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~4 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\13_reef_royale_add_player.log
    set _TARGET=integration_test/reef_royale_add_player_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +7: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~6 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Menu and Settings Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_menu_and_settings_test.dart >> integration_test_output\summary.txt
    echo Tests: 10 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~6 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\14_reef_royale_menu_and_settings.log
    set _TARGET=integration_test/reef_royale_menu_and_settings_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +9: All tests passed! >> !_LOG!
    cmd /c exit 0

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

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Gameplay Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_gameplay_test.dart >> integration_test_output\summary.txt
    echo Tests: 25 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~12 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\15_reef_royale_gameplay.log
    set _TARGET=integration_test/reef_royale_gameplay_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +26: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Edit Score Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_edit_score_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\16_reef_royale_edit_score.log
    set _TARGET=integration_test/reef_royale_edit_score_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +5: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Results Screen Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_results_screen_test.dart >> integration_test_output\summary.txt
    echo Tests: 6 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\17_reef_royale_results_screen.log
    set _TARGET=integration_test/reef_royale_results_screen_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +6: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~5 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Visual Validation Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_visual_validation_test.dart >> integration_test_output\summary.txt
    echo Tests: 7 tests >> integration_test_output\summary.txt
    echo Expected Duration: ~5 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\18_reef_royale_visual_validation.log
    set _TARGET=integration_test/reef_royale_visual_validation_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +6: All tests passed! >> !_LOG!
    cmd /c exit 0

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
    echo Expected Duration: ~3 minutes
    echo Start Time: %date% %time%
    echo ========================================
    echo.

    echo ======================================== >> integration_test_output\summary.txt
    echo [!test_count!] Reef Royale Showcase Test >> integration_test_output\summary.txt
    echo ======================================== >> integration_test_output\summary.txt
    echo File: reef_royale_showcase_test.dart >> integration_test_output\summary.txt
    echo Tests: 1 test >> integration_test_output\summary.txt
    echo Expected Duration: ~3 minutes >> integration_test_output\summary.txt
    echo Start Time: %date% %time% >> integration_test_output\summary.txt

    set _LOG=integration_test_output\19_reef_royale_showcase.log
    set _TARGET=integration_test/reef_royale_showcase_test.dart
    echo [STUB] Simulating: flutter drive --target=!_TARGET!
    echo Running: !_TARGET! > !_LOG!
    echo Started at %date% %time% >> !_LOG!
    echo. >> !_LOG!
    echo [STUB] Simulating test execution... >> !_LOG!
    timeout /t 2 /nobreak >nul
    echo +2: All tests passed! >> !_LOG!
    cmd /c exit 0

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
echo [STUB MODE]
echo ========================================
echo.
echo USAGE:
echo   run_ui_tests_stub.bat [test_file1] [test_file2] ... [test_fileN]
echo   run_ui_tests_stub.bat /?
echo.
echo DESCRIPTION:
echo   Stub version of run_ui_tests.bat. Tests the full control flow
echo   (arg parsing, test selection, result tracking, summary output)
echo   without running actual flutter drive tests. Completes in ~24 seconds.
echo.
echo   To test the FAILED path, edit this file and change
echo   "cmd /c exit 0" to "cmd /c exit 1" for any test block.
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
echo  15. reef_royale_gameplay_test.dart              (25 tests, ~12 min)
echo  16. reef_royale_edit_score_test.dart            (6 tests,  ~5 min)
echo  17. reef_royale_results_screen_test.dart        (6 tests,  ~5 min)
echo  18. reef_royale_visual_validation_test.dart     (7 tests,  ~5 min)
echo  19. reef_royale_showcase_test.dart              (1 test,   ~3 min)
echo.
echo EXAMPLES:
echo   Run all tests (stub):
echo     run_ui_tests_stub.bat
echo.
echo   Run only Carnival Derby test (stub):
echo     run_ui_tests_stub.bat carnival_derby_ui_test.dart
echo.
echo   Partial file names also work (case-insensitive):
echo     run_ui_tests_stub.bat menu_and_mechanics
echo     run_ui_tests_stub.bat gameplay
echo     run_ui_tests_stub.bat carnival
echo.
echo   Run all Reef Royale tests:
echo     run_ui_tests_stub.bat reef_royale
echo.
echo   Run all Monster Mash tests:
echo     run_ui_tests_stub.bat monster_mash
echo.
echo   Run all Target Tag tests:
echo     run_ui_tests_stub.bat target_tag
echo.
echo   Run multiple specific tests:
echo     run_ui_tests_stub.bat reef_royale_gameplay reef_royale_menu
echo.
echo NOTES:
echo   - Test results are saved to integration_test_output folder
echo   - Summary saved to integration_test_output\summary.txt
echo.
exit /b 0
