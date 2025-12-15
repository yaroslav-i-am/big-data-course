# ДЗ_1 Разработка контейнера на Hadoop и выполнение задания

## #1
```bash
hdfs dfs -mkdir /createme
hdfs dfs -ls /
# --
Found 1 items
drwxr-xr-x   - root supergroup          0 2025-12-15 14:18 /createme
```

## #2
```bash
hdfs dfs -mkdir /delme
hdfs dfs -rm -rf /delme
hdfs dfs -ls /
# --
Found 1 items
drwxr-xr-x   - root supergroup          0 2025-12-15 14:18 /createme
```

## #3
```bash
echo "Test input for task 3" | hdfs dfs -put - /nonnull.txt
hdfs dfs -cat /nonnull.txt
# --
Test input for task 3
```

## #4
```bash
echo "Innsmouth sdfaf Innsmouth . sdafas Innsmouth asdfafawqe. wertwhewg Innsmouth wretrt солhgjk." > /tmp/shadow.txt
hdfs dfs -put /tmp/shadow.txt /shadow.txt
hdfs dfs -cat /shadow.txt
# --
Innsmouth sdfaf Innsmouth . sdafas Innsmouth asdfafawqe. wertwhewg Innsmouth wretrt солhgjk.

hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
    wordcount /shadow.txt /wordcount_output
hdfs dfs -ls /wordcount_output
# --
Found 2 items
-rw-r--r--   1 root supergroup          0 2025-12-15 13:51 /wordcount_output/_SUCCESS
-rw-r--r--   1 root supergroup        165 2025-12-15 13:51 /wordcount_output/part-r-00000

hdfs dfs -cat /wordcount_output/part-r-00000
# --
.       1
Innsmouth       4
asdfafawqe.     1
sdafas  1
sdfaf   1
wertwhewg       1
wretrt  1
солhgjk.        1
```

## #5
```bash
hdfs dfs -cat /wordcount_output/part-r-00000 | grep -w "Innsmouth" | awk '{print $2}' > /tmp/count.txt
if [ ! -s /tmp/count.txt ]; 
then 
    echo 0 > /tmp/count.txt; 
fi
hdfs dfs -put /tmp/count.txt /whataboutinsmouth.txt
hdfs dfs -cat /whataboutinsmouth.txt
# --
4
```