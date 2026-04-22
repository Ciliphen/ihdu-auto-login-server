@echo off
setlocal

REM Resolve this BAT file's directory so it can be launched from Task Scheduler.
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%run.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Cannot find "%PS_SCRIPT%".
    goto :fail
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo [ERROR] run.ps1 exited with code %EXIT_CODE%.
    goto :fail
)

echo [OK] run.ps1 completed.
goto :done

:fail
if /I "%~1"=="pause" pause
exit /b 1

:done
if /I "%~1"=="pause" pause
exit /b 0
