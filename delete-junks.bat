::===================================================
:: Delete junk files and directories.
::===================================================
@echo off
SetLocal EnableExtensions EnableDelayedExpansion

if "%~1" == "" (
    echo Usage  : %~nx0  Directory  [IsPreview]  [Junk_Directory_Pattern]          [Junk_File_Pattern]
    echo Example: %~nx0  my-codes   1            "Debug|Release|ipch|obj|bin|.vs"  "\.(pdb|obj|o|vc.db|ilk|suo|sdf)$"
    echo Example: %~nx0  my-codes   0            ""  "\.(dll|exe)$"
    echo Example: %~nx0  my-codes
    echo IsPreview=1 as default, just preview, not delete.
    exit /b -1
)

set Directory=%1
set IsPreview=%2
set "Junk_Directory_Pattern=%~3"
set Junk_File_Pattern=%4

if not "%IsPreview%" == "0" ( set "lzmwExecute=-c Check junks" ) else ( set "lzmwExecute=-X -c Delete junks" )
if "%Junk_Directory_Pattern%" == "" set "Junk_Directory_Pattern=Debug|Release|ipch|obj|bin|.vs|_UpgradeReport_Files"
if [%Junk_File_Pattern%] == [] set Junk_File_Pattern="^\$RANDOM_SEED\$|\.(pdb|obj|o|vc.db|ilk|suo|sdf|vshost\..*)$"

@where lzmw.exe 2>nul >nul || if not exist %~dp0\lzmw.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/lzmw.exe?raw=true -OutFile %~dp0\lzmw.exe"
@where lzmw.exe 2>nul >nul || set "PATH=%PATH%;%~dp0"

@where nin.exe 2>nul >nul || if not exist %~dp0\nin.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/nin.exe?raw=true -OutFile %~dp0\nin.exe"
@where nin.exe 2>nul >nul || set "PATH=%PATH%;%~dp0"

:: Remove junk directory
dir %1 /S /B /A:D  | lzmw -it "^(.*?\\(%Junk_Directory_Pattern%))\\*.*$"  -o "rd /q /s \"$1\"" -PAC | nin nul -iuPAC | lzmw %lzmwExecute%

:: Remove junk files
lzmw -rp %1 -l -f %Junk_File_Pattern%  -PAC | lzmw -t .+ -o "del /A \"$0\"" %lzmwExecute%
if not "%IsPreview%" == "0" lzmw -rp %1 -l -f %Junk_File_Pattern% --sz --wt -H 0 -c Stats junk files
