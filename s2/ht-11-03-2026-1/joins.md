### Запрос 1: Nested Loop (Маленькая выборка)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.full_name, o.creation_date
FROM autoservice_schema.customer c
         JOIN autoservice_schema."order" o ON c.id = o.customer_id
WHERE c.id = 12345;
QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=1000.42..8474.88 rows=23 width=23) (actual time=52.322..101.087 rows=1 loops=1)
   Buffers: shared read=5645
   ->  Index Scan using customer_pkey on customer c  (cost=0.42..8.44 rows=1 width=19) (actual time=0.339..0.342 rows=1 loops=1)
         Index Cond: (id = 12345)
         Buffers: shared read=4
   ->  Gather  (cost=1000.00..8466.22 rows=23 width=12) (actual time=51.981..100.741 rows=1 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared read=5641
         ->  Parallel Seq Scan on "order" o  (cost=0.00..7463.92 rows=10 width=12) (actual time=37.702..52.997 rows=0 loops=3)
               Filter: (customer_id = 12345)
               Rows Removed by Filter: 116666
               Buffers: shared read=5641
 Planning:
   Buffers: shared hit=32 read=14 dirtied=1
 Planning Time: 5.608 ms
 Execution Time: 101.279 ms
(17 rows)
```

### Запрос 2: Hash Join (Большая выборка). Cоединяем 50 работников и 400 000 задач

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT w.full_name, t.description, t.value
FROM autoservice_schema.worker w
         JOIN autoservice_schema.task t ON w.id = t.worker_id;
QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=23.73..11235.02 rows=400000 width=60) (actual time=0.634..149.035 rows=400000 loops=1)
   Hash Cond: (t.worker_id = w.id)
   Buffers: shared read=6155 dirtied=1
   ->  Seq Scan on task t  (cost=0.00..10154.00 rows=400000 width=32) (actual time=0.197..89.184 rows=400000 loops=1)
         Buffers: shared read=6154
   ->  Hash  (cost=16.10..16.10 rows=610 width=36) (actual time=0.394..0.395 rows=50 loops=1)
         Buckets: 1024  Batches: 1  Memory Usage: 11kB
         Buffers: shared read=1 dirtied=1
         ->  Seq Scan on worker w  (cost=0.00..16.10 rows=610 width=36) (actual time=0.286..0.295 rows=50 loops=1)
               Buffers: shared read=1 dirtied=1
 Planning:
   Buffers: shared hit=93 read=7
 Planning Time: 6.331 ms
 Execution Time: 161.760 ms
(14 rows)
```

### Запрос 3: Merge Join (Большая выборка где требуются отсортированные данные).
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.id, o.id 
FROM autoservice_schema.customer c
JOIN autoservice_schema."order" o ON c.id = o.customer_id
ORDER BY c.id;
                                                                    QUERY PLAN                                                                     
---------------------------------------------------------------------------------------------------------------------------------------------------
 Merge Join  (cost=46170.42..58532.00 rows=350000 width=8) (actual time=126.293..235.511 rows=350000 loops=1)
   Merge Cond: (o.customer_id = c.id)
   Buffers: shared hit=102 read=6225, temp read=774 written=778
   ->  Sort  (cost=46158.74..47033.74 rows=350000 width=8) (actual time=126.274..151.992 rows=350000 loops=1)
         Sort Key: o.customer_id
         Sort Method: external merge  Disk: 6192kB
         Buffers: shared hit=96 read=5545, temp read=774 written=778
         ->  Seq Scan on "order" o  (cost=0.00..9141.00 rows=350000 width=8) (actual time=0.128..62.190 rows=350000 loops=1)
               Buffers: shared hit=96 read=5545
   ->  Index Only Scan using customer_pkey on customer c  (cost=0.42..6498.42 rows=250000 width=4) (actual time=0.015..36.032 rows=249998 loops=1)
         Heap Fetches: 0
         Buffers: shared hit=6 read=680
 Planning:
   Buffers: shared hit=16 read=8 dirtied=1
 Planning Time: 1.586 ms
 Execution Time: 246.4
```


### Запрос 4:  Merge Anti Join (Поиск несуществующих с условием NOT EXISTS)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.id, c.full_name 
FROM autoservice_schema.customer c
WHERE NOT EXISTS (
    SELECT 1 
    FROM autoservice_schema."order" o 
    WHERE o.customer_id = c.id
);
                                                                        QUERY PLAN                                                                        
----------------------------------------------------------------------------------------------------------------------------------------------------------
 Merge Anti Join  (cost=44.40..24553.85 rows=236812 width=19) (actual time=48.359..182.307 rows=162945 loops=1)
   Merge Cond: (c.id = o.customer_id)
   Buffers: shared hit=2065 read=5766
   ->  Index Scan using customer_pkey on customer c  (cost=0.42..12323.42 rows=250000 width=19) (actual time=0.085..98.420 rows=250000 loops=1)
         Buffers: shared hit=2060 read=5277
   ->  Index Only Scan using idx_order_customer_id on "order" o  (cost=0.42..7230.42 rows=350000 width=4) (actual time=0.101..42.457 rows=350000 loops=1)
         Heap Fetches: 0
         Buffers: shared hit=5 read=489
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.571 ms
 Execution Time: 187.302 ms
(12 rows)

```

### Запрос 5: много всякого

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT w.full_name, SUM(t.value) as total_earned
FROM autoservice_schema.worker w
JOIN autoservice_schema.task t ON w.id = t.worker_id
JOIN autoservice_schema."order" o ON t.order_id = o.id
JOIN autoservice_schema.customer c ON o.customer_id = c.id
WHERE c.loyalty_tier IN ('Gold', 'Platinum')
GROUP BY w.full_name;
                                                                                 QUERY PLAN                                                                                  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=24551.50..24603.67 rows=200 width=64) (actual time=204.117..208.262 rows=49 loops=1)
   Group Key: w.full_name
   Buffers: shared hit=7280 read=10384
   ->  Gather Merge  (cost=24551.50..24598.17 rows=400 width=64) (actual time=204.102..208.199 rows=147 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=7280 read=10384
         ->  Sort  (cost=23551.48..23551.98 rows=200 width=64) (actual time=139.741..139.753 rows=49 loops=3)
               Sort Key: w.full_name
               Sort Method: quicksort  Memory: 29kB
               Buffers: shared hit=7280 read=10384
               Worker 0:  Sort Method: quicksort  Memory: 29kB
               Worker 1:  Sort Method: quicksort  Memory: 29kB
               ->  Partial HashAggregate  (cost=23541.33..23543.83 rows=200 width=64) (actual time=139.654..139.672 rows=49 loops=3)
                     Group Key: w.full_name
                     Batches: 1  Memory Usage: 64kB
                     Buffers: shared hit=7264 read=10384
                     Worker 0:  Batches: 1  Memory Usage: 64kB
                     Worker 1:  Batches: 1  Memory Usage: 64kB
                     ->  Hash Join  (cost=14915.69..23465.14 rows=15239 width=38) (actual time=88.679..137.458 rows=12004 loops=3)
                           Hash Cond: (t.worker_id = w.id)
                           Buffers: shared hit=7264 read=10384
                           ->  Parallel Hash Join  (cost=14891.96..23401.13 rows=15239 width=10) (actual time=88.601..135.732 rows=12004 loops=3)
                                 Hash Cond: (t.order_id = o.id)
                                 Buffers: shared hit=7233 read=10384
                                 ->  Parallel Seq Scan on task t  (cost=0.00..7820.67 rows=166667 width=14) (actual time=0.069..29.061 rows=133333 loops=3)
                                       Buffers: shared hit=224 read=5930
                                 ->  Parallel Hash  (cost=14725.29..14725.29 rows=13334 width=4) (actual time=88.308..88.315 rows=10464 loops=3)
                                       Buckets: 32768  Batches: 1  Memory Usage: 1504kB
                                       Buffers: shared hit=7009 read=4454
                                       ->  Parallel Hash Join  (cost=7243.13..14725.29 rows=13334 width=4) (actual time=48.519..86.122 rows=10464 loops=3)
                                             Hash Cond: (o.customer_id = c.id)
                                             Buffers: shared hit=7009 read=4454
                                             ->  Parallel Seq Scan on "order" o  (cost=0.00..7099.33 rows=145833 width=8) (actual time=0.080..23.943 rows=116667 loops=3)
                                                   Buffers: shared hit=1187 read=4454
                                             ->  Parallel Hash  (cost=7124.08..7124.08 rows=9524 width=4) (actual time=48.336..48.337 rows=7471 loops=3)
                                                   Buckets: 32768  Batches: 1  Memory Usage: 1184kB
                                                   Buffers: shared hit=5822
                                                   ->  Parallel Seq Scan on customer c  (cost=0.00..7124.08 rows=9524 width=4) (actual time=0.059..45.311 rows=7471 loops=3)
                                                         Filter: ((loyalty_tier)::text = ANY ('{Gold,Platinum}'::text[]))
                                                         Rows Removed by Filter: 75863
                                                         Buffers: shared hit=5822
                           ->  Hash  (cost=16.10..16.10 rows=610 width=36) (actual time=0.045..0.046 rows=50 loops=3)
                                 Buckets: 1024  Batches: 1  Memory Usage: 11kB
                                 Buffers: shared hit=3
                                 ->  Seq Scan on worker w  (cost=0.00..16.10 rows=610 width=36) (actual time=0.020..0.025 rows=50 loops=3)
                                       Buffers: shared hit=3
 Planning:
   Buffers: shared hit=24
 Planning Time: 2.604 ms
 Execution Time: 208.677 ms
(51 rows)

```

по этом запросу видно, что планировщик поэтапно все делает, а не 4 таблицы напрямую джоинит