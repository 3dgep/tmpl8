@echo off
rem Builds the Release version of your game and packs it in a zip file that you can share: send it to friends,
rem upload it to itch.io, or hand it in. Double-click this file to run it (close the game first if it is running).
rem
rem The zip file is build\<name of your game>.zip, with a folder that contains:
rem   <name of your game>.exe, SDL3.dll, the assets folder and LICENSE-SDL3.txt.
rem Players unzip it and double-click the .exe: they don't need to install anything.
rem
rem This runs the "windows-vs-package" workflow of CMake (see CMakePresets.json, and the Packaging section of
rem CMakeLists.txt), so what goes in the zip file is set up in one place. CMake comes with Visual Studio
rem ("C++ CMake tools for Windows", part of the "Desktop development with C++" workload): this script finds it there
rem when it isn't on the PATH. For the web: cmake --workflow --preset web-package (build\<name of your game>-web.zip).
setlocal

rem The name of your game. Leave it empty to use the name of the Visual Studio project (rename the project in the
rem Solution Explorer), or type the name here, e.g.: set "GAME_NAME=Tank Wars"
set "GAME_NAME="

cd /d "%~dp0"
if defined GAME_NAME set "TMPL8_GAME_NAME=%GAME_NAME%"

where cmake >nul 2>nul && goto build
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -property installationPath`) do set "VSDIR=%%I"
if defined VSDIR set "VSCMAKE=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake"
if defined VSCMAKE if exist "%VSCMAKE%\CMake\bin\cmake.exe" set "PATH=%VSCMAKE%\CMake\bin;%PATH%"
where cmake >nul 2>nul && goto build
echo CMake was not found.
echo Open the Visual Studio Installer, click Modify, and add "C++ CMake tools for Windows"
echo (under "Desktop development with C++"), or install CMake and add it to the PATH.
if /i not "%~1"=="--no-open" pause
exit /b 1

:build
echo Building the Release version and packing it in a zip file...
cmake --workflow --preset windows-vs-package
if errorlevel 1 (
    echo.
    echo Packaging failed: see the errors above. Is the game ^(or the zip file^) still open?
    if /i not "%~1"=="--no-open" pause
    exit /b 1
)

rem The newest zip file in the build folder is the one that was just made.
set "ZIP_FILE="
for /f "delims=" %%Z in ('dir /b /a-d /od build\*.zip') do set "ZIP_FILE=build\%%Z"
echo.
echo Done: "%ZIP_FILE%"
rem Show the zip file in Explorer (unless this runs from an automated build: package.bat --no-open).
if /i not "%~1"=="--no-open" explorer /select,"%CD%\%ZIP_FILE%"
exit /b 0
