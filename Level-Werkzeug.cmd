@echo off
set "GODOT_EXE=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if exist "%GODOT_EXE%" (
  start "" "%GODOT_EXE%" --path "%~dp0." -- --editor-tool
  exit /b
)
where godot >nul 2>nul
if %errorlevel% equ 0 (
  start "" godot --path "%~dp0." -- --editor-tool
  exit /b
)
echo Godot nicht gefunden. Starte das Projekt mit: godot --path . -- --editor-tool
pause
