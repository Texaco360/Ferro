@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

if "%~1"=="" goto :usage
set "COMMAND=%~1"
shift

if /I "%COMMAND%"=="build" goto :build
if /I "%COMMAND%"=="run" goto :run
if /I "%COMMAND%"=="test" goto :test
if /I "%COMMAND%"=="clean" goto :clean
if /I "%COMMAND%"=="generate" goto :generate
if /I "%COMMAND%"=="migrate" goto :migrate
if /I "%COMMAND%"=="fetch-sqlite" goto :fetch_sqlite
if /I "%COMMAND%"=="help" goto :usage

echo Error: unknown command "%COMMAND%".
goto :usage_error

:usage
echo Ferro Windows helper
echo.
echo Usage: scripts\windows.bat ^<command^> [args]
echo.
echo Commands:
echo   build                Build server binary
echo   run                  Build ^(unless SKIP_BUILD=1^) and run server
echo   test [--build-only]  Build and run tests
echo   clean                Reset build/bin and build/units
echo   generate ^<Model^>     Compile and run generator tool
echo   migrate [args]       Compile and run migration tool
echo   fetch-sqlite         Download sqlite3.dll ^(Win32^) to repo/build folders
echo.
echo Env vars:
echo   DEBUG=1              Build debug mode
echo   OUTPUT_NAME=name     Override binary name
echo   EXTRA_FPC_ARGS=...   Extra arguments passed to fpc
echo   PORT=9010            Server port for run
echo   DB_FILE=path         Test database path
exit /b 0

:usage_error
exit /b 1

:require_fpc
where fpc >nul 2>nul
if errorlevel 1 (
  echo Error: fpc not found in PATH.
  echo Install Free Pascal and retry.
  exit /b 1
)
exit /b 0

:append_module_fu
set "MODULE_FU="
for /D %%M in ("%ROOT_DIR%\modules\*") do (
  if exist "%%~fM\src" set "MODULE_FU=!MODULE_FU! -Fu%%~fM\src"
)
exit /b 0

:require_sqlite_dll
set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" (
  echo Error: internal script issue, missing sqlite target directory.
  exit /b 1
)

if exist "%TARGET_DIR%\sqlite3.dll" exit /b 0

if exist "%ROOT_DIR%\sqlite3.dll" (
  copy /Y "%ROOT_DIR%\sqlite3.dll" "%TARGET_DIR%\sqlite3.dll" >nul
  exit /b 0
)

if defined SQLITE3_DLL if exist "%SQLITE3_DLL%" (
  copy /Y "%SQLITE3_DLL%" "%TARGET_DIR%\sqlite3.dll" >nul
  exit /b 0
)

for /F "delims=" %%D in ('where sqlite3.dll 2^>nul') do (
  copy /Y "%%~fD" "%TARGET_DIR%\sqlite3.dll" >nul
  if exist "%TARGET_DIR%\sqlite3.dll" exit /b 0
)

echo Error: sqlite3.dll not found.
echo.
echo This project needs sqlite3.dll beside the executable on Windows.
echo Checked: %TARGET_DIR%\sqlite3.dll, %ROOT_DIR%\sqlite3.dll, SQLITE3_DLL env var, and PATH.
echo.
echo Fix options:
echo   1^) Place sqlite3.dll at %ROOT_DIR%\sqlite3.dll and rerun.
echo   2^) Set SQLITE3_DLL to an absolute sqlite3.dll path and rerun.
echo   3^) Copy sqlite3.dll directly into %TARGET_DIR%.
exit /b 1

:fetch_sqlite
set "PS_TMP=%TEMP%\ferro-sqlite"
set "PS_ZIP=%PS_TMP%\sqlite3.zip"
set "PS_EXTRACT=%PS_TMP%\extract"

if not exist "%PS_TMP%" mkdir "%PS_TMP%"
if not exist "%PS_EXTRACT%" mkdir "%PS_EXTRACT%"

echo Locating latest Win32 sqlite3.dll package...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$page=Invoke-WebRequest -UseBasicParsing 'https://www.sqlite.org/download.html';" ^
  "$content=$page.Content;" ^
  "$m=[regex]::Match($content,'PRODUCT,[^,]+,(\d{4}/sqlite-dll-win-x86-\d+\.zip),');" ^
  "if(-not $m.Success){ $m=[regex]::Match($content,'PRODUCT,[^,]+,(\d{4}/sqlite-dll-win32-x86-\d+\.zip),') };" ^
  "if(-not $m.Success){ throw 'Could not find Win32 sqlite DLL link on download page.' };" ^
  "$url='https://www.sqlite.org/' + $m.Groups[1].Value;" ^
  "Write-Host ('Downloading ' + $url);" ^
  "Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile '%PS_ZIP%';" ^
  "if(Test-Path '%PS_EXTRACT%'){ Remove-Item -Recurse -Force '%PS_EXTRACT%' };" ^
  "Expand-Archive -Path '%PS_ZIP%' -DestinationPath '%PS_EXTRACT%' -Force;" ^
  "$dll=Get-ChildItem -Path '%PS_EXTRACT%' -Filter sqlite3.dll -Recurse | Select-Object -First 1;" ^
  "if(-not $dll){ throw 'sqlite3.dll was not found in downloaded archive.' };" ^
  "Copy-Item -Path $dll.FullName -Destination '%ROOT_DIR%\sqlite3.dll' -Force;"
