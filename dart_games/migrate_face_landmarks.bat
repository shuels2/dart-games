@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Backfill face landmarks for existing player avatars.
REM ============================================================
REM Convenience wrapper around `dart run bin/migrate_face_landmarks.dart`.
REM
REM Usage:
REM   migrate_face_landmarks.bat              (incremental — only players whose
REM                                            face_landmarks is still NULL)
REM   migrate_face_landmarks.bat --all        (reprocess EVERY player with an
REM                                            avatar, overwriting existing
REM                                            landmarks — use when a better
REM                                            landmarker model is dropped in)
REM   migrate_face_landmarks.bat --data-dir D:\some\path  (override data dir)
REM
REM All flags after the script name are passed through to the Dart CLI as-is.
REM ============================================================

REM Anchor to the repo root so `check_python_deps.bat` and the server
REM working directory resolve correctly regardless of where the user
REM invoked us from.
cd /d "%~dp0"

REM Ensure Python + mediapipe are installed before invoking the CLI.
call "%~dp0check_python_deps.bat"
if errorlevel 1 (
    echo.
    echo  ERROR: Python / mediapipe check failed — cannot run migrator.
    exit /b 1
)

REM The Dart CLI lives in server\bin and uses relative paths.
cd server
dart run bin/migrate_face_landmarks.dart %*
set _exit=%errorlevel%
cd /d "%~dp0"
exit /b !_exit!
