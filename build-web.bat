@echo off
rem Builds the game for the web with Emscripten, then opens it in your browser.
rem Double-click this file to run it. The web build is written to the build\web\Release folder:
rem upload the files in that folder (index.html, index.js, index.wasm and index.data) to any web host
rem (for example itch.io or GitHub Pages) to share your game.
rem
rem This runs the "web" preset of CMake (see CMakePresets.json and CMakeLists.txt), so the web build is set up in
rem one place. CMake and Ninja come with Visual Studio ("C++ CMake tools for Windows", part of the "Desktop
rem development with C++" workload): this script finds them there when they aren't on the PATH.
rem Emscripten is found, or installed the first time (see cmake\EmscriptenToolchain.cmake).
rem "build-web.bat --no-run" only builds (for automated builds).
setlocal
cd /d "%~dp0"

where cmake >nul 2>nul && where ninja >nul 2>nul && goto build
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -property installationPath`) do set "VSDIR=%%I"
if defined VSDIR set "VSCMAKE=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake"
rem Only add what is missing (at the end of the PATH), so a CMake that is on the PATH is still the one that runs.
if defined VSCMAKE where cmake >nul 2>nul || set "PATH=%PATH%;%VSCMAKE%\CMake\bin"
if defined VSCMAKE where ninja >nul 2>nul || set "PATH=%PATH%;%VSCMAKE%\Ninja"
where cmake >nul 2>nul && where ninja >nul 2>nul && goto build
echo CMake and Ninja were not found.
echo Open the Visual Studio Installer, click Modify, and add "C++ CMake tools for Windows"
echo (under "Desktop development with C++"), or install CMake and Ninja and add them to the PATH.
if /i not "%~1"=="--no-run" pause
exit /b 1

:build
echo Building the web version (the first build also downloads and builds SDL3, which takes a while)...
cmake --workflow --preset web
if errorlevel 1 (
    echo.
    echo The web build failed: see the errors above.
    if /i not "%~1"=="--no-run" pause
    exit /b 1
)

echo.
echo Done: build\web\Release\index.html
if /i "%~1"=="--no-run" exit /b 0
echo Opening it in your browser. Close this window to stop the local web server.
cmake --build --preset web-release --target run
