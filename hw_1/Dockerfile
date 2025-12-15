FROM ubuntu:20.04

ENV HADOOP_VERSION=3.3.6 \
    HADOOP_HOME=/opt/hadoop \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

RUN apt-get update && \
    apt-get install -y openjdk-8-jdk ssh openssh-server wget vim net-tools procps && \
    apt-get clean

RUN wget -q https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -O /tmp/hadoop.tar.gz && \
    tar -xzf /tmp/hadoop.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm /tmp/hadoop.tar.gz

RUN mkdir -p ~/.ssh && \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

RUN mkdir -p /opt/hadoop_data/hdfs/namenode /opt/hadoop_data/hdfs/datanode

COPY core-site.xml $HADOOP_HOME/etc/hadoop/
COPY hdfs-site.xml $HADOOP_HOME/etc/hadoop/
COPY yarn-site.xml $HADOOP_HOME/etc/hadoop/
COPY mapred-site.xml $HADOOP_HOME/etc/hadoop/

ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

COPY init-hadoop.sh /init-hadoop.sh
RUN chmod +x /init-hadoop.sh

CMD ["/bin/bash"]