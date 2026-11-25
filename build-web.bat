@echo off
rem Builds the game for the web with Emscripten, then opens it in your browser.
rem Double-click this file to run it. The web build is written to the web-build folder:
rem upload the files in that folder to any web host (for example itch.io or GitHub Pages) to share your game.
rem
rem You need Emscripten (the emsdk) once: https://emscripten.org/docs/getting_started/downloads.html
rem This script finds it on the PATH, in the EMSDK environment variable, in C:\emsdk, or next to this folder.
setlocal
cd /d "%~dp0"

where em++ >nul 2>nul && goto build
if not defined EMSDK if exist "C:\emsdk\emsdk_env.bat" set "EMSDK=C:\emsdk"
if not defined EMSDK if exist "%~dp0..\emsdk\emsdk_env.bat" set "EMSDK=%~dp0..\emsdk"
if not defined EMSDK (
    echo Emscripten was not found.
    echo Install the emsdk from https://emscripten.org/docs/getting_started/downloads.html
    echo to C:\emsdk, or set the EMSDK environment variable to the folder where you installed it.
    pause
    exit /b 1
)
call "%EMSDK%\emsdk_env.bat" >nul 2>nul

:build
echo Building the web version (the first build also downloads and builds SDL3, which takes a while)...
if not exist web-build mkdir web-build
rem The source files of the game: game.cpp, and every .cpp file in the src folder (and its subfolders).
set "SOURCES=game.cpp"
if exist src for /R src %%F in (*.cpp) do call set "SOURCES=%%SOURCES%% "%%F""
call em++ %SOURCES% tmpl8\template.cpp tmpl8\surface.cpp ^
    -I tmpl8 -I . -I lib\stb ^
    -std=c++23 -O2 ^
    --use-port=sdl3 ^
    --preload-file assets ^
    -sALLOW_MEMORY_GROWTH ^
    --shell-file tmpl8\web-shell.html ^
    -o web-build\index.html
if errorlevel 1 (
    echo.
    echo The web build failed: see the errors above.
    if /i not "%~1"=="--no-run" pause
    exit /b 1
)

echo.
echo Done: web-build\index.html
rem "build-web.bat --no-run" only builds (for automated builds).
if /i "%~1"=="--no-run" exit /b 0
rem A browser can't run the game from a file on disk (file://), so emrun serves it from a local web server.
echo Opening it in your browser. Close this window to stop the local web server.
call emrun --no_emrun_detect web-build\index.html
