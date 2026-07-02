@echo off
setlocal

set APP_ROOT=%~dp0
set GLOBAL_INSTALL=false
set INSTALL_DIR=%USERPROFILE%\.paxori

if "%~1"=="--global" set GLOBAL_INSTALL=true
if /I "%~1"=="-g" set GLOBAL_INSTALL=true

if "%GLOBAL_INSTALL%"=="true" (
  set INSTALL_DIR=%ProgramFiles%\Paxori
)

color 0B

echo.
echo   ██████╗  ██████╗ ██╗  ██╗██╗███████╗
echo   ██╔══██╗██╔═══██╗██║  ██║██║██╔════╝
echo   ██████╔╝██║   ██║███████║██║███████╗
echo   ██╔═══╝ ██║   ██║██╔══██║██║██╔══╝
echo   ██║     ╚██████╔╝██║  ██║██║███████╗
echo   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝
echo.

echo [INFO] Checking prerequisites...
where node >nul 2>nul
if errorlevel 1 (
  echo [ERR] Node.js is required. Install it from https://nodejs.org
  exit /b 1
)
where npm >nul 2>nul
if errorlevel 1 (
  echo [ERR] npm is required. Install Node.js first.
  exit /b 1
)
if "%GLOBAL_INSTALL%"=="true" (
  net session >nul 2>nul
  if errorlevel 1 (
    echo [ERR] Global installation requires administrator rights. Run from an elevated command prompt.
    exit /b 1
  )
)
echo [OK] Prerequisites are available.

echo [INFO] Installing files...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
xcopy /E /I /Y "%APP_ROOT%*" "%INSTALL_DIR%\" >nul

if "%GLOBAL_INSTALL%"=="true" (
  echo @echo off > "%INSTALL_DIR%\paxori.cmd"
  echo cd /d "%INSTALL_DIR%" >> "%INSTALL_DIR%\paxori.cmd"
  echo call npm start %%* >> "%INSTALL_DIR%\paxori.cmd"
  echo [OK] Installed Paxori globally into %INSTALL_DIR%
  echo [INFO] Add %INSTALL_DIR% to PATH to run paxori from anywhere.
) else (
  echo [OK] Installed Paxori into %INSTALL_DIR%
)

echo [OK] Installed Paxori into %INSTALL_DIR%
echo.
echo Paxori installation complete!
echo Run it with: powershell -ExecutionPolicy Bypass -File "%INSTALL_DIR%\run.ps1"
endlocal
