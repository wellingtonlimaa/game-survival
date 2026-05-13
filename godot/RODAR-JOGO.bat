@echo off
chcp 65001 >nul
title Noite dos Sobreviventes
echo ============================================
echo   Noite dos Sobreviventes
echo ============================================
echo.

set "GODOT_EXE=C:\Users\Lucas Santos\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.2-stable_win64.exe"
set "PROJ_DIR=%~dp0"
if "%PROJ_DIR:~-1%"=="\" set "PROJ_DIR=%PROJ_DIR:~0,-1%"

echo Godot: %GODOT_EXE%
echo Projeto: %PROJ_DIR%
echo.

if not exist "%GODOT_EXE%" (
    echo [ERRO] Godot nao encontrado!
    echo.
    pause
    exit /b 1
)

if not exist "%PROJ_DIR%\project.godot" (
    echo [ERRO] project.godot nao encontrado em "%PROJ_DIR%"
    echo.
    pause
    exit /b 1
)

echo Abrindo o jogo...
"%GODOT_EXE%" --path "%PROJ_DIR%"
echo.
echo Jogo encerrado (codigo: %errorlevel%)
echo Pressione qualquer tecla para fechar esta janela...
pause >nul
