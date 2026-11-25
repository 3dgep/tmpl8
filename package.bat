@echo off
rem Builds the Release version of your game and packs it in a zip file that you can share: send it to friends,
rem upload it to itch.io, or hand it in. Double-click this file to run it (close the game first if it is running).
rem
rem The zip file is build\<name of your game>.zip, with a folder that contains:
rem   <name of your game>.exe, SDL3.dll, the assets folder and LICENSE-SDL3.txt.
rem Players unzip it and double-click the .exe: they don't need to install anything.
rem
rem "package.bat --web" packs the web version instead: build\<name of your game>-web.zip, with index.html,
rem index.js, index.wasm and index.data (the assets) at the top, ready to upload to itch.io as an HTML game.
rem "package.bat --no-open" doesn't show the zip file in Explorer (for automated builds).
rem
rem This runs the "windows-vs-package" (or "web-package") workflow of CMake (see CMakePresets.json, and the Packaging
rem section of CMakeLists.txt), so what goes in the zip file is set up in one place. CMake and Ninja come with Visual
rem Studio ("C++ CMake tools for Windows", part of the "Desktop development with C++" workload): this script finds
rem them there when they aren't on the PATH. The web version also needs Emscripten, which is found, or installed the
rem first time (see cmake\EmscriptenToolchain.cmake).
setlocal

rem The name of your game. Leave it empty to use the name of the Visual Studio project (rename the project in the
rem Solution Explorer), or type the name here, e.g.: set "GAME_NAME=Tank Wars"
set "GAME_NAME="

cd /d "%~dp0"
if defined GAME_NAME set "TMPL8_GAME_NAME=%GAME_NAME%"

set "PRESET=windows-vs-package"
set "WHAT=the Release version"
set "NO_OPEN="
for %%A in (%*) do (
    if /i "%%~A"=="--web" set "PRESET=web-package"
    if /i "%%~A"=="--no-open" set "NO_OPEN=1"
)
if "%PRESET%"=="web-package" set "WHAT=the web version"

rem The web version is built with Ninja; the Windows version only needs CMake.
set "NEED_NINJA="
if "%PRESET%"=="web-package" set "NEED_NINJA=1"
call :find_tools && goto build
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -property installationPath`) do set "VSDIR=%%I"
if defined VSDIR set "VSCMAKE=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake"
rem Only add what is missing (at the end of the PATH), so a CMake that is on the PATH is still the one that runs.
if defined VSCMAKE where cmake >nul 2>nul || set "PATH=%PATH%;%VSCMAKE%\CMake\bin"
if defined VSCMAKE where ninja >nul 2>nul || set "PATH=%PATH%;%VSCMAKE%\Ninja"
call :find_tools && goto build
echo CMake (and Ninja, for the web version) were not found.
echo Open the Visual Studio Installer, click Modify, and add "C++ CMake tools for Windows"
echo (under "Desktop development with C++"), or install CMake and Ninja and add them to the PATH.
if not defined NO_OPEN pause
exit /b 1

:build
echo Building %WHAT% and packing it in a zip file (the first web build also downloads and builds SDL3)...
cmake --workflow --preset %PRESET%
if errorlevel 1 (
    echo.
    echo Packaging failed: see the errors above. Is the game ^(or the zip file^) still open?
    if not defined NO_OPEN pause
    exit /b 1
)

rem The newest zip file in the build folder is the one that was just made.
set "ZIP_FILE="
for /f "delims=" %%Z in ('dir /b /a-d /od build\*.zip') do set "ZIP_FILE=build\%%Z"
echo.
echo Done: "%ZIP_FILE%"
rem Show the zip file in Explorer.
if not defined NO_OPEN explorer /select,"%CD%\%ZIP_FILE%"
exit /b 0

rem Succeeds when CMake (and Ninja, if it is needed) can be found on the PATH.
:find_tools
where cmake >nul 2>nul || exit /b 1
if defined NEED_NINJA where ninja >nul 2>nul || exit /b 1
exit /b 0
