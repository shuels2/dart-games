@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Python Dependency Check - check_python_deps.bat
REM ============================================================
REM Ensures Python 3 + mediapipe/opencv-python/pillow/numpy are
REM available for the server's Python sidecar (Treasure Divide
REM face-landmarks feature).
REM
REM Fast path: if .python_deps_verified sentinel exists at the
REM repo root, exits 0 immediately (single file-existence check,
REM nearly free).
REM
REM Manual re-verify: delete .python_deps_verified and re-run.
REM
REM Usage (from any runner script):
REM   call "%~dp0check_python_deps.bat"
REM   if errorlevel 1 exit /b 1
REM ============================================================

REM Always resolve the sentinel relative to this script's own
REM directory so it works regardless of the caller's cwd.
set "_HELPER_DIR=%~dp0"
if "!_HELPER_DIR:~-1!"=="\" set "_HELPER_DIR=!_HELPER_DIR:~0,-1!"
set "_SENTINEL=!_HELPER_DIR!\.python_deps_verified"

REM ============================================================
REM Fast path: sentinel already written by a previous successful run
REM ============================================================
if exist "!_SENTINEL!" (
    endlocal
    exit /b 0
)

echo.
echo ============================================================
echo  Python Dependency Check
echo ============================================================

REM ============================================================
REM Step 1: Locate a real Python interpreter
REM ============================================================
set "_PY_CMD="

REM --- Try the py.exe launcher first (preferred on Windows) ---
where py >nul 2>&1
if !errorlevel! equ 0 (
    py --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "_PY_CMD=py"
        echo   Found: py launcher
        goto :python_found
    )
)

REM --- Try `python` but reject the Windows Store alias ---
where python >nul 2>&1
if !errorlevel! equ 0 (
    for /f "usebackq tokens=*" %%P in (`python -c "import sys; print(sys.executable)" 2^>nul`) do (
        set "_py_exe=%%P"
    )
    if not "!_py_exe!"=="" (
        REM Reject anything under the WindowsApps Store shim path
        echo !_py_exe! | findstr /i "WindowsApps" >nul 2>&1
        if !errorlevel! neq 0 (
            set "_PY_CMD=python"
            echo   Found: python at !_py_exe!
            goto :python_found
        ) else (
            echo   Skipping Windows Store alias: !_py_exe!
        )
    )
)

REM --- Try `python3` but reject the Windows Store alias ---
where python3 >nul 2>&1
if !errorlevel! equ 0 (
    for /f "usebackq tokens=*" %%P in (`python3 -c "import sys; print(sys.executable)" 2^>nul`) do (
        set "_py_exe=%%P"
    )
    if not "!_py_exe!"=="" (
        echo !_py_exe! | findstr /i "WindowsApps" >nul 2>&1
        if !errorlevel! neq 0 (
            set "_PY_CMD=python3"
            echo   Found: python3 at !_py_exe!
            goto :python_found
        ) else (
            echo   Skipping Windows Store alias: !_py_exe!
        )
    )
)

REM ============================================================
REM No real Python found
REM ============================================================
echo.
echo ============================================================
echo  ERROR: No real Python interpreter found on PATH.
echo ============================================================
echo.
echo  The server's Python sidecar (Treasure Divide face-landmarks)
echo  requires Python 3.9 or later.
echo.
echo  To fix:
echo    1. Download Python from https://www.python.org/downloads/
echo    2. During install, CHECK "Add python.exe to PATH"
echo    3. If you see a Windows Store "python" stub, disable it:
echo         Settings - Apps - Advanced app settings -
echo         App execution aliases - turn OFF python.exe / python3.exe
echo    4. Reopen this terminal and try again.
echo.
endlocal
exit /b 1

:python_found

REM ============================================================
REM Step 2: Test required imports
REM ============================================================
echo   Testing imports: mediapipe, cv2, PIL, numpy...
!_PY_CMD! -c "import mediapipe, cv2, PIL, numpy" >nul 2>&1
if !errorlevel! equ 0 goto :imports_ok

REM ============================================================
REM Step 3: Auto-install missing packages
REM ============================================================
echo   One or more packages missing. Installing...
echo   (Running: !_PY_CMD! -m pip install --user mediapipe opencv-python pillow numpy)
echo.

REM Verify pip is available before trying to use it
!_PY_CMD! -m pip --version >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo ============================================================
    echo  ERROR: pip is not available for the Python at '!_PY_CMD!'.
    echo ============================================================
    echo.
    echo  Python was found but pip is missing. Try:
    echo    !_PY_CMD! -m ensurepip --upgrade
    echo  or reinstall Python from https://www.python.org/downloads/
    echo  ^(make sure "pip" is selected in the optional features list^).
    echo.
    endlocal
    exit /b 1
)

!_PY_CMD! -m pip install --user mediapipe opencv-python pillow numpy
if !errorlevel! neq 0 (
    echo.
    echo ============================================================
    echo  ERROR: pip install failed ^(see output above^).
    echo ============================================================
    echo.
    echo  Things to try:
    echo    !_PY_CMD! -m pip install --upgrade pip
    echo    !_PY_CMD! -m pip install --user mediapipe opencv-python pillow numpy
    echo.
    endlocal
    exit /b 1
)

REM ============================================================
REM Step 4: Re-test imports after install
REM ============================================================
echo.
echo   Verifying installation...
!_PY_CMD! -c "import mediapipe, cv2, PIL, numpy" >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo ============================================================
    echo  ERROR: Packages installed but imports still fail.
    echo ============================================================
    echo.
    echo  This can happen when pip installs to a user site-packages
    echo  directory that the Python interpreter does not scan.
    echo  Things to try:
    echo    !_PY_CMD! -m pip install --upgrade pip
    echo    !_PY_CMD! -m pip install mediapipe opencv-python pillow numpy
    echo    ^(try without --user if the above fails^)
    echo.
    endlocal
    exit /b 1
)

:imports_ok

REM ============================================================
REM Write sentinel: timestamp + resolved command + mediapipe version
REM ============================================================
for /f "usebackq tokens=*" %%V in (`!_PY_CMD! -c "import mediapipe; print(mediapipe.__version__)" 2^>nul`) do set "_MP_VER=%%V"
(
    echo Verified: %date% %time%
    echo Python command: !_PY_CMD!
    echo mediapipe version: !_MP_VER!
) > "!_SENTINEL!"

echo   OK - mediapipe !_MP_VER! ready.
echo.
endlocal
exit /b 0
