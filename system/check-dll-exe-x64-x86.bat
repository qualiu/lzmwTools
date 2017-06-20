::====================================================
:: Check DLL or EXE file platform bits.
::====================================================
@echo off
SetLocal EnableExtensions EnableDelayedExpansion

where lzmw.exe 2>nul >nul || if not exist %~dp0\lzmw.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/lzmw.exe?raw=true -OutFile %~dp0\lzmw.exe"
where lzmw.exe 2>nul >nul || set "PATH=%PATH%;%~dp0"

if "%~1" == "" (
    echo Usage   : %0  directory-or-file    [lzmw-options except : -f -l -PAC -r -p ]
    echo Example : %0  d:\lztool\lzmw.exe
    echo Example : %0  d:\lztool\           --nd "^(obj|target)$" --nf "log4net|Json|Razorvine"
    exit /b -1
)

set CheckPath=%1

where dumpbin.exe 2>nul >nul
if %ERRORLEVEL% GTR 0 (
    for /f "tokens=*" %%a in ('set VS ^| lzmw -it "^VS\d+COMNTOOLS=(.+?Visual Studio.+?)\\?$" -o "$1" -PAC -T 1') do (
        if exist "%%a\VsDevCmd.bat" call "%%a\VsDevCmd.bat" >nul
    )
)
where dumpbin.exe 2>nul >nul || (echo Not found dumpbin.exe | lzmw -PA -t "(dumpbin.exe)|\w+" & exit /b -1)

shift
for /F "tokens=*" %%f in ('lzmw -rp %CheckPath% -f "\.(dll|exe|lib)$" -PAC -l %* '); do (
    echo dumpbin.exe /headers %%f ^| lzmw -it "\s+machine\s*\(\s*\w*\d+\w*\s*\)" -PA
    dumpbin.exe /headers %%f | lzmw -PA -it "machine.*\d+"
)
