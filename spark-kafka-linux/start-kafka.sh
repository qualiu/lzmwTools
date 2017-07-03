#!/bin/sh
cd $(dirname $0)
thisDir=$PWD

alias lzmw=~/qualiu/tools/lzmw.gcc48
alias nin=~/qualiu/tools/nin.gcc48

kafkaRoot=$thisDir/$(ls -d */ | lzmw -t "(kafka.+)/$" -o '$1' -PAC -T 1)
kafkaBin=$kafkaRoot/bin
kafkaConfigDir=$kafkaRoot/config

echo $kafkaBin/zookeeper-server-start.sh $kafkaConfigDir/zookeeper.properties | lzmw -aPA -ie "zookeeper\S+"
$kafkaBin/zookeeper-server-start.sh $kafkaConfigDir/zookeeper.properties &

for oneConfig in $(ls $kafkaConfigDir | grep server.*propert\S+ ); do
    echo $kafkaBin/kafka-server-start.sh $kafkaConfigDir/$oneConfig | lzmw -aPA -ie "kafka-server-start|server.*propert\S+"
    $kafkaBin/kafka-server-start.sh $kafkaConfigDir/$oneConfig &
done
