#!/usr/bin/env bash
set -e

################################################################################
# ДЗ 4. ClickHouse
# Все задания и решения собраны в одном скрипте
################################################################################

CH="docker exec -i ch1 clickhouse-client"

################################################################################
# Упражнение 1. Запуск и проверка подключения
################################################################################

# 1. Создать базу данных
$CH --query "
CREATE DATABASE IF NOT EXISTS dz4;
SHOW DATABASES;
"

################################################################################
# 2. Создать таблицу с движком MergeTree
################################################################################

$CH --query "
CREATE TABLE IF NOT EXISTS dz4.events_mt
(
    int_val   UInt32,
    uuid_val  UUID,
    dt_val    DateTime,
    str_val   LowCardinality(String)
)
ENGINE = MergeTree
ORDER BY (dt_val, str_val);
"

################################################################################
# 3. Проверить структуру таблицы
################################################################################

$CH --query "DESCRIBE TABLE dz4.events_mt;"

################################################################################
# 4. Заполнить таблицу тестовыми данными
################################################################################

$CH --query "
INSERT INTO dz4.events_mt (int_val, uuid_val, dt_val, str_val)
SELECT
    modulo(rand(), 999) + 1 AS int_val,
    generateUUIDv4() AS uuid_val,
    now() - INTERVAL rand() / 1000 SECOND AS dt_val,
    multiIf(
        int_val_2 <= 1500, 'A',
        int_val_2 <= 3000, 'B',
        int_val_2 <= 4500, 'C',
        int_val_2 <= 6000, 'D',
        int_val_2 <= 7300, 'E',
        'F'
    ) AS str_val
FROM
(
    SELECT
        rand() / 500000 AS int_val_2
    FROM numbers(1000000)
);
"

################################################################################
# 5. Аналитический запрос с группировкой и агрегатами
################################################################################

$CH --query "
SELECT
    str_val,
    count() AS rows,
    uniqExact(uuid_val) AS uniq_users
FROM dz4.events_mt
GROUP BY str_val
ORDER BY rows DESC;
"

################################################################################
# 6. Проверка системных таблиц
################################################################################

$CH --query "SELECT * FROM system.clusters;"
$CH --query "SELECT * FROM system.macros;"
$CH --query "SELECT * FROM system.zookeeper;"
$CH --query "SELECT * FROM system.distributed_ddl_queue;"
$CH --query "SELECT * FROM system.replication_queue;"
$CH --query "SELECT * FROM system.trace_log LIMIT 10;"

################################################################################
# 7. Проверка функций getMacro и clusterAllReplicas
################################################################################

$CH --query "
SELECT
    getMacro('cluster') AS cluster,
    getMacro('shard')   AS shard,
    getMacro('replica') AS replica;
"

$CH --query "
SELECT *
FROM clusterAllReplicas('default', system.one);
"

################################################################################
# 8. Анализ метрик (query_log, parts, parts_columns)
################################################################################

$CH --query "
SELECT
    event_time,
    query_duration_ms,
    memory_usage,
    read_rows,
    read_bytes,
    query
FROM system.query_log
WHERE type = 'QueryFinish'
  AND query LIKE '%events_mt%'
ORDER BY event_time DESC
LIMIT 5;
"

$CH --query "
SELECT
    table,
    formatReadableSize(sum(data_compressed_bytes))   AS compressed,
    formatReadableSize(sum(data_uncompressed_bytes)) AS uncompressed,
    formatReadableSize(sum(primary_key_bytes_in_memory)) AS pk_memory
FROM system.parts
WHERE database = 'dz4'
  AND table = 'events_mt'
  AND active
GROUP BY table;
"

$CH --query "
SELECT
    column,
    formatReadableSize(sum(data_compressed_bytes))   AS compressed,
    formatReadableSize(sum(data_uncompressed_bytes)) AS uncompressed
FROM system.parts_columns
WHERE database = 'dz4'
  AND table = 'events_mt'
GROUP BY column
ORDER BY column;
"

################################################################################
# Упражнение 2. Размер вставки
################################################################################

