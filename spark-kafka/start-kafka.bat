::===============================================================
:: Check and start Kafka
::===============================================================

@echo off
SetLocal EnableExtensions EnableDelayedExpansion

set StopAtFirst=%1
if /I "%~1" == "true" set "StopAtFirst=1"

call %~dp0\set-path-variables.bat || exit /b !ERRORLEVEL!
for /f "tokens=*" %%a in ('lzmw -z "%KAFKA_HOME%" -x \ -o \\ -PAC') do set "KAFKA_HOME_Pattern=%%a"

if "%StopAtFirst%" == "1" (
    call psall -it "%KAFKA_HOME_Pattern%" --nx lzmw.exe > nul
    if !ERRORLEVEL! GTR 0 call %~dp0\stop-kafka
)

set ZookeeperProcessPattern="%KAFKA_HOME_Pattern%\S+zookeeper-server-start.*config\\zookeeper.properties"

call psall -it "%ZookeeperProcessPattern%" --nx lzmw.exe > nul
if %ERRORLEVEL% EQU 0 (
    echo %KafkaBin%\zookeeper-server-start %KafkaConfigDir%\zookeeper.properties | lzmw -aPA -e "[\w-]+start|([\w\.-]+).properties"
    start %KafkaBin%\zookeeper-server-start %KafkaConfigDir%\zookeeper.properties
    ::powershell -Command "Start-Sleep -Seconds 5"
    ping 127.0.0.1 -n 5 -w 1000 > nul 2>nul
)

:: Wait for Zookeeper process.
for /L %%k in (1,1,20) do (
    call psall -it "%ZookeeperProcessPattern%" --nx lzmw.exe > nul
    if !ERRORLEVEL! GTR 0 (
       call :StartKafaProcess
       exit /b 0
    )
    ::powershell -Command "Start-Sleep -Seconds 3"
    ping 127.0.0.1 -n 3 -w 1000 > nul 2>nul
)


call :StartKafaProcess
exit /b !ERRORLEVEL!

:StartKafaProcess
    set /a kafkaServerNodeCount=0
    for /f "tokens=*" %%a in ('lzmw -p %KafkaConfigDir% -f "^server-?\d*\.properties$" -l -PAC') do (
        for /f "tokens=*" %%p in ('lzmw -z "%%a" -t ".*\\(server-?\d*.properties$)" -o "$1" -PAC') do (
            set oneKafkaConfig=%%p
            ::set killOneCmdPattern=-it "%KAFKA_HOME_Pattern%\S+kafka-server-start.+%%p" -x cmd.exe --nx lzmw.exe
            set killOneCmdPattern=-ix %KafkaConfigDir%\!oneKafkaConfig! -t cmd.exe --nx lzmw.exe
            set oneKafkaProcessPattern=-ix %KafkaConfigDir%\!oneKafkaConfig! -t java.exe --nx lzmw.exe
        )
        
        set /a kafkaServerNodeCount=!kafkaServerNodeCount!+1
        :: echo psall !oneKafkaProcessPattern!
        call psall !oneKafkaProcessPattern! > nul
        if !ERRORLEVEL! EQU 0 (
            :: Close possible dead cmd window
            call pskill !killOneCmdPattern! -M 2>nul
            echo %KafkaBin%\kafka-server-start %KafkaConfigDir%\!oneKafkaConfig! | lzmw -aPA -e "[\w-]+start|([\w\.-]+).properties"
            start %KafkaBin%\kafka-server-start %KafkaConfigDir%\!oneKafkaConfig!
            ::powershell -Command "Start-Sleep -Seconds 3"
            ping 127.0.0.1 -n 3 -w 1000 > nul 2>nul
        )
    )
    
    :: Wait for Kafka process nodes
    set KafkaProcessPattern=-it "%KAFKA_HOME_Pattern%\S+config\\server-?\d*.properties" -x java.exe --nx lzmw.exe
    ::echo kafkaServerNodeCount=!kafkaServerNodeCount!, KafkaProcessPattern=!KafkaProcessPattern!
    for /L %%k in (1,1,20) do (
        call psall %KafkaProcessPattern% > nul
        :: echo return=!ERRORLEVEL!, kafkaServerNodeCount=!kafkaServerNodeCount!
        if !ERRORLEVEL! GEQ !kafkaServerNodeCount! exit /b 0
        ::powershell -Command "Start-Sleep -Seconds 3"
        ping 127.0.0.1 -n 3 -w 1000 > nul 2>nul
    )
    
    exit /b -1
