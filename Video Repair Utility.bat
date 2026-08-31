@echo off
title Video Repair Utility
cd /d "%~dp0"

:: Check for override arguments
if /i "%1"=="/ps" goto :POWERSHELL
if /i "%1"=="/py" goto :PYTHON

:: Smart detection: Check if Python is available
python --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    goto :PYTHON
) else (
    goto :POWERSHELL
)

:PYTHON
echo Starting Video Repair Utility (Python)...
python "video_repair_utility.py"
if %ERRORLEVEL% neq 0 (
    echo.
    echo Python failed to start. Falling back to PowerShell...
    goto :POWERSHELL
)
goto :END

:POWERSHELL
echo Starting Video Repair Utility (PowerShell)...
PowerShell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "Video Repair Utility.ps1"
goto :END

:END
