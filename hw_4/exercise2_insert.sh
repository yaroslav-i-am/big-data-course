#!/usr/bin/env bash

DURATION=300

echo "Starting parallel insert experiment for $DURATION seconds"

insert_small_batches() {
  end=$((SECONDS + DURATION))
  while [ $SECONDS -lt $end ]; do
    docker exec -i ch1 clickhouse-client --query "
      INSERT INTO dz4.mt_small
      SELECT
        modulo(rand(), 1000),
        generateUUIDv4(),
        now(),
        'small_batch'
      FROM numbers(1000);
    " >/dev/null
  done
}

insert_large_batches() {
  end=$((SECONDS + DURATION))
  while [ $SECONDS -lt $end ]; do
    docker exec -i ch1 clickhouse-client --query "
      INSERT INTO dz4.buf_big
      SELECT
        modulo(rand(), 1000),
        generateUUIDv4(),
        now(),
        'large_batch'
      FROM numbers(200000);
    " >/dev/null
  done
}

insert_small_batches &
insert_large_batches &
wait

echo "Insert experiment finished"

