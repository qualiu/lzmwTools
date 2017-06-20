::=================================================
:: Turn off echo if have turned on.
:: Basically, Replace "echo on" to "echo off" :
:: lzmw -rp directory1,file1 -f "\.(bat|cmd)$" -it "^(\s*@\s*echo)\s+off\b" -o "$1 on" -R
::=================================================
@echo off
SetLocal EnableExtensions EnableDelayedExpansion

where lzmw.exe 2>nul >nul || if not exist %~dp0\lzmw.exe powershell -Command "Invoke-WebRequest -Uri https://github.com/qualiu/lzmw/blob/master/tools/lzmw.exe?raw=true -OutFile %~dp0\lzmw.exe"
where lzmw.exe 2>nul >nul || set "PATH=%PATH%;%~dp0"

@if "%~1" == "" (
    echo Usage  : %~n0 Files_Directories [lzmw_Options: Optional]   | lzmw -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0 "directory1,file1,file2"        | lzmw -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0 "directory1,file1,file2" -R     | lzmw -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0 "directory1,file1,file2" -r     | lzmw -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0 "directory1,file1,file2" -r -R  | lzmw -aPA -e "%~n0\s+(\S+).*"
    echo Example: %~n0 "directory1,file1,file2" --nd "^(softwares|logs|data|target|bin|obj|Debug|Release)$" -r -R    | lzmw -aPA -e "%~n0\s+(\S+).*"
    echo Use -r to recursively search or replace; Use -R to replace, preview without -R. | lzmw -aPA -t "-\w\b" -e .+
    echo Should not use -p as occuppied. | lzmw -PA -t "-\S+|(\w+)"
    echo It just calls: lzmw -rp directory1,file1 -f "\.(bat|cmd)$" -it "^(\s*@\s*echo)\s+off\b" -o "$1 on" -R | lzmw -aPA -e "lzmw (-rp \S+).*" -t "\s+-[rp]+\s+|\s+(-\w+)\s+"
    exit /b -1
)

:: first argument must be the path, just like above examples.
lzmw -it "^(\s*@\s*echo)\s+on\b" -o "$1 off" -f "\.(bat|cmd)$" -p %*
