### Запрос 1: Полнотекстовый поиск (TSVECTOR)

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.car 
WHERE description_search @@ to_tsquery('noise & oil');
```

#### Без индекса
```sql
                                                          QUERY PLAN                                                          
------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..83058.50 rows=300000 width=310) (actual time=0.995..230.331 rows=300000 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=11237 read=8359
   ->  Parallel Seq Scan on car  (cost=0.00..52058.50 rows=125000 width=310) (actual time=0.414..184.982 rows=100000 loops=3)
         Filter: (description_search @@ to_tsquery('noise & oil'::text))
         Buffers: shared hit=11237 read=8359
 Planning Time: 0.415 ms
 Execution Time: 240.447 ms
(9 rows)
```

#### Создание индекса GIN для полнотекстового поиска
 ```sql
CREATE INDEX idx_car_fts_gin ON autoservice_schema.car USING GIN (description_search);
```

#### Создание индекса GIST для полнотекстового поиска
```sql
CREATE INDEX idx_car_fts_gist ON autoservice_schema.car USING GIST (description_search);
```

#### Оба индекса не работают, так как лексемы noise и oil встречаются в каждой строке, и планировщик выбирает последовательное сканирование. В данном случае индексы неэффективны, так как они не могут сузить поиск до меньшего количества строк.

#### Но если заменить запрос на: 
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.car 
WHERE description_search @@ to_tsquery('30063');
```

#### Без индекса
```sql
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..53208.50 rows=1500 width=310) (actual time=102.913..106.101 rows=1 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=10797 read=8757
   ->  Parallel Seq Scan on car  (cost=0.00..52058.50 rows=625 width=310) (actual time=82.967..83.069 rows=0 loops=3)
         Filter: (description_search @@ to_tsquery('30063'::text))
         Rows Removed by Filter: 100000
         Buffers: shared hit=10797 read=8757
 Planning Time: 0.271 ms
 Execution Time: 106.136 ms
(10 rows)
```

#### С индексом (планировщик выбрал gin индекс, потому что он быстрее когда нужно найти отдельные элементы как в нашем случае номер)
```sql
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on car  (cost=25.22..5008.38 rows=1500 width=310) (actual time=0.162..0.170 rows=1 loops=1)
   Recheck Cond: (description_search @@ to_tsquery('30063'::text))
   Heap Blocks: exact=1
   Buffers: shared hit=5
   ->  Bitmap Index Scan on idx_car_fts_gin  (cost=0.00..24.85 rows=1500 width=0) (actual time=0.090..0.090 rows=1 loops=1)
         Index Cond: (description_search @@ to_tsquery('30063'::text))
         Buffers: shared hit=4
 Planning:
   Buffers: shared hit=1
 Planning Time: 1.196 ms
 Execution Time: 0.347 ms
(11 rows)
```


### Запрос 2: Поиск по массивам (Array)

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.customer 
WHERE tags @> '{tuning}';
```

#### без индекса
```sql
                                                   QUERY PLAN                                                   
----------------------------------------------------------------------------------------------------------------
 Seq Scan on customer  (cost=0.00..8947.00 rows=55933 width=155) (actual time=0.167..62.370 rows=55871 loops=1)
   Filter: (tags @> '{tuning}'::text[])
   Rows Removed by Filter: 194129
   Buffers: shared hit=128 read=5694
 Planning Time: 0.324 ms
 Execution Time: 65.390 ms
(6 rows)
```


#### gin

```sql
CREATE INDEX idx_cust_tags_gin ON autoservice_schema.customer USING GIN (tags);
```

```sql
                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on customer  (cost=384.67..6905.83 rows=55933 width=155) (actual time=7.222..35.674 rows=55871 loops=1)
   Recheck Cond: (tags @> '{tuning}'::text[])
   Heap Blocks: exact=5822
   Buffers: shared hit=5798 read=35
   ->  Bitmap Index Scan on idx_cust_tags_gin  (cost=0.00..370.68 rows=55933 width=0) (actual time=6.254..6.254 rows=55871 loops=1)
         Index Cond: (tags @> '{tuning}'::text[])
         Buffers: shared hit=11
 Planning:
   Buffers: shared hit=1
 Planning Time: 0.291 ms
 Execution Time: 38.555 ms
(11 rows)

```

gin хорошо подходит для этой задачи, так как массив легко разбивается на отдельные элементы, и индекс может эффективно находить строки, содержащие нужный элемент.

#### gist
```sql
CREATE INDEX idx_cust_tags_gist ON autoservice_schema.customer USING GIST (tags);
```

```sql
ERROR:  data type text[] has no default operator class for access method "gist"
HINT:  You must specify an operator class for the index or define a default operator class for the data type.
```

пу пу пу


### Запрос 3: Поиск внутри JSONB

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.customer 
WHERE profile_data @> '{"age": 42}';
```

#### без индекса
```sql
                                                         QUERY PLAN                                                          
-----------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8480.78 rows=3567 width=155) (actual time=0.584..37.516 rows=3513 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=5822
   ->  Parallel Seq Scan on customer  (cost=0.00..7124.08 rows=1486 width=155) (actual time=0.029..15.741 rows=1171 loops=3)
         Filter: (profile_data @> '{"age": 42}'::jsonb)
         Rows Removed by Filter: 82162
         Buffers: shared hit=5822
 Planning Time: 0.232 ms
 Executio
```

#### gin
```sql
CREATE INDEX idx_cust_jsonb_gin ON autoservice_schema.customer USING GIN (profile_data);
```

```sql
                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on customer  (cost=56.43..5413.66 rows=3567 width=155) (actual time=2.916..10.480 rows=3513 loops=1)
   Recheck Cond: (profile_data @> '{"age": 42}'::jsonb)
   Heap Blocks: exact=2646
   Buffers: shared hit=2718
   ->  Bitmap Index Scan on idx_cust_jsonb_gin  (cost=0.00..55.53 rows=3567 width=0) (actual time=2.550..2.551 rows=3513 loops=1)
         Index Cond: (profile_data @> '{"age": 42}'::jsonb)
         Buffers: shared hit=72
 Planning:
   Buffers: shared hit=20 read=3
 Planning Time: 1.329 ms
 Execution Time: 10.894 ms
(11 rows)
```

ситуация аналогичная поиску по массиву - gin индекс хорошо подходит для поиска по JSONB, так как он может эффективно индексировать ключи и значения внутри JSON, что позволяет быстро находить строки, соответствующие заданному условию.

#### gist
```sql
CREATE INDEX idx_cust_jsonb_gist ON autoservice_schema.customer USING GIST (profile_data);
```
```sql
ERROR:  data type jsonb has no default operator class for access method "gist"
HINT:  You must specify an operator class for the index or define a default operator class for the data type.
```
пу пу пу


### Запрос 4: Пересечение диапазонов (Range Types)

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.task 
WHERE estimated_cost_range && '[1000, 1500)'::numrange;
```

#### без индекса
```sql
                                                  QUERY PLAN                                                  
--------------------------------------------------------------------------------------------------------------
 Seq Scan on task  (cost=0.00..11154.00 rows=103141 width=92) (actual time=0.024..71.499 rows=102261 loops=1)
   Filter: (estimated_cost_range && '[1000,1500)'::numrange)
   Rows Removed by Filter: 297739
   Buffers: shared hit=291 read=5863
 Planning Time: 0.123 ms
 Execution Time: 75.058 ms
(6 rows)
```

#### gin 
```sql
ERROR:  data type numrange has no default operator class for access method "gin"
HINT:  You must specify an operator class for the index or define a default operator class for the data type.
```
gin для таких приколов не подходит, он не может превратить диапазон в отдельные элементы, так как диапазон - это непрерывный интервал, и его нельзя разбить на дискретные части для индексирования.


#### gist
```sql
CREATE INDEX idx_task_cost_gist ON autoservice_schema.task USING GIST (estimated_cost_range);
```

```sql
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on task  (cost=3167.63..10610.89 rows=103141 width=92) (actual time=28.699..60.107 rows=102261 loops=1)
   Recheck Cond: (estimated_cost_range && '[1000,1500)'::numrange)
   Heap Blocks: exact=6154
   Buffers: shared hit=6751
   ->  Bitmap Index Scan on idx_task_cost_gist  (cost=0.00..3141.84 rows=103141 width=0) (actual time=27.818..27.819 rows=102261 loops=1)
         Index Cond: (estimated_cost_range && '[1000,1500)'::numrange)
         Buffers: shared hit=597
 Planning Time: 0.310 ms
 Execution Time: 64.099 ms
(9 rows)
```
ну глист в целом для таких задач и придуман - он может эффективно индексировать диапазоны и поддерживать операции пересечения, что позволяет быстро находить строки, где диапазоны пересекаются с заданным диапазоном.




#### Запрос 5: Решение проблемы с %LIKE% (Триграммы)
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM autoservice_schema.car 
WHERE history_log LIKE '%recall%';

```


#### БЕЗ
```sql
                                                      QUERY PLAN                                                       
-----------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..21811.50 rows=30 width=310) (actual time=57.191..60.437 rows=2997 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   Buffers: shared hit=3059 read=16187
   ->  Parallel Seq Scan on car  (cost=0.00..20808.50 rows=12 width=310) (actual time=39.603..39.988 rows=999 loops=3)
         Filter: (history_log ~~ '%recall%'::text)
         Rows Removed by Filter: 99001
         Buffers: shared hit=3059 read=16187
 Planning Time: 0.375 ms
 Execution Time: 60.611 ms
(10 rows)
```

#### gist
```sql
CREATE INDEX idx_car_log_gist_trgm ON autoservice_schema.car USING GIST (history_log gist_trgm_ops);

```
```sql
                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on car  (cost=8.64..125.46 rows=30 width=310) (actual time=18.199..20.574 rows=2997 loops=1)
   Recheck Cond: (history_log ~~ '%recall%'::text)
   Heap Blocks: exact=144
   Buffers: shared hit=1515
   ->  Bitmap Index Scan on idx_car_log_gist_trgm  (cost=0.00..8.63 rows=30 width=0) (actual time=18.121..18.122 rows=2997 loops=1)
         Index Cond: (history_log ~~ '%recall%'::text)
         Buffers: shared hit=1371
 Planning Time: 0.344 ms
 Execution Time: 20.834 ms
(9 rows)

```

#### gin
```sql
CREATE INDEX idx_car_log_gin_trgm ON autoservice_schema.car USING GIN (history_log gin_trgm_ops);

```

```sql
                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on car  (cost=80.26..197.08 rows=30 width=310) (actual time=0.324..1.522 rows=2997 loops=1)
   Recheck Cond: (history_log ~~ '%recall%'::text)
   Heap Blocks: exact=144
   Buffers: shared hit=157
   ->  Bitmap Index Scan on idx_car_log_gin_trgm  (cost=0.00..80.26 rows=30 width=0) (actual time=0.292..0.292 rows=2997 loops=1)
         Index Cond: (history_log ~~ '%recall%'::text)
         Buffers: shared hit=13
 Planning:
   Buffers: shared hit=1
 Planning Time: 0.168 ms
 Execution Time: 1.669 ms
(11 rows)
```

gin лучше так как сразу точно ищет какие триграммы нам нужны, а гист ищет "примерно" и там ложно срабатывает 