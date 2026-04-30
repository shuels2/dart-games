@echo off
REM ============================================================
REM STUB VERSION of run_ui_tests_parallel.bat
REM ============================================================
REM Tests the full parallel orchestration without running actual
REM tests, ChromeDriver, or backend servers.
REM Workers simulate 1-second test execution with mocked results.
REM
REM To simulate failures: set STUB_FAIL=1 before running.
REM   set STUB_FAIL=1
REM   run_ui_tests_parallel_stub.bat
REM ============================================================

set STUB_MODE=1
call "%~dp0run_ui_tests_parallel.bat" %*
exit /b %errorlevel%
