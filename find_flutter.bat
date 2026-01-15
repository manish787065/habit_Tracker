@echo off
echo ======================================================
echo Searching for Flutter SDK... Please wait.
echo This might take a few minutes.
echo ======================================================

echo [1/2] Searching in C: Drive...
cd /d C:\
where /r C:\ flutter.bat 2>nul
if %errorlevel%==0 goto Found

echo.
echo [2/2] Searching in E: Drive...
cd /d E:\
where /r E:\ flutter.bat 2>nul
if %errorlevel%==0 goto Found

echo.
echo ======================================================
echo COULD NOT FIND FLUTTER.
echo Please install Flutter from: https://docs.flutter.dev/get-started/install/windows
echo ======================================================
pause
exit /b

:Found
echo.
echo ======================================================
echo FLUTTER FOUND!
echo Please copy the path above (the folder containing bin).
echo Example: If path is C:\src\flutter\bin\flutter.bat
echo Then your flutter Path is: C:\src\flutter\bin
echo ======================================================
pause
