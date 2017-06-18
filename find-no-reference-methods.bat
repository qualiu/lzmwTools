::=======================================================
:: Find unreferenced methods in code files.
::=======================================================
@echo off
SetLocal EnableExtensions EnableDelayedExpansion

set ThisDir=%~dp0
if %ThisDir:~-1%==\ set ThisDir=%ThisDir:~0,-1%

where lzmw.exe 2>nul >nul || if not exist %ThisDir%\lzmw.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/lzmw.exe?raw=true -OutFile %ThisDir%\lzmw.exe"
where lzmw.exe 2>nul >nul || set "PATH=%ThisDir%;%PATH%"


@if "%~3" == "" (
    echo on
    set enhanceCommand=-aPA -e %~n0 -it "\w+Dir\w+|(\w+name\w+|(\bMethod\w+Cap\w+|(other\w+)))"
    set enhanceExamples=-aPA -e %~n0 -it "src\\scala|(\\.scala\$.\s+(\S+(\s*-?.*)))
    echo Usage  : %~n0  Files_or_Directories  File_Name_Pattern  Method_Capture1_Pattern  [Other_lzmw_Options: Optional] | lzmw !enhanceCommand!
    echo Example: %~n0  src\scala  "\.scala$"  "^\s*def\s+(\w+)\s*[\(:].*"  -P        | lzmw !enhanceExamples!
    echo Example: %~n0  src\scala  "\.scala$"  "^\s*def\s+(\w+)\s*[\(:].*"	-U 2 -D 2 | lzmw !enhanceExamples!
    echo Example: %~n0  src\scala  "\.scala$"  "^\s*def\s+(\w+)\s*[\(:].*"  --nd "^(\.git|target)$|test" --nt "^\s*//" | lzmw !enhanceExamples!
    echo Example: %~n0  src\scala  "\.scala$"  "^\s*def\s+(\w+)\s*[\(:].*"  --nd "^(\.git|target)$|test" --nf "test|unit" --nt "^\s*//" | lzmw !enhanceExamples!
    echo Should not use -r -p , -f , -t as occupied: -rp Files_or_Directories, -f File_Name_Pattern, -t Method_Capture1_Pattern. | lzmw -PA -t "-[rp]+|(-f|(-t))\s+" -e "(\w+)"
    exit /b -1
)

set Files_or_Directories=%1
set File_Name_Pattern=%2
set Method_Capture1_Pattern=%3

shift & shift & shift
:: Begin to get other arguments, save to lzmwOptions
set /a AddPrefixFileFilter=0
set NoPathAnyInfoColor=__-PAC
set NoSumary=-M
set ShowCommand=-c

:CheckArgs
    if "%~1" == ""  goto CheckArgsCompleted
    if "%~1" == "-f" set /a AddPrefixFileFilter=1
    lzmw -z " %~1" -it "\s+-[A-Z]*P" >nul || for /f "tokens=*" %%a in ('lzmw -z "!NoPathAnyInfoColor!" -t "P" -o "" -PAC') do set NoPathAnyInfoColor=%%a
    lzmw -z " %~1" -it "\s+-[A-Z]*A" >nul || for /f "tokens=*" %%a in ('lzmw -z "!NoPathAnyInfoColor!" -t "A" -o "" -PAC') do set NoPathAnyInfoColor=%%a
    lzmw -z " %~1" -it "\s+-[A-Z]*C" >nul || for /f "tokens=*" %%a in ('lzmw -z "!NoPathAnyInfoColor!" -t "C" -o "" -PAC') do set NoPathAnyInfoColor=%%a
    lzmw -z " %~1" -it "\s+-[A-Z]*M" >nul || set "NoSumary="
    lzmw -z " %~1" -it "\s+-[A-Z]*c" >nul || set "ShowCommand="
    set safeArg=%1
    lzmw -z " %~1" -t "(\s+-[A-Z]*?)[alRXK]+" >nul || for /f "tokens=*" %%a in ('lzmw -z " %~1" -t "(\s+-[A-Z]*?)[alRXK]+" -o "$1" -aPAC') do set safeArg=%%a
    set lzmwOptions=!lzmwOptions! !safeArg!
    shift
    goto CheckArgs
    
:CheckArgsCompleted

for /f "tokens=*" %%a in ('lzmw -z "!NoPathAnyInfoColor!" -t "(__\s*$|__$|__)" -o "" -aPAC') do set NoPathAnyInfoColor=%%a

:: if not defined lzmwOptions set set lzmwOptions=--nd "^\.git$" -f "\.(hp*|cp*|cx*|cs|ps1|bat|cmd)$"
if not defined lzmwOptions (
    set lzmwOptions=--nd "^\.git$"
) else (
    for /f "tokens=*" %%a in ('echo !lzmwOptions! ^| lzmw -t "\s+-(\s+|$)" -o " " -aPAC') do set lzmwOptions=%%a
    for /f "tokens=*" %%a in ('echo !lzmwOptions! ^| lzmw -t "(^|\s+)-[UD]\s*\d+" -o " " -aPAC') do set lzmwOptionsGetMethod=%%a
)

:: set | lzmw -t "lzmwOptions|^(NoPathAnyInfoColor|NoSumary|ShowCommand)$" & exit /b 0

set /a checkedMethods=0
set /a unreferencedMethods=0

set commonCommand=lzmw -rp %Files_or_Directories% -f %File_Name_Pattern%

for /f "tokens=*" %%a in ('!commonCommand! -t %Method_Capture1_Pattern% -o "$1" !lzmwOptionsGetMethod! !NoPathAnyInfoColor!') do (
    set /a checkedMethods+=1
    :: set checkMethodPattern="^\s*def\s+%%a|\.?\b%%a\s*\(|\.%%a\b"
    set checkMethodPattern="\b%%a\b"
    set checkCommand=!commonCommand! -t !checkMethodPattern! %ShowCommand% !lzmwOptions! Check method %%a
    !checkCommand! >nul
    
    :: checkCommand Return value = !ERRORLEVEL! = matched count in Files_or_Directories
    if !ERRORLEVEL! EQU 1 (
        set /a unreferencedMethods+=1
        echo. & echo Unreferenced method[!unreferencedMethods!]: %%a , Check pattern: !checkMethodPattern! | lzmw -aPA -x %%a -t "(\d+)|\w+"
        !checkCommand! !NoSumary!
    )
)

echo Checked !checkedMethods! methods, unreferenced method count = !unreferencedMethods! in %Files_or_Directories% | lzmw -aPA -it "(Unreferenced method count = )\d+" -e "\w+"
