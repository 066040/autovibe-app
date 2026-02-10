@echo off
setlocal

set DEVICE=RFCY91GHLRD
set PORT=3000

echo [1/4] Device kontrol...
adb get-state 1>nul 2>nul
if errorlevel 1 (
  echo ADB calismiyor. once adb server baslatiliyor...
  adb start-server
)

echo [2/4] Device baglanti kontrol...
for /f "tokens=1,2" %%a in ('adb devices') do (
  if "%%a"=="%DEVICE%" if "%%b"=="device" set FOUND=1
)
if not defined FOUND (
  echo Cihaz bulunamadi: %DEVICE%
  echo adb devices ciktisini kontrol et.
  exit /b 1
)

echo [3/4] adb reverse yenileniyor...
adb reverse --remove-all
adb reverse tcp:%PORT% tcp:%PORT%
adb reverse --list

echo [4/4] Flutter run...
cd /d C:\Users\steud\carnews\frontend
flutter run -d %DEVICE%

endlocal
