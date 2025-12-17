#!/bin/bash
set -e

export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export YARN_RESOURCEMANAGER_USER=root
export YARN_NODEMANAGER_USER=root

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

echo "127.0.0.1 master" >> /etc/hosts

service ssh start

if [ ! -f /opt/hadoop_data/hdfs/namenode/current/VERSION ]; then
  hdfs namenode -format -force
fi

$HADOOP_HOME/sbin/start-dfs.sh

$HADOOP_HOME/sbin/start-yarn.sh
