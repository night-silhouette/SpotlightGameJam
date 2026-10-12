@echo off
chcp 65001 >nul
title Godot 贴图规范化切片工具 (Tilemap Normalizer)

if "%~1"=="" (
    echo =======================================================
    echo   [用法说明]
    echo   直接把你的 PNG 贴图文件拖拽到这个 .bat 图标上即可！
    echo =======================================================
    echo.
    pause
    exit /b
)

echo 正在处理贴图文件: %~1
echo.

python "%~dp0normalizer.py" "%~1" 665

if errorlevel 1 (
    echo.
    echo [提示] 尝试使用内部 Python 解释器...
    "C:\Users\Napori\AppData\Local\hermes\tools\python-3.14.7+20240901-win32-x64\python.exe" "%~dp0normalizer.py" "%~1" 665
)

echo.
pause
