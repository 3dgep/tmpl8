@echo off
rem Builds the Windows version of your game with CMake, then starts it.
rem Double-click this file to run it. The game is written to the build\windows-vs\Release folder, with the assets
rem folder and SDL3.dll next to it. (To share your game, use package.bat, which also packs it in a zip file.)
rem
rem This runs the "windows-vs" configure preset and the "windows-vs-release" build preset of CMake (see
rem CMakePresets.json and CMakeLists.txt). CMake comes with Visual Studio ("C++ CMake tools for Windows", part of the
rem "Desktop development with C++" workload): this script finds it there when it isn't on the PATH.
rem "build.bat --debug" builds the Debug version instead (build\windows-vs\Debug, with a console window).
rem "build.bat --no-run" only builds (for automated builds).
setlocal
cd /d "%~dp0"

set "CONFIG=Release"
set "NO_RUN="
for %%A in (%*) do (
    if /i "%%~A"=="--debug" set "CONFIG=Debug"
    if /i "%%~A"=="--no-run" set "NO_RUN=1"
)

where cmake >nul 2>nul && goto build
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -property installationPath`) do set "VSDIR=%%I"
if defined VSDIR set "VSCMAKE=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake"
if defined VSCMAKE if exist "%VSCMAKE%\CMake\bin\cmake.exe" set "PATH=%VSCMAKE%\CMake\bin;%PATH%"
where cmake >nul 2>nul && goto build
echo CMake was not found.
echo Open the Visual Studio Installer, click Modify, and add "C++ CMake tools for Windows"
echo (under "Desktop development with C++"), or install CMake and add it to the PATH.
if not defined NO_RUN pause
exit /b 1

:build
echo Building the %CONFIG% version...
cmake --preset windows-vs
if errorlevel 1 goto failed
if /i "%CONFIG%"=="Debug" (cmake --build --preset windows-vs-debug) else (cmake --build --preset windows-vs-release)
if errorlevel 1 goto failed

set "GAME=build\windows-vs\%CONFIG%\tmpl8.exe"
echo.
echo Done: %GAME%
if defined NO_RUN exit /b 0
rem Start it in its own folder, like a player would (the full path, because start looks in that folder).
start "" /d "%CD%\build\windows-vs\%CONFIG%" "%CD%\%GAME%"
exit /b 0

:failed
echo.
echo The build failed: see the errors above. Is the game still running?
if not defined NO_RUN pause
exit /b 1
