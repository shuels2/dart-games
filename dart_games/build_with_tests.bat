@echo off
REM Build script that runs dartboard tests before building

echo ========================================
echo Running Dartboard Segment Tests
echo ========================================
call flutter test test/dartboard_test.dart

if %ERRORLEVEL% neq 0 (
    echo.
    echo ========================================
    echo TESTS FAILED - Build aborted
    echo ========================================
    exit /b 1
)

echo.
echo ========================================
echo All tests passed! Proceeding with build
echo ========================================
echo.

REM Run the actual build
call flutter build %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo ========================================
    echo BUILD FAILED
    echo ========================================
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
