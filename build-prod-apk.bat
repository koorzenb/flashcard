@echo off
REM exit when any command fails
@REM setlocal
setlocal EnableDelayedExpansion


REM If define_env is not configured, configure it
where /q define_env
if errorlevel 1 (
    echo define_env could not be found
    dart pub global activate define_env
)

call copy-pubspec.bat

REM Create folder for build if it doesn't exist
set OUTPUT_FOLDER=release\%BUILD_VERSION%
set OUTPUT_FILE=%PROJ_NAME%-%BUILD_VERSION%.apk

REM Warn user if folder already exists
echo Output file = .\%OUTPUT_FOLDER%\%OUTPUT_FILE%


@REM if "1"=="1" (
if exist %OUTPUT_FOLDER%\%OUTPUT_FILE% (
    call :promptUser
) else (
    call :continueBuild
)
exit /b

:promptUser
set /P REPLY=Press 'y' to overwrite, or any other key to exit: 
if /I "%REPLY%"=="Y" goto :continueBuild
exit /b

:continueBuild

if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"

call flutter doctor -v > flutter-doctor-win.txt 
call flutter pub outdated >> flutter-doctor-win.txt

for /F "usebackq delims=" %%A in (`define_env -f .env.prod --no-generate ^| sed -r "s/--dart-define=/--dart-define /g"`) do call flutter build apk --release -v -t lib/main.dart --obfuscate --split-debug-info=./debug-info %%A

echo.

if exist build\app\outputs\flutter-apk\app-release.apk (
    move /Y build\app\outputs\flutter-apk\app-release.apk %OUTPUT_FOLDER%\%OUTPUT_FILE%
    echo Built %BUILD_VERSION% bundle to "%OUTPUT_FOLDER%"
) else (
    echo Build failed.
)