@echo off
chcp 65001 >nul
title Noite dos Sobreviventes
echo ============================================
echo   NOITE DOS SOBREVIVENTES
echo ============================================
echo.
echo Procurando o Godot...

set "PROJ_DIR=%~dp0"
if "%PROJ_DIR:~-1%"=="\" set "PROJ_DIR=%PROJ_DIR:~0,-1%"

set "GODOT_EXE="

rem 1) Godot no PATH
for /f "delims=" %%G in ('where godot 2^>nul') do (
    set "GODOT_EXE=%%G"
    goto :found
)

rem 2) Instalacao via winget
for /f "delims=" %%G in ('dir /b /s "%LOCALAPPDATA%\Microsoft\WinGet\Packages\Godot_v*.exe" 2^>nul ^| findstr /v "_console"') do (
    set "GODOT_EXE=%%G"
    goto :found
)

rem 3) Pastas comuns
for %%P in (
    "%LOCALAPPDATA%\Programs\Godot"
    "%ProgramFiles%\Godot"
    "%ProgramFiles(x86)%\Godot"
    "%USERPROFILE%\Downloads"
) do (
    for /f "delims=" %%G in ('dir /b /s "%%~P\Godot_v*.exe" 2^>nul ^| findstr /v "_console"') do (
        set "GODOT_EXE=%%G"
        goto :found
    )
)

echo.
echo [ERRO] Godot nao encontrado.
echo Rode o INICIAR.bat da pasta de cima - ele instala sozinho pelo winget.
echo Ou baixe em https://godotengine.org/download
echo.
pause
exit /b 1

:found
echo Godot: %GODOT_EXE%
echo Projeto: %PROJ_DIR%
echo.
if not exist "%PROJ_DIR%\project.godot" (
    echo [ERRO] project.godot nao encontrado em "%PROJ_DIR%"
    pause
    exit /b 1
)

echo Abrindo o jogo...
"%GODOT_EXE%" --path "%PROJ_DIR%"
echo.
echo Jogo encerrado (codigo: %errorlevel%)
pause >nul
