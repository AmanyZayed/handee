@echo off
REM Do NOT use plain "flutter run" — C: temp is full. This script uses D: for temp/cache.
setlocal
set "GRADLE_USER_HOME=D:\dev\gradle-home"
set "PUB_CACHE=D:\dev\pub-cache"
set "TEMP=D:\dev\tmp"
set "TMP=D:\dev\tmp"
set "FLUTTER_BIN=D:\src\flutter\bin\flutter.bat"

if not exist "D:\dev\tmp" mkdir "D:\dev\tmp"
if not exist "D:\dev\gradle-home" mkdir "D:\dev\gradle-home"
if not exist "D:\dev\pub-cache" mkdir "D:\dev\pub-cache"

cd /d "%~dp0"

if "%1"=="install" (
  echo Installing existing APK to phone...
  "D:\Android\Sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-debug.apk"
  exit /b %ERRORLEVEL%
)

echo TEMP=%TEMP%
echo Project=%CD%
echo.

if "%1"=="" (
  "%FLUTTER_BIN%" run
) else (
  "%FLUTTER_BIN%" run -d %1
)
