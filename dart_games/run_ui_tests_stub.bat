@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM STUB VERSION of run_ui_tests.bat (Dynamic File Scanner)
REM Tests the full control flow without running actual tests.
REM Each test simulates ~1 second then returns PASSED.
REM
REM To test the FAILED path, set STUB_FAIL=1 before running.
REM ============================================================

if "%1"=="/?" goto :show_help
if "%1"=="/help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help

REM ============================================================
REM Parse command line arguments
REM ============================================================
set "filter="
set "run_all=1"

if not "%~1"=="" (
    set "run_all=0"
    set "filter=%*"
)

REM ============================================================
REM Start
REM ============================================================
echo ========================================
echo Dart Games UI Automation Test Runner
echo [STUB MODE - No real tests run]
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
    echo Running All UI Automation Tests ^(STUB^)
) else (
    echo Running Filtered UI Automation Tests ^(STUB^): !filter!
)
echo ========================================
echo.
echo NOTE: STUB MODE - flutter drive and Backend Server are simulated.
echo       Each test completes in ~1 second with a mocked result.
echo.

goto :discover_tests

REM ============================================================
REM Run a single test (stub version)
REM ============================================================
:run_single_test
set "_RST_TARGET=%~1"
set /a test_count+=1

set "_RST_LOGNAME=%_RST_TARGET:integration_test/=%"
set "_RST_LOGNAME=%_RST_LOGNAME:/=_%"
set "_RST_LOGNAME=%_RST_LOGNAME:\=_%"
set "_RST_LOGNAME=%_RST_LOGNAME:.dart=%"
set "_RST_LOG=integration_test_output\%_RST_LOGNAME%.log"

echo ----------------------------------------
echo [!test_count!] !_RST_TARGET!
echo Start: %time%

echo ---------------------------------------- >> integration_test_output\summary.txt
echo [!test_count!] !_RST_TARGET! >> integration_test_output\summary.txt
echo Start Time: %date% %time% >> integration_test_output\summary.txt

echo [STUB] Simulating: flutter drive --target=!_RST_TARGET! > "!_RST_LOG!"
echo Started at %date% %time% >> "!_RST_LOG!"
echo. >> "!_RST_LOG!"
timeout /t 1 /nobreak >nul
echo +1: All tests passed! >> "!_RST_LOG!"

REM Use STUB_FAIL env var to simulate failures
if defined STUB_FAIL (
    cmd /c exit 1
) else (
    cmd /c exit 0
)

echo End: %time%
echo End Time: %date% %time% >> integration_test_output\summary.txt
if !errorlevel! equ 0 (
    echo Result: PASSED
    echo Result: PASSED >> integration_test_output\summary.txt
    echo PASSED >> "!_RST_LOG!" 2>nul
    set /a pass_count+=1
) else (
    echo Result: FAILED
    echo Result: FAILED >> integration_test_output\summary.txt
    echo FAILED >> "!_RST_LOG!" 2>nul
    set /a fail_count+=1
)
echo Completed at %date% %time% >> "!_RST_LOG!" 2>nul
echo. >> integration_test_output\summary.txt
exit /b

REM ============================================================
REM DISCOVER AND RUN TESTS
REM ============================================================
:discover_tests

set "GAMES=target_tag carnival_derby monster_mash reef_royale clockwork_quest"

for %%G in (%GAMES%) do (
    set "_GAME=%%G"
    set "_GAME_DIR=integration_test\%%G"

    set "_game_matches=0"
    if "!run_all!"=="1" set "_game_matches=1"
    if "!_game_matches!"=="0" (
        echo %%G | findstr /i "!filter!" >nul 2>&1
        if !errorlevel! equ 0 set "_game_matches=1"
    )

    if "!_game_matches!"=="1" (
        echo.
        echo ========================================
        echo Game: %%G
        echo ========================================

        echo. >> integration_test_output\summary.txt
        echo ======================================== >> integration_test_output\summary.txt
        echo Game: %%G >> integration_test_output\summary.txt
        echo ======================================== >> integration_test_output\summary.txt

        echo [STUB] Starting services for %%G...

        REM Run test files directly in the game directory
        for %%F in ("!_GAME_DIR!\*_test.dart") do (
            set "_test_path=%%F"
            set "_test_path=!_test_path:\=/!"

            set "_file_matches=0"
            if "!run_all!"=="1" set "_file_matches=1"
            if "!_file_matches!"=="0" (
                echo !_test_path! | findstr /i "!filter!" >nul 2>&1
                if !errorlevel! equ 0 set "_file_matches=1"
            )

            if "!_file_matches!"=="1" (
                call :run_single_test "!_test_path!"
            )
        )

        REM Run test files in subdirectories
        for /d %%D in ("!_GAME_DIR!\*") do (
            set "_subdir_name=%%~nxD"

            set "_subdir_matches=0"
            if "!run_all!"=="1" set "_subdir_matches=1"
            if "!_subdir_matches!"=="0" (
                echo %%G/!_subdir_name! | findstr /i "!filter!" >nul 2>&1
                if !errorlevel! equ 0 set "_subdir_matches=1"
            )
            if "!_game_matches!"=="1" if "!run_all!"=="0" (
                echo %%G | findstr /i "!filter!" >nul 2>&1
                if !errorlevel! equ 0 set "_subdir_matches=1"
            )

            if "!_subdir_matches!"=="1" (
                for %%F in ("%%D\*_test.dart") do (
                    set "_test_path=%%F"
                    set "_test_path=!_test_path:\=/!"

                    set "_file_matches=0"
                    if "!run_all!"=="1" set "_file_matches=1"
                    if "!_file_matches!"=="0" (
                        echo !_test_path! | findstr /i "!filter!" >nul 2>&1
                        if !errorlevel! equ 0 set "_file_matches=1"
                    )
                    if "!_subdir_matches!"=="1" if "!run_all!"=="0" (
                        echo %%G/!_subdir_name! | findstr /i "!filter!" >nul 2>&1
                        if !errorlevel! equ 0 set "_file_matches=1"
                    )

                    if "!_file_matches!"=="1" (
                        call :run_single_test "!_test_path!"
                    )
                )
            )
        )

        echo.
        echo [STUB] Services stopped for %%G.
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
echo [STUB MODE]
echo ========================================
echo.
echo USAGE:
echo   run_ui_tests_stub.bat [filter1] [filter2] ...
echo   run_ui_tests_stub.bat /?
echo.
echo DESCRIPTION:
echo   Stub version of run_ui_tests.bat. Tests the full control flow
echo   (arg parsing, file discovery, result tracking, summary output)
echo   without running actual flutter drive tests or Backend Server.
echo   Automatically discovers test files, same as run_ui_tests.bat.
echo.
echo   To test the FAILED path, set STUB_FAIL=1 before running:
echo     set STUB_FAIL=1
echo     run_ui_tests_stub.bat
echo.
echo FILTERING:
echo   Without arguments, runs ALL test files.
echo   With arguments, runs only files whose path matches any filter.
echo.
echo EXAMPLES:
echo   Run all tests (stub):
echo     run_ui_tests_stub.bat
echo.
echo   Run all Target Tag tests:
echo     run_ui_tests_stub.bat target_tag
echo.
echo   Run only save/resume tests:
echo     run_ui_tests_stub.bat save_resume
echo.
echo   Run a specific category:
echo     run_ui_tests_stub.bat reef_royale/gameplay
echo.
echo NOTES:
echo   - Test results saved to integration_test_output\
echo   - Summary saved to integration_test_output\summary.txt
echo.
exit /b 0