# 9. Две таблицы MergeTree

$CH --query "
CREATE TABLE IF NOT EXISTS dz4.mt_small
(
    int_val   UInt32,
    uuid_val  UUID,
    dt_val    DateTime,
    str_val   String
)
ENGINE = MergeTree
ORDER BY dt_val;
"

$CH --query "
CREATE TABLE IF NOT EXISTS dz4.mt_big
(
    int_val   UInt32,
    uuid_val  UUID,
    dt_val    DateTime,
    str_val   String
)
ENGINE = MergeTree
ORDER BY dt_val;
"

################################################################################
# 10. Таблица Buffer
################################################################################

$CH --query "
CREATE TABLE IF NOT EXISTS dz4.buf_big
AS dz4.mt_big
ENGINE = Buffer(
    dz4, mt_big,
    16,
    5,
    60,
    10000,
    200000,
    1000000,
    10000000
);
"

################################################################################
# 11. Параллельная вставка (мелкие и крупные пачки)
################################################################################

DURATION=300
echo \"Starting insert experiment for \$DURATION seconds\"

insert_small_batches() {
  end=\$((SECONDS + DURATION))
  while [ \$SECONDS -lt \$end ]; do
    $CH --query \"
      INSERT INTO dz4.mt_small
      SELECT
        modulo(rand(), 1000),
        generateUUIDv4(),
        now(),
        'small_batch'
      FROM numbers(1000);
    \" >/dev/null
  done
}

insert_large_batches() {
  end=\$((SECONDS + DURATION))
  while [ \$SECONDS -lt \$end ]; do
    $CH --query \"
      INSERT INTO dz4.buf_big
      SELECT
        modulo(rand(), 1000),
        generateUUIDv4(),
        now(),
        'large_batch'
      FROM numbers(200000);
    \" >/dev/null
  done
}

insert_small_batches &
insert_large_batches &
wait

echo \"Insert experiment finished\"

################################################################################
# Проверка количества данных и партиций
################################################################################

$CH --query "
SELECT 'mt_small' AS table_name, count() FROM dz4.mt_small
UNION ALL
SELECT 'mt_big', count() FROM dz4.mt_big;
"

$CH --query "
SELECT
    table,
    countIf(active) AS active_parts,
    countIf(NOT active) AS inactive_parts
FROM system.parts
WHERE database = 'dz4'
  AND table IN ('mt_small','mt_big')
GROUP BY table
ORDER BY table;
"

################################################################################
# Упражнение 3. Оптимизация ORDER BY
################################################################################

# 15. Таблица person_data

$CH --query "
CREATE TABLE IF NOT EXISTS default.person_data
(
    id          UInt64,
    region      LowCardinality(String),
    date_birth  Date,
    gender      UInt8,
    is_marital  UInt8,
    dt_create   DateTime DEFAULT now()
)
ENGINE = MergeTree
ORDER BY date_birth;
"

################################################################################
# 16. Заполнение данными
################################################################################

$CH --query "
INSERT INTO default.person_data (id, region, date_birth, gender, is_marital)
SELECT
    rand(),
    toString(modulo(rand(), 70) + 20),
    toDate('1970-01-01') + INTERVAL floor(randNormal(10000,1700)) DAY,
    if(modulo(rand(),3)=1,1,0),
    if(modulo(rand(),3)=0,1,0)
FROM numbers(10000000);
"

################################################################################
# 17. OPTIMIZE FINAL
################################################################################

$CH --query "OPTIMIZE TABLE default.person_data FINAL;"

################################################################################
# 18–19. Анализ и оптимизация ORDER BY
################################################################################

$CH --query "
CREATE TABLE IF NOT EXISTS default.person_data_opt
AS default.person_data
ENGINE = MergeTree
ORDER BY (region, date_birth);
"

$CH --query "
INSERT INTO default.person_data_opt
SELECT * FROM default.person_data;
"

$CH --query "OPTIMIZE TABLE default.person_data_opt FINAL;"

################################################################################
# Конец скрипта
################################################################################

echo "All tasks completed successfully"