if errorlevel 1 (
  echo Error: failed to download sqlite3.dll.
  exit /b 1
)

if not exist "%ROOT_DIR%\sqlite3.dll" (
  echo Error: sqlite3.dll was not created at %ROOT_DIR%\sqlite3.dll.
  exit /b 1
)

if exist "%ROOT_DIR%\build\bin" copy /Y "%ROOT_DIR%\sqlite3.dll" "%ROOT_DIR%\build\bin\sqlite3.dll" >nul
if exist "%ROOT_DIR%\build\tests\bin" copy /Y "%ROOT_DIR%\sqlite3.dll" "%ROOT_DIR%\build\tests\bin\sqlite3.dll" >nul

echo sqlite3.dll installed at %ROOT_DIR%\sqlite3.dll
echo You can now run: scripts\windows.bat run
exit /b 0

:find_main
set "MAIN_FILE="
for %%F in ("%ROOT_DIR%\src\main.lpr" "%ROOT_DIR%\src\Main.lpr" "%ROOT_DIR%\src\TodoApi.lpr" "%ROOT_DIR%\src\todoapi.lpr") do (
  if exist "%%~fF" if not defined MAIN_FILE set "MAIN_FILE=%%~fF"
)
if not defined MAIN_FILE (
  echo Error: no entrypoint .lpr found in %ROOT_DIR%\src
  exit /b 1
)
exit /b 0

:resolve_binary
set "RESOLVED_BINARY="
if exist "%~1.exe" (
  set "RESOLVED_BINARY=%~1.exe"
  exit /b 0
)
if exist "%~1" (
  set "RESOLVED_BINARY=%~1"
  exit /b 0
)
exit /b 1

:build
call :require_fpc || exit /b 1
call :find_main || exit /b 1

set "BUILD_DIR=%ROOT_DIR%\build"
set "BIN_DIR=%BUILD_DIR%\bin"
if not defined OUTPUT_NAME set "OUTPUT_NAME=ferroserver.exe"

if "%DEBUG%"=="1" (
  set "BUILD_PROFILE=debug"
  set "FPC_DEBUG_ARGS=-gl -O-"
) else (
  set "BUILD_PROFILE=release"
  set "FPC_DEBUG_ARGS="
)

set "UNITS_DIR=%BUILD_DIR%\units\%BUILD_PROFILE%"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%UNITS_DIR%" mkdir "%UNITS_DIR%"

call :append_module_fu

echo Building with fpc...
echo Output binary: %BIN_DIR%\%OUTPUT_NAME%
echo Build mode: %BUILD_PROFILE%
echo Unit output: %UNITS_DIR%

call fpc -Mdelphi -FU"%UNITS_DIR%" -FE"%BIN_DIR%" -o"%BIN_DIR%\%OUTPUT_NAME%" %FPC_DEBUG_ARGS% -Fu"%ROOT_DIR%\src" -Fu"%ROOT_DIR%\src\database" -Fu"%ROOT_DIR%\src\domain\shared" -Fu"%ROOT_DIR%\src\domain\todo" -Fu"%ROOT_DIR%\src\domain\project" -Fu"%ROOT_DIR%\src\application\todo" -Fu"%ROOT_DIR%\src\application\project" -Fu"%ROOT_DIR%\src\infrastructure\bootstrap" -Fu"%ROOT_DIR%\src\infrastructure\shared" -Fu"%ROOT_DIR%\src\infrastructure\todo" -Fu"%ROOT_DIR%\src\infrastructure\project" -Fu"%ROOT_DIR%\src\presentation\shared" -Fu"%ROOT_DIR%\src\presentation\todo" -Fu"%ROOT_DIR%\src\presentation\project" -Fu"%ROOT_DIR%\src\presentation\routes" !MODULE_FU! %EXTRA_FPC_ARGS% "%MAIN_FILE%"
if errorlevel 1 exit /b 1

echo Build completed.
exit /b 0

:run
if "%SKIP_BUILD%"=="1" goto :run_skip_build
call "%SCRIPT_DIR%windows.bat" build || exit /b 1
:run_skip_build

if not defined PORT set "PORT=9010"
set "BASE_BINARY=%ROOT_DIR%\build\bin\ferroserver"
call :resolve_binary "%BASE_BINARY%" || (
  echo Error: binary not found at %BASE_BINARY% or %BASE_BINARY%.exe
  echo Run scripts\windows.bat build first.
  exit /b 1
)

call :require_sqlite_dll "%ROOT_DIR%\build\bin" || exit /b 1

