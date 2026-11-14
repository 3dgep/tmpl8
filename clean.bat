@echo off
rem Deletes everything Visual Studio generates, so the folder is small enough to zip and hand in.
rem Close Visual Studio first. Double-click this file to run it.
cd /d "%~dp0"
if exist .vs rd /s /q .vs
if exist web-build rd /s /q web-build
if exist build rd /s /q build
del /q *.exe *.pdb *.ilk SDL3.dll 2>nul
echo Done: the template folder is clean.
pause
