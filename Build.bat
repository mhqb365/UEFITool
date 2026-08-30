@echo off
setlocal

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "MSYS=C:\msys64"
set "BASH=%MSYS%\usr\bin\bash.exe"
set "WINDEPLOYQT=%MSYS%\ucrt64\bin\windeployqt.exe"
set "BUILD_DIR=%ROOT%\build"
set "RELEASE_DIR=%ROOT%\release-minimal\UEFITool"
set "PACK_DIR=%ROOT%\release-packed\UEFITool"
set "PACK_BIN=%PACK_DIR%\bin"
set "ROOT_MSYS=/c%ROOT:~2%"
set "BUILD_MSYS=/c%BUILD_DIR:~2%"
set "ROOT_MSYS=%ROOT_MSYS:\=/%"
set "BUILD_MSYS=%BUILD_MSYS:\=/%"

if not exist "%BASH%" (
    echo MSYS2 was not found at "%MSYS%".
    echo Install MSYS2 and the UCRT64 toolchain first.
    exit /b 1
)

taskkill /IM UEFITool.exe /F >nul 2>nul

echo [1/4] Configuring...
"%BASH%" -lc "export PATH=/ucrt64/bin:$PATH; cmake -S '%ROOT_MSYS%' -B '%BUILD_MSYS%' -G Ninja -DCMAKE_BUILD_TYPE=Release"
if errorlevel 1 exit /b 1

echo [2/4] Building...
"%BASH%" -lc "export PATH=/ucrt64/bin:$PATH; cmake --build '%BUILD_MSYS%' -j4"
if errorlevel 1 exit /b 1

echo [3/4] Preparing minimal release folder...
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"
copy /Y "%BUILD_DIR%\UEFITool\UEFITool.exe" "%RELEASE_DIR%\" >nul
if errorlevel 1 exit /b 1

echo [4/4] Deploying Qt runtime...
if exist "%WINDEPLOYQT%" (
    "%WINDEPLOYQT%" --compiler-runtime --release "%RELEASE_DIR%\UEFITool.exe"
    if errorlevel 1 exit /b 1
) else (
    echo windeployqt was not found at "%WINDEPLOYQT%".
    exit /b 1
)

for %%F in (
    libgcc_s_seh-1.dll
    libstdc++-6.dll
    libwinpthread-1.dll
    libb2-1.dll
    libdouble-conversion.dll
    libicuin78.dll
    libicuuc78.dll
    libpcre2-16-0.dll
    zlib1.dll
    libzstd.dll
    libfreetype-6.dll
    libharfbuzz-0.dll
    libmd4c.dll
    libpng16-16.dll
    libicudt78.dll
    libbrotlidec.dll
    libbz2-1.dll
    libglib-2.0-0.dll
    libgraphite2.dll
    libbrotlicommon.dll
    libintl-8.dll
    libpcre2-8-0.dll
    libiconv-2.dll
    libjpeg-8.dll
) do (
    if exist "%MSYS%\ucrt64\bin\%%F" copy /Y "%MSYS%\ucrt64\bin\%%F" "%RELEASE_DIR%\" >nul
)

echo.
echo Build complete:
echo   %BUILD_DIR%\UEFITool\UEFITool.exe
echo.
echo Minimal release:
echo   %RELEASE_DIR%\UEFITool.exe

echo.
echo Preparing packed release:
if not exist "%PACK_BIN%" mkdir "%PACK_BIN%"
xcopy /E /I /Y "%RELEASE_DIR%\*" "%PACK_BIN%\" >nul
if errorlevel 1 exit /b 1
(
    echo @echo off
    echo setlocal
    echo set "APP_DIR=%%~dp0bin"
    echo set "PATH=%%APP_DIR%%;%%PATH%%"
    echo start "" "%%APP_DIR%%\UEFITool.exe" %%*
    echo endlocal
) > "%PACK_DIR%\Run.bat"
if exist "%PACK_DIR%\UEFITool.bat" del /Q "%PACK_DIR%\UEFITool.bat"
echo   %PACK_DIR%\Run.bat

endlocal
