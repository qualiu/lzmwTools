::======================================================================
::Find dependents for an exe or DLL. Only displays first level dependents if Save-Directory not provided.
::Principle:
::Step-1: Find dumpbin.exe : %PATH%; environment variables like VS120COMNTOOLS/VS150COMNTOOLS.
::Step-2: Dump dependents and grep them.
::Step-3: Exit if Save-Directory not provided or SaveDirectory is empty; Otherwise, recursively find the dependents.
::======================================================================

@echo off
SetLocal EnableExtensions EnableDelayedExpansion

where lzmw.exe 2>nul >nul || if not exist %~dp0\lzmw.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/lzmw.exe?raw=true -OutFile %~dp0\lzmw.exe"
where lzmw.exe 2>nul >nul || set "PATH=%PATH%;%~dp0"

if "%~1" == "" (
    echo Usage  : %~n0  Exe-or-DLL-Path           [Save-Directory]   [Dependents-Directories: Optional; Separated by comma ','] | lzmw -e %~n0 -aPA -t "Exe-or-DLL-Path|(Save-Directory|(Dependents-Directories))"
    echo Example: %~n0  C:\Windows\System32\Robocopy.exe | lzmw -aPA -e %~n0 -t "\S+Robocopy.exe|(\S+tmp\S+|(\S+bin\s*$))"
    echo Example: %~n0  D:\cygwin64\bin\curl.exe  d:\tmp\curl-all    D:\cygwin64\bin       | lzmw -aPA -e %~n0 -t "\S+curl.exe|(\S+tmp\S+|(\S+bin\s*$))"
    echo Example: %~n0  D:\cygwin64\bin\curl.exe  "" "d:\cygwin64\bin,c:\Windows\System32" | lzmw -aPA -e %~n0 -t "\S+curl.exe|\s+(\W{2}(?=\s+)|(\S+bin,\S+))"
    echo Default Dependents-Directory = Exe-Directory , for the above examples, is D:\cygwin64\bin | lzmw -aPA -t "Exe-\S+|((Dependents-Directory|\S+bin))"
    echo Only displays first level dependents if Save-Directory not provided. | lzmw -aPA -it "Only.*first level|(Save-Directory)"
    exit /b -1
)

set ExeOrDLLPath=%1
set SaveDirectory=%2
set DependentsDirectories=%3

if "%~3" == "" for /f "tokens=*" %%a in ('lzmw -z %ExeOrDLLPath% -t "\\[^\\]+$" -o "" -PAC') do set DependentsDirectories="%%a"

where dumpbin.exe 2>nul >nul
if %ERRORLEVEL% GTR 0 (
    for /f "tokens=*" %%a in ('set VS ^| lzmw -it "^VS\d+COMNTOOLS=(.+?Visual Studio.+?)\\?$" -o "$1" -PAC -T 1') do (
        if exist "%%a\VsDevCmd.bat" call "%%a\VsDevCmd.bat" >nul
    )
)
where dumpbin.exe 2>nul >nul || (echo Not found dumpbin.exe | lzmw -PA -t "(dumpbin.exe)|\w+" & exit /b -1)


if "%~2" == "" (
    :: call dumpbin.exe /DEPENDENTS %ExeOrDLLPath% | lzmw --nt "^Dump of" -t "^\s*(\S+.*\.dll)\s*$" -o "$1" -PA
    echo ---- First level dependents of %ExeOrDLLPath% ---------------- | lzmw -PA -t "(First level)" -e "[\w\.-]+\.(dll|exe)"
    for /f "tokens=*" %%a in ('call dumpbin.exe /DEPENDENTS %ExeOrDLLPath% ^| lzmw --nt "^Dump of" -t "^\s*(\S+.*\.dll)\s*$" -o "$1" -PAC') do (
        for /f "tokens=*" %%p in ('lzmw -z "%%a" -t "[\.\$\+]" -o "\\$0" -PAC') do set "toFindFilePattern=%%p"
        :: echo toFindFilePattern=!toFindFilePattern! | lzmw -PA -e .+
        echo lzmw -l -f "^^!toFindFilePattern!$" -rp %DependentsDirectories% --wt --sz -PAC >nul
        lzmw -l -f "^^!toFindFilePattern!$" -rp %DependentsDirectories% --wt --sz -PAC 2>nul | lzmw -PA -e .+
        if !ERRORLEVEL! EQU 0 (
            echo %%a | lzmw -PA -t .+
        )
    )

    exit /b 0
)

if not exist %SaveDirectory% md %SaveDirectory%
if not exist %SaveDirectory%\%~nx1 (
    copy "%~1" %SaveDirectory%
)

echo ---- Dependents of %ExeOrDLLPath% ---------------- | lzmw -PA -e "[\w\.-]+\.(dll|exe)"
for /f "tokens=*" %%a in ('call dumpbin.exe /DEPENDENTS %ExeOrDLLPath% ^| lzmw --nt "^Dump of" -t "^\s*(\S+.*\.dll)\s*$" -o "$1" -PAC') do (
    for /f "tokens=*" %%p in ('lzmw -z "%%a" -t "[\.\$\+]" -o "\\$0" -PAC') do set "toFindFilePattern=%%p"
    ::echo toFindFilePattern=!toFindFilePattern!
    echo lzmw -l -f "^^!toFindFilePattern!$" -rp %DependentsDirectories% --wt --sz -PAC >nul
    lzmw -l -f "^^!toFindFilePattern!$" -rp %DependentsDirectories% --wt --sz -PAC 2>nul | lzmw -PA -e .+
    if !ERRORLEVEL! EQU 0 (
        echo %%a | lzmw -PA -t .+
    ) else (
        for /f "tokens=*" %%b in ('lzmw -l -f "^^!toFindFilePattern!$" -rp %DependentsDirectories% --wt --sz -PAC 2^>nul') do (
            for /f "tokens=*" %%c in ('lzmw -z %%b -t "^.+\\([^\\]+)$" -o "$1" -PAC') do set fileName=%%c
            if not exist %SaveDirectory%\!fileName! (
                copy "%%b" %SaveDirectory%
                call %0 "%%b" %SaveDirectory% %DependentsDirectories%
            )
        )
    )
)
