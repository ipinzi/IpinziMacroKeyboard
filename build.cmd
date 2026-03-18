@echo off
REM Build script wrapper for IpinziMacroKeyboard
REM This allows the build to be run by double-clicking or from command line

setlocal enabledelayedexpansion

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

REM Control whether to pause at the end (default: yes)
set "PAUSE_ON_EXIT=1"
if /I "%~1"=="/nopause" (
    set "PAUSE_ON_EXIT=0"
    shift
)

REM Prompt for version (required)
if "%~1"=="" (
    set /p "BUILD_VERSION=Enter version (e.g. 0.1.0): "
) else (
    set "BUILD_VERSION=%~1"
    shift
)

if "%BUILD_VERSION%"=="" (
    echo ERROR: Version is required.
    exit /b 1
)

REM Run the PowerShell build script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build.ps1" -Version "%BUILD_VERSION%" %*

REM Preserve exit code
set "EXIT_CODE=%ERRORLEVEL%"

if "%PAUSE_ON_EXIT%"=="1" (
    echo.
    pause
)

exit /b %EXIT_CODE%
