    @echo off
set FLUTTER_PATH=E:\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat

echo ======================================================
echo Generating Project Files (Android/Windows)...
echo ======================================================
call "%FLUTTER_PATH%" create .

echo ======================================================
echo Installing Dependencies...
echo ======================================================
call "%FLUTTER_PATH%" pub get

if %errorlevel% NEQ 0 (
    echo.
    echo ERROR: Could not install dependencies.
    pause
    exit /b
)

echo ======================================================
echo DIAGNOSING CONNECTION...
echo ======================================================
echo 1. Stopping ADB Server (to clear conflicts)...
call "%FLUTTER_PATH%\cache\artifacts\engine\android-sdk-windows\platform-tools\adb.exe" kill-server 2>nul
:: Attempt generic adb if specific path fails
adb kill-server 2>nul

echo.
echo 2. Running Flutter Doctor (Check Android Toolchain)...
call "%FLUTTER_PATH%" doctor

echo.
echo ======================================================
echo Checking for Connected Devices...
echo ======================================================
call "%FLUTTER_PATH%" devices

echo.
echo ======================================================
echo Running Habit Tracker App...
echo ======================================================
call "%FLUTTER_PATH%" run

pause
