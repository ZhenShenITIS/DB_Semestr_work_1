### Сравнение битри и хэш на точном совпадении

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.customer WHERE email = 'user123450@example.com';
```

```sql
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8124.18 rows=1 width=155) (actual time=38.031..53.210 rows=1 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=96 read=5726
   ->  Parallel Seq Scan on customer  (cost=0.00..7124.08 rows=1 width=155) (actual time=36.618..40.945 rows=0 loops=3)
         Filter: ((email)::text = 'user123450@example.com'::text)
         Rows Removed by Filter: 83333
         Buffers: shared hit=96 read=5726
 Planning Time: 0.787 ms
 Execution Time: 53.425 ms

```

```sql
CREATE INDEX idx_customer_email_hash ON autoservice_schema.customer USING HASH (email);
```


```sql
                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_customer_email_hash on customer  (cost=0.00..8.02 rows=1 width=155) (actual time=0.198..0.199 rows=1 loops=1)
   Index Cond: ((email)::text = 'user123450@example.com'::text)
   Buffers: shared hit=2 read=1
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.764 ms
 Execution Time: 0.377 ms
```

```sql
CREATE INDEX idx_customer_email_btree ON autoservice_schema.customer USING BTREE (email);
```

```sql
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_customer_email_btree on customer  (cost=0.42..8.44 rows=1 width=155) (actual time=0.358..0.360 rows=1 loops=1)
   Index Cond: ((email)::text = 'user123450@example.com'::text)
   Buffers: shared hit=4
 Planning Time: 1.017 ms
 Execution Time: 0.603 ms

```


### Диапазон

```sql
 EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.task WHERE difficulty_score > 90 AND difficulty_score < 95;
```

```sql
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..11190.00 rows=15360 width=92) (actual time=0.958..40.299 rows=16039 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=6154
   ->  Parallel Seq Scan on task  (cost=0.00..8654.00 rows=6400 width=92) (actual time=0.049..28.264 rows=5346 loops=3)
         Filter: ((difficulty_score > 90) AND (difficulty_score < 95))
         Rows Removed by Filter: 127987
         Buffers: shared hit=6154
 Planning Time: 0.313 ms
 Execution Time: 41.803 ms
```

Добавлять хэш-индекс нет смысла, так как СУБД его даже не выберет, будет использовать seq scan

```sql
CREATE INDEX idx_task_diff_hash ON autoservice_schema.task USING HASH (difficulty_score);
```



```sql
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..11190.00 rows=15360 width=92) (actual time=1.231..49.285 rows=16039 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=6154
   ->  Parallel Seq Scan on task  (cost=0.00..8654.00 rows=6400 width=92) (actual time=0.153..36.736 rows=5346 loops=3)
         Filter: ((difficulty_score > 90) AND (difficulty_score < 95))
         Rows Removed by Filter: 127987
         Buffers: shared hit=6154
 Planning Time: 0.644 ms
 Execution Time: 50.592 ms

```

```sql
CREATE INDEX idx_task_diff_btree ON autoservice_schema.task (difficulty_score);
```

```sql
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on task  (cost=213.86..6598.26 rows=15360 width=92) (actual time=1.542..14.679 rows=16039 loops=1)
   Recheck Cond: ((difficulty_score > 90) AND (difficulty_score < 95))
   Heap Blocks: exact=5725
   Buffers: shared hit=5741
   ->  Bitmap Index Scan on idx_task_diff_btree  (cost=0.00..210.02 rows=15360 width=0) (actual time=0.887..0.887 rows=16039 loops=1)
         Index Cond: ((difficulty_score > 90) AND (difficulty_score < 95))
         Buffers: shared hit=16
 Planning Time: 0.191 ms
 Execution Time: 15.354 ms
(9 rows)

```


### Оператор IN 

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.car WHERE model IN ('Model-10', 'Model-50');
```

```sql
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..9563.50 rows=6180 width=171) (actual time=1.094..21.578 rows=5997 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=384 read=5999
   ->  Parallel Seq Scan on car  (cost=0.00..7945.50 rows=2575 width=171) (actual time=0.218..14.690 rows=1999 loops=3)
         Filter: ((model)::text = ANY ('{Model-10,Model-50}'::text[]))
         Rows Removed by Filter: 98001
         Buffers: shared hit=384 read=5999
 Planning Time: 0.292 ms
 Execution Time: 21.925 ms
```

```sql
CREATE INDEX idx_car_model_hash ON autoservice_schema.car USING HASH (model);
```


```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.car WHERE model IN ('Model-10', 'Model-50');
                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on car  (cost=191.89..6835.89 rows=6180 width=171) (actual time=0.911..7.477 rows=5997 loops=1)
   Recheck Cond: ((model)::text = ANY ('{Model-10,Model-50}'::text[]))
   Heap Blocks: exact=3945
   Buffers: shared hit=3961
   ->  Bitmap Index Scan on idx_car_model_hash  (cost=0.00..190.35 rows=6180 width=0) (actual time=0.496..0.496 rows=5997 loops=1)
         Index Cond: ((model)::text = ANY ('{Model-10,Model-50}'::text[]))
         Buffers: shared hit=16
 Planning Time: 0.339 ms
 Execution Time: 7.717 ms
(9 rows)

```

```sql
CREATE INDEX idx_car_model ON autoservice_schema.car (model);
```

```sql
                                                         QUERY PLAN                                                          
-----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on car  (cost=72.74..6716.73 rows=6180 width=171) (actual time=3.231..10.501 rows=5997 loops=1)
   Recheck Cond: ((model)::text = ANY ('{Model-10,Model-50}'::text[]))
   Heap Blocks: exact=3945
   Buffers: shared hit=3957
   ->  Bitmap Index Scan on idx_car_model  (cost=0.00..71.19 rows=6180 width=0) (actual time=0.933..0.933 rows=5997 loops=1)
         Index Cond: ((model)::text = ANY ('{Model-10,Model-50}'::text[]))
         Buffers: shared hit=12
 Planning Time: 0.517 ms
 Execution Time: 10.800 ms
(9 rows)

```



### LIKE prefix%
```sql
 EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.car WHERE vin LIKE 'VIN000000123%';

```
```sql
                                                     QUERY PLAN                                                     
--------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8948.50 rows=30 width=171) (actual time=22.828..25.093 rows=0 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=4600 read=1783
   ->  Parallel Seq Scan on car  (cost=0.00..7945.50 rows=12 width=171) (actual time=17.413..17.413 rows=0 loops=3)
         Filter: ((vin)::text ~~ 'VIN000000123%'::text)
         Rows Removed by Filter: 100000
         Buffers: shared hit=4600 read=1783
 Planning Time: 0.428 ms
 Execution Time: 25.147 ms

```

```sql
CREATE INDEX idx_car_vin_hash ON autoservice_schema.car USING HASH (vin);
```

```sql
                                                     QUERY PLAN                                                     
--------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8948.50 rows=30 width=171) (actual time=42.493..45.328 rows=0 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=4696 read=1687
   ->  Parallel Seq Scan on car  (cost=0.00..7945.50 rows=12 width=171) (actual time=34.935..34.935 rows=0 loops=3)
         Filter: ((vin)::text ~~ 'VIN000000123%'::text)
         Rows Removed by Filter: 100000
         Buffers: shared hit=4696 read=1687
 Planning Time: 1.301 ms
 Execution Time: 45.510 ms

```
хэш индекс не поможет, так как он ищет точные совпадения, а у нас стоит оператор LIKE, который ищет по шаблону, поэтому индекс не может сузить область поиска


```sql
CREATE INDEX idx_car_vin_btree ON autoservice_schema.car USING BTREE (vin varchar_pattern_ops);
```

```sql
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_car_vin_btree on car  (cost=0.42..8.44 rows=30 width=171) (actual time=0.079..0.080 rows=0 loops=1)
   Index Cond: (((vin)::text ~>=~ 'VIN000000123'::text) AND ((vin)::text ~<~ 'VIN000000124'::text))
   Filter: ((vin)::text ~~ 'VIN000000123%'::text)
   Buffers: shared hit=3
 Planning Time: 0.430 ms
 Execution Time: 0.145 ms

```






### %LIKE

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.customer WHERE phone_number LIKE '%7000';
```

```sql
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8126.58 rows=25 width=155) (actual time=5.127..25.330 rows=25 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=385 read=5437
   ->  Parallel Seq Scan on customer  (cost=0.00..7124.08 rows=10 width=155) (actual time=1.989..17.543 rows=8 loops=3)
         Filter: ((phone_number)::text ~~ '%7000'::text)
         Rows Removed by Filter: 83325
         Buffers: shared hit=385 read=5437
 Planning Time: 0.306 ms
 Execution Time: 25.415 ms

```

```sql
CREATE INDEX idx_customer_phone_hash ON autoservice_schema.customer USING HASH (phone_number);
```

```sql
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8126.58 rows=25 width=155) (actual time=3.695..16.921 rows=25 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=289 read=5533
   ->  Parallel Seq Scan on customer  (cost=0.00..7124.08 rows=10 width=155) (actual time=1.816..11.311 rows=8 loops=3)
         Filter: ((phone_number)::text ~~ '%7000'::text)
         Rows Removed by Filter: 83325
         Buffers: shared hit=289 read=5533
 Planning Time: 0.350 ms
 Execution Time: 16.998 ms
```

хэш индекс не умеет такое делать, так как ищет точные совпадения 

```sql
CREATE INDEX idx_customer_phone_btree
    ON autoservice_schema.customer USING BTREE (phone_number varchar_pattern_ops);
```

```sql
                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8126.58 rows=25 width=155) (actual time=2.770..20.932 rows=25 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=961 read=4861
   ->  Parallel Seq Scan on customer  (cost=0.00..7124.08 rows=10 width=155) (actual time=1.336..14.019 rows=8 loops=3)
         Filter: ((phone_number)::text ~~ '%7000'::text)
         Rows Removed by Filter: 83325
         Buffers: shared hit=961 read=4861
 Planning Time: 0.209 ms
 Execution Time: 20.973 ms
```

бтри тоже не поможет, так сортируется строка по началу, а у нас в начале стоит %, который может быть любым символом, поэтому индекс не может помочь, так как не может сузить область поиска


