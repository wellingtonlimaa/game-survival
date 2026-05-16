@echo off
title Noite dos Sobreviventes
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0setup-and-run.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Algo deu errado. Veja a mensagem acima.
    pause
)
