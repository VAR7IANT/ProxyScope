@echo off
setlocal EnableExtensions
title ProxyScope

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "PROXYSCOPE_ROOT=%~dp0"
set "SCRIPT=%PROXYSCOPE_ROOT%src\ProxyScope.ps1"

if not exist "%SCRIPT%" (
    echo.
    echo ERROR: Main script not found
    echo Expected path:
    echo %SCRIPT%
    echo.
    pause
    exit /b 1
)

echo Preparing PowerShell source encoding...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $utf8Bom=New-Object System.Text.UTF8Encoding($true); Get-ChildItem -LiteralPath (Join-Path $env:PROXYSCOPE_ROOT 'src') -Filter '*.ps1' -Recurse -File | ForEach-Object { $text=[System.IO.File]::ReadAllText($_.FullName,[System.Text.Encoding]::UTF8); [System.IO.File]::WriteAllText($_.FullName,$text,$utf8Bom) }"

if not "%errorlevel%"=="0" (
    echo.
    echo ERROR: Failed to prepare PowerShell source files
    echo Make sure the extracted project folder is writable
    echo.
    pause
    exit /b 1
)

echo Validating PowerShell syntax...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$failed=$false; Get-ChildItem -LiteralPath (Join-Path $env:PROXYSCOPE_ROOT 'src') -Filter '*.ps1' -Recurse -File | ForEach-Object { $tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors) | Out-Null; if($errors.Count -gt 0){ $failed=$true; Write-Host ('ERROR in ' + $_.FullName) -ForegroundColor Red; $errors | ForEach-Object { Write-Host ('  Line ' + $_.Extent.StartLineNumber + ': ' + $_.Message) -ForegroundColor Red } } }; if($failed){ exit 2 }"

if not "%errorlevel%"=="0" (
    echo.
    echo ERROR: PowerShell source validation failed
    echo Download the latest clean copy of ProxyScope and try again
    echo.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

if not "%errorlevel%"=="0" (
    echo.
    echo ProxyScope exited with an error
    echo Review the error message above or open a GitHub issue
    echo.
    pause
    exit /b 1
)
