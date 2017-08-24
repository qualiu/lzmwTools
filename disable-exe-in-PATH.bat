::===============================================
:: Find and disable specified exe files in PATH
::===============================================
@echo off

SetLocal EnableExtensions EnableDelayedExpansion

set lzmwExe=%~dp0lzmw.exe
if not exist %lzmwExe% powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/lzmw.exe?raw=true -OutFile %~dp0lzmw.exe"

if "%~1" == "" (
    echo Usage  : %~n0  ExeFilePattern     | %lzmwExe% -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0  lzmw.exe            | %lzmwExe% -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0  "^(lzmw|nin)\.exe$"       | %lzmwExe% -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0  "^(lzmw|nin)\.exe$|psall.bat" | %lzmwExe% -aPA -e "%~n0\s+(\S+).*"
    exit /b -1
)

set ninExe=%~dp0nin.exe
if not exist %ninExe% powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/nin.exe?raw=true -OutFile %~dp0nin.exe"

:: Dispaly files with exe pattern %1
%lzmwExe% -l -f "%~1" --wt --sz -p "%PATH%" 2>nul
if %ERRORLEVEL% EQU 0 exit /b 0

set "tmpPATH=%PATH%"
for /f "tokens=*" %%a in ('%lzmwExe% -l -f "%~1" -PAC 2^>nul -p "%PATH%" ^| %ninExe% nul "^([a-z]+.+?)[\\/][^\\/]*$" -iuPAC') do (
    :: echo Will remove in PATH: %%a
    for /f "tokens=*" %%b in ('%lzmwExe% -z "!tmpPATH!" -t "\\*\s*;\s*" -o "\n" -aPAC ^| %lzmwExe% --nx %%a -i -PAC ^| %lzmwExe% -S -t "[\r\n]+\s*(\S+)" -o ";$1" -aPAC ^| %lzmwExe% -S -t "\s+$" -o "" -aPAC') do (
        set "tmpPATH=%%b"
    )
)

EndLocal & set "PATH=%tmpPATH%"
