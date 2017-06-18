::======================================================================
::Download a portable Cygwin in specified diretory
::======================================================================

@echo off
SetLocal EnableExtensions EnableDelayedExpansion

if "%~1" == "" (
    echo Usage  : %~n0  Save_Directory  [Packages]              [Download_Cache_Directory]
    echo Example: %~n0  D:\tmp\cygwin64 dos2unix,unix2dos,egrep D:\tmp\cygwin64-download-cache
    echo Example: %~n0  D:\tmp\cygwin64
    exit /b -1
)

set Save_Directory=%~dp1%~nx1
if %Save_Directory:~-1%==\ set Save_Directory=%Save_Directory:~0,-1%

if "%~2" == "" ( set Packages=wget,gawk,grep,dos2unix,unix2dos,egrep ) else ( set Packages=%2 )
if "%~3" == "" (
    set Download_Cache_Directory=%Save_Directory%-download-cache
) else (
    set Download_Cache_Directory=%~dp3%~nx3
)

:: --download  --verbose --no-shortcuts --no-startmenu --no-desktop  --prune-install
set OtherOptions=--no-admin --quiet-mode --no-shortcuts --no-startmenu --no-desktop  --prune-install

set ThisDir=%~dp0
if %ThisDir:~-1%==\ set ThisDir=%ThisDir:~0,-1%
set DownloadsDirectory=%ThisDir%\downloads
if not exist %DownloadsDirectory% md %DownloadsDirectory%

set cygwin64_setup_exe=%DownloadsDirectory%\cygwin-setup-x86_64.exe

@echo on

if not exist %cygwin64_setup_exe% powershell -Command "Invoke-WebRequest -Uri https://www.cygwin.com/setup-x86_64.exe -OutFile %cygwin64_setup_exe%"

%cygwin64_setup_exe% --root %Save_Directory% --local-package-dir %Download_Cache_Directory% --packages %Packages% --arch x86_64 %OtherOptions%

@echo off
