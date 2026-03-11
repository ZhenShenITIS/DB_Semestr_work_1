### 1-2. Моделирование обновления данных и изучение xmin, xmax, ctid, t_infomask

**Состояние строки до обновления**

```sql
SELECT t_xmin AS xmin, t_xmax AS xmax, t_ctid AS ctid, t_infomask
FROM heap_page_items(get_raw_page('autoservice_schema.worker', 0))
OFFSET 47 LIMIT 3;

```

**Результат:**

```sql
 xmin | xmax |  ctid  | t_infomask 
------+------+--------+------------
  766 |  770 | (0,48) |        402
  766 |  770 | (0,49) |        402
  766 |    0 | (0,50) |       2306
(3 rows)
```

```sql
UPDATE autoservice_schema.worker SET role = 'Senior Mechanic' WHERE id = 1;
```

**Состояние строки после обновления**

```sql
SELECT t_xmin AS xmin, t_xmax AS xmax, t_ctid AS ctid, t_infomask
FROM heap_page_items(get_raw_page('autoservice_schema.worker', 0))
OFFSET 47 LIMIT 4;
```

**Результат:**
```sql
 xmin | xmax |  ctid  | t_infomask 
------+------+--------+------------
  766 |  770 | (0,48) |       2450
  766 |  770 | (0,49) |       2450
  766 |    0 | (0,50) |       2306
  821 |    0 | (0,51) |      10498
```


---


### 3. Видимость в разных транзакциях

**Терминал 1 (Начинает транзакцию и делает UPDATE):**

```sql
BEGIN;
UPDATE autoservice_schema.worker SET role = 'Lead Mechanic' WHERE id = 1;
SELECT xmin, xmax, ctid, role FROM autoservice_schema.worker WHERE id = 1;
```

**Результат Терминала 1:**

```sql
 xmin | xmax |  ctid  |     role      
------+------+--------+---------------
  823 |    0 | (0,52) | Lead Mechanic
```

**Терминал 2 (Пытается прочитать те же данные параллельно):**

```sql
BEGIN;
SELECT xmin, xmax, ctid, role FROM autoservice_schema.worker WHERE id = 1;
```

**Результат Терминала 2:**

```sql
 xmin | xmax |  ctid  |      role       
------+------+--------+-----------------
  821 |  823 | (0,51) | Senior Mechanic
```

---

### 4. Deadlock

Имитация перекрестного обновления двух строк в двух сессиях.

Терминал 1: `BEGIN; UPDATE autoservice_schema.worker SET role = 'Master' WHERE id = 1;`
Терминал 2: `BEGIN; UPDATE autoservice_schema.worker SET role = 'Master' WHERE id = 2;`
Терминал 1: `UPDATE autoservice_schema.worker SET role = 'Director' WHERE id = 2;` (Транзакция зависнет, так как строка id=2 заблокирована Терминалом 2)
Терминал 2: `UPDATE autoservice_schema.worker SET role = 'Director' WHERE id = 1;` (Здесь сработает детектор дедлоков)
**Результат в логах PostgreSQL:**

```text
ERROR:  deadlock detected
DETAIL:  Process 335 waits for ShareLock on transaction 824; blocked by process 2670.
Process 2670 waits for ShareLock on transaction 825; blocked by process 335.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,51) in relation "worker"
```

Анализ: PostgreSQL автоматически обнаружил цикличное ожидание и принудительно прервал транзакцию в одном из окон с ошибкой, чтобы позволить второму процессу продолжить работу

---

### 5. Явные блокировки на уровне строк

**Терминал 1 (Блокировка на обновление):**

```sql
BEGIN;
SELECT * FROM autoservice_schema.worker WHERE id = 1 FOR UPDATE;
```

**Терминал 2:**

```sql
BEGIN;
SELECT * FROM autoservice_schema.worker WHERE id = 1 FOR SHARE;
```
зависание

Также я попробовал сделать
```sql
SELECT * FROM autoservice_schema.worker WHERE id = 1;
```
и получил результат

Это происходит потому что FOR UPDATE не дает навесить другие блокировки на строки, с которыми он работает и запрос с FOR SHARE ждет. Обычный селект работает без блокировок и работает со снимком до начала первой транзакции

---

### 6. Очистка данных (VACUUM)

```sql
VACUUM VERBOSE autoservice_schema.worker;
```

**Результат:**

```text
INFO:  vacuuming "autoservice.autoservice_schema.worker"
INFO:  finished vacuuming "autoservice.autoservice_schema.worker": index scans: 0
pages: 0 removed, 1 remain, 1 scanned (100.00% of total)
tuples: 5 removed, 50 remain, 0 are dead but not yet removable
```