echo Starting FerroServer on port %PORT%
set "PORT=%PORT%"
"%RESOLVED_BINARY%"
exit /b %ERRORLEVEL%

:test
set "RUN_TESTS=1"
if "%~1"=="--build-only" set "RUN_TESTS=0"

call :require_fpc || exit /b 1

echo Building application binary for controller integration tests...
call "%SCRIPT_DIR%windows.bat" build || exit /b 1

set "BUILD_DIR=%ROOT_DIR%\build\tests"
set "BIN_DIR=%BUILD_DIR%\bin"
set "UNITS_DIR=%BUILD_DIR%\units"
if not defined OUTPUT_NAME set "OUTPUT_NAME=ferroserver-tests.exe"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%UNITS_DIR%" mkdir "%UNITS_DIR%"

if not defined DB_FILE set "DB_FILE=%BUILD_DIR%\ferroserver-tests.sqlite"
set "DB_PATH=%DB_FILE%"

call :append_module_fu

echo Building test runner with fpc...
echo Output binary: %BIN_DIR%\%OUTPUT_NAME%
echo Database path: %DB_PATH%

call fpc -Mdelphi -FU"%UNITS_DIR%" -FE"%BIN_DIR%" -o"%BIN_DIR%\%OUTPUT_NAME%" -Fu"%ROOT_DIR%\src" -Fu"%ROOT_DIR%\src\database" -Fu"%ROOT_DIR%\src\domain\shared" -Fu"%ROOT_DIR%\src\domain\todo" -Fu"%ROOT_DIR%\src\domain\project" -Fu"%ROOT_DIR%\src\application\todo" -Fu"%ROOT_DIR%\src\application\project" -Fu"%ROOT_DIR%\src\infrastructure\bootstrap" -Fu"%ROOT_DIR%\src\infrastructure\shared" -Fu"%ROOT_DIR%\src\infrastructure\todo" -Fu"%ROOT_DIR%\src\infrastructure\project" -Fu"%ROOT_DIR%\src\presentation\shared" -Fu"%ROOT_DIR%\src\presentation\todo" -Fu"%ROOT_DIR%\src\presentation\project" -Fu"%ROOT_DIR%\src\presentation\routes" -Fu"%ROOT_DIR%\tests" !MODULE_FU! "%ROOT_DIR%\tests\FerroServerTests.lpr"
if errorlevel 1 exit /b 1

if "%RUN_TESTS%"=="1" (
  call :resolve_binary "%BIN_DIR%\%OUTPUT_NAME%" || (
    echo Error: test binary not found.
    exit /b 1
  )
  call :require_sqlite_dll "%ROOT_DIR%\build\bin" || exit /b 1
  call :require_sqlite_dll "%BIN_DIR%" || exit /b 1
  echo Running tests...
  "!RESOLVED_BINARY!" --all
  exit /b !ERRORLEVEL!
)

exit /b 0

:clean
if exist "%ROOT_DIR%\build\bin" rd /s /q "%ROOT_DIR%\build\bin"
if exist "%ROOT_DIR%\build\units" rd /s /q "%ROOT_DIR%\build\units"
mkdir "%ROOT_DIR%\build\bin" 2>nul
mkdir "%ROOT_DIR%\build\units" 2>nul
echo Clean completed: build/bin and build/units reset.
exit /b 0

:generate
call :require_fpc || exit /b 1
set "BUILD_DIR=%ROOT_DIR%\build"
set "BIN_DIR=%BUILD_DIR%\bin"
set "UNITS_DIR=%BUILD_DIR%\units\generate"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%UNITS_DIR%" mkdir "%UNITS_DIR%"

echo Compiling generate tool...
call fpc -Mdelphi -FU"%UNITS_DIR%" -FE"%BIN_DIR%" -o"%BIN_DIR%\generate.exe" "%ROOT_DIR%\tools\generate.lpr"
if errorlevel 1 exit /b 1

call :resolve_binary "%BIN_DIR%\generate.exe" || exit /b 1
"%RESOLVED_BINARY%" %*
exit /b %ERRORLEVEL%

:migrate
call :require_fpc || exit /b 1
set "BUILD_DIR=%ROOT_DIR%\build"
set "BIN_DIR=%BUILD_DIR%\bin"
set "UNITS_DIR=%BUILD_DIR%\units\migrate"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%UNITS_DIR%" mkdir "%UNITS_DIR%"

call :append_module_fu

echo Compiling migrate tool...
call fpc -Mdelphi -FU"%UNITS_DIR%" -FE"%BIN_DIR%" -o"%BIN_DIR%\migrate.exe" -Fu"%ROOT_DIR%\src" -Fu"%ROOT_DIR%\src\database" !MODULE_FU! "%ROOT_DIR%\tools\migrate.lpr"
if errorlevel 1 exit /b 1

call :resolve_binary "%BIN_DIR%\migrate.exe" || exit /b 1
"%RESOLVED_BINARY%" %*
exit /b %ERRORLEVEL%
