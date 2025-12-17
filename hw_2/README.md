# ДЗ_2 Установка и настройка базы данных Hadoop и выполнение задания

## Запуск
1. `docker build -t hadoop-local . `
2. `docker run -it --hostname=master hive-local`
3. `./init-hadoop.sh`
4. `hdfs dfs -mkdir -p /user/hive/warehouse`
5. `hdfs dfs -chmod g+w /user/hive/warehouse`
6. `schematool -dbType derby -initSchema  # При первом запуске`
7. `hive`


## #1
Набор данных: https://www.kaggle.com/tylerx/flights-and-airports-data

## #2 
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /user/hive/warehouse
schematool -dbType derby -initSchema  # При первом запуске

hdfs dfs -put ./data/airports.csv /
hdfs dfs -put ./data/flights.csv /

hdfs dfs -ls /



## #3


## #4

