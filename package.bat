@echo off
rem Builds the Release version of your game and packs it in a zip file that you can share: send it to friends,
rem upload it to itch.io, or hand it in. Double-click this file to run it (close the game first if it is running).
rem
rem The zip file is build\<name of your game>.zip, with a folder that contains:
rem   <name of your game>.exe, SDL3.dll, the assets folder and LICENSE-SDL3.txt.
rem Players unzip it and double-click the .exe: they don't need to install anything.
setlocal

rem The name of your game. Leave it empty to use the name of the Visual Studio project (rename the project in the
rem Solution Explorer), or type the name here, e.g.: set "GAME_NAME=Tank Wars"
set "GAME_NAME="

cd /d "%~dp0"

rem The Visual Studio solution and project. The name of the project is also the name of the Release .exe.
set "SOLUTION="
for %%S in (*.slnx *.sln) do if not defined SOLUTION set "SOLUTION=%%S"
set "PROJECT_FILE="
for %%P in (tmpl8\*.vcxproj) do if not defined PROJECT_FILE set "PROJECT_FILE=%%P"
if not defined SOLUTION goto no_project
if not defined PROJECT_FILE goto no_project
for %%P in ("%PROJECT_FILE%") do set "PROJECT_NAME=%%~nP"
for /f "tokens=3 delims=<>" %%N in ('findstr /c:"<ProjectName>" "%PROJECT_FILE%"') do set "PROJECT_NAME=%%N"
if not defined GAME_NAME set "GAME_NAME=%PROJECT_NAME%"

rem Find MSBuild (it comes with Visual Studio).
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto no_visual_studio
set "MSBUILD="
for /f "usebackq delims=" %%M in (`"%VSWHERE%" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do if not defined MSBUILD set "MSBUILD=%%M"
if not defined MSBUILD goto no_visual_studio

echo Building the Release version...
"%MSBUILD%" "%SOLUTION%" -p:Configuration=Release -p:Platform=x64 -m -nologo -verbosity:minimal
if errorlevel 1 goto build_failed

echo Packaging "%GAME_NAME%"...
set "PACKAGE_DIR=build\package"
set "GAME_DIR=%PACKAGE_DIR%\%GAME_NAME%"
set "ZIP_FILE=build\%GAME_NAME%.zip"
if exist "%PACKAGE_DIR%" rd /s /q "%PACKAGE_DIR%"
mkdir "%GAME_DIR%"
copy /y "%PROJECT_NAME%.exe" "%GAME_DIR%\%GAME_NAME%.exe" >nul || goto package_failed
copy /y SDL3.dll "%GAME_DIR%" >nul || goto package_failed
copy /y lib\SDL3\LICENSE.txt "%GAME_DIR%\LICENSE-SDL3.txt" >nul || goto package_failed
xcopy /e /i /q /y assets "%GAME_DIR%\assets" >nul || goto package_failed

rem Zip the folder with the tar that comes with Windows 10 and 11 (-a: the format follows the .zip extension).
rem Its full path is used, because another tar on the PATH (e.g. from Git) may not be able to write zip files.
if exist "%ZIP_FILE%" del /q "%ZIP_FILE%"
"%SystemRoot%\System32\tar.exe" -a -c -f "%ZIP_FILE%" -C "%PACKAGE_DIR%" "%GAME_NAME%" || goto package_failed

echo.
echo Done: "%ZIP_FILE%"
rem Show the zip file in Explorer (unless this runs from an automated build: package.bat --no-open).
if /i not "%~1"=="--no-open" explorer /select,"%CD%\%ZIP_FILE%"
exit /b 0

:no_project
echo The Visual Studio solution (.slnx) or project (tmpl8\*.vcxproj) was not found next to package.bat.
if /i not "%~1"=="--no-open" pause
exit /b 1

:no_visual_studio
echo Visual Studio (with the "Desktop development with C++" workload) was not found.
if /i not "%~1"=="--no-open" pause
exit /b 1

:build_failed
echo.
echo The build failed: see the errors above (or build the Release version in Visual Studio to see them there).
if /i not "%~1"=="--no-open" pause
exit /b 1

:package_failed
echo.
echo Packaging failed: see the messages above. Is the game (or the zip file) still open?
if /i not "%~1"=="--no-open" pause
exit /b 1
