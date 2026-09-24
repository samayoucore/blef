@echo off
cd /d "%~dp0"
if not exist BLEF.exe (
    powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath 'BLEF-engine.zip' -DestinationPath '.' -Force"
    if errorlevel 1 exit /b 1
)
if not exist BLEF.pck (
    echo BLEF.pck is missing.
    exit /b 1
)
start "" "BLEF.exe"
