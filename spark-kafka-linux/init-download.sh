#!/bin/sh
cd $(dirname $0)
thisDir=$PWD

scalaVersion=2.11
kafkaVersion=0.10.1.0
kafkaTarName=kafka_$scalaVersion-$kafkaVersion
if [ ! -f $kafkaTarName.tgz ]; then
        wget http://www-eu.apache.org/dist/kafka/$kafkaVersion/$kafkaTarName.tgz
fi

if [ ! -f $kafkaTarName ]; then
        tar xf $kafkaTarName.tgz
fi

kafkaRoot=$thisDir/$kafkaTarName
zookeeperDataDir=$kafkaRoot/data/zookeeper
kafkaLogDir=$kafkaRoot/kafka-logs
kafkaConfigDir=$kafkaRoot/config

alias lzmw='~/qualiu/tools/lzmw.gcc48'
alias nin='~/qualiu/tools/nin.gcc48'

lzmw -it "^(\s*dataDir)\s*=.*$" -o '$1="'$zookeeperDataDir'"' -p $kafkaConfigDir/zookeeper.properties -R -c
lzmw -it "^(\s*log.dirs)\s*=.*$" -o '$1="'$kafkaLogDir'"' -p $kafkaConfigDir/server.properties -R -c
lzmw -it "^(\s*num.partitions)\s*=.*$" -o '$1=2' -p $kafkaConfigDir/server.properties -R -c
