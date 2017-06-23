::===============================================================
:: Check and stop Kafka which belongs only this test directory.
:: If you want to kill all Kafka processes:
:: call pskill -it "cmd.*kafka-server-start|zookeeper-server-start.bat\s+config|org.apache.zookeeper.server.quorum.QuorumPeerMain"
:: Not use kafka-server-stop and zookeeper-server-stop as they will kill all even not in the directory.
:: 	call %KafkaBin%\kafka-server-stop
:: 	call %KafkaBin%\zookeeper-server-stop
::===============================================================

@echo off
SetLocal EnableExtensions EnableDelayedExpansion

call %~dp0\set-path-variables.bat || exit /b !ERRORLEVEL!
::for /f "tokens=*" %%a in ('lzmw -z "%KAFKA_HOME%" -x \ -o \\ -PAC') do set "KAFKA_HOME_Pattern=%%a"

:: Use -O or -M to hide summary of lzmw.exe if not found kafka processes.
call pskill -ix "%KAFKA_HOME%" --nx lzmw.exe -O
