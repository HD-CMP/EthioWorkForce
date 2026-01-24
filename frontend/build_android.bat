@echo off
echo Building EthioWorkforce Android APK...
echo.

echo Cleaning previous builds...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo Running code generation...
call flutter pub run build_runner build --delete-conflicting-outputs

echo Building release APK...
call flutter build apk --release --split-per-abi

echo.
echo Build complete!
echo.
echo APK files location:
echo    - ARM64 (most common): build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo    - ARMv7 (older devices): build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
echo    - x86_64 (emulators): build\app\outputs\flutter-apk\app-x86_64-release.apk
echo.
echo Transfer to your phone and install!
pause
