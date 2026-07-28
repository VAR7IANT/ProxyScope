@echo off
setlocal EnableExtensions
title ProxyScope

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SCRIPT=%~dp0src\ProxyScope.ps1"

if not exist "%SCRIPT%" (
    echo.
    echo ERROR: Main script not found
    echo Expected path:
    echo %SCRIPT%
    echo.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
