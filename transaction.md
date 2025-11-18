# Дз транзакции от Дамира

## 1. Транзакции

### 1.1. Базовая транзакция

Идейно:

- Регистрируем нового клиента
- Регистрируем его машину
- Создаём заказ
- Прикрепляем задачи к заказу

```sql
BEGIN;

WITH now_customer AS (
    INSERT INTO autoservice_schema.customer (full_name, phone_number)
        VALUES ('Паровозов Аркадий', '+7-800-555-35-35')
        RETURNING id),
     now_car AS (
         INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id)
             SELECT upper(substr(md5(random()::text), 1, 17)) AS random_vin, ' Patriot', 'A001BC30', 'ожидает', 1
             RETURNING vin),
     now_order AS (
         INSERT INTO autoservice_schema."order" (customer_id, creation_date, description)
             SELECT c.id, '2025-11-18 10:00:00.000000', 'Полное ТО'
             FROM now_customer c
             RETURNING id),
     now_task1 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 2500, 8, 'Смена резины на зимнюю', c.vin
             FROM now_order o
                      CROSS JOIN now_car c),
     now_task2 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 5000, 11, 'Проверка АКБ и генератора', c.vin
             FROM now_order o
                      CROSS JOIN now_car c),
     now_task3 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 3000, 2, 'Компьютерная диагностика двигателя', c.vin
             FROM now_order o
                      CROSS JOIN now_car c)

SELECT *
FROM autoservice_schema.customer
LIMIT 1;

COMMIT;
```

### 1.2. Rollback транзакция

Просто поменяли COMMIT на ROLLBACK

```sql
BEGIN;

WITH now_customer AS (
    INSERT INTO autoservice_schema.customer (full_name, phone_number)
        VALUES ('Паровозов Аркадий', '+7-800-555-35-35')
        RETURNING id),
     now_car AS (
         INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id)
             SELECT upper(substr(md5(random()::text), 1, 17)) AS random_vin, ' Patriot', 'A001BC30', 'ожидает', 1
             RETURNING vin),
     now_order AS (
         INSERT INTO autoservice_schema."order" (customer_id, creation_date, description)
             SELECT c.id, '2025-11-18 10:00:00.000000', 'Полное ТО'
             FROM now_customer c
             RETURNING id),
     now_task1 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 2500, 8, 'Смена резины на зимнюю', c.vin
             FROM now_order o
                      CROSS JOIN now_car c),
     now_task2 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 5000, 11, 'Проверка АКБ и генератора', c.vin
             FROM now_order o
                      CROSS JOIN now_car c),
     now_task3 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 3000, 2, 'Компьютерная диагностика двигателя', c.vin
             FROM now_order o
                      CROSS JOIN now_car c)

SELECT *
FROM autoservice_schema.customer
LIMIT 1;

ROLLBACK;
```

### 1.3. Ошибка в транзакции

Поменяли корректную дату заказа (2025-11-18 10:00:00.000000) на (-15454)

```sql
BEGIN;

WITH now_customer AS (
    INSERT INTO autoservice_schema.customer (full_name, phone_number)
        VALUES ('Паровозов Аркадий', '+7-800-555-35-35')
        RETURNING id),
     now_car AS (
         INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id)
             SELECT upper(substr(md5(random()::text), 1, 17)) AS random_vin, ' Patriot', 'A001BC30', 'ожидает', 1
             RETURNING vin),
     now_order AS (
         INSERT INTO autoservice_schema."order" (customer_id, creation_date, description)
             SELECT c.id, '-15454', 'Полное ТО'
             FROM now_customer c
             RETURNING id),
     now_task1 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 2500, 8, 'Смена резины на зимнюю', c.vin
             FROM now_order o
                      CROSS JOIN now_car c),
     now_task2 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 5000, 11, 'Проверка АКБ и генератора', c.vin
             FROM now_order o
                      CROSS JOIN now_car c),
     now_task3 AS (
         INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
             SELECT o.id, 3000, 2, 'Компьютерная диагностика двигателя', c.vin
             FROM now_order o
                      CROSS JOIN now_car c)

SELECT *
FROM autoservice_schema.customer
LIMIT 1;

ROLLBACK;
```

## 2. Уровни изоляции

### 2.1. READ UNCOMMITTED

T1:
```sql
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

UPDATE autoservice_schema."order" SET description = 'Ремонт генератора/аккумулятора' WHERE "order".id = 12;

-- пока не делаем коммит
```

T2:
```sql
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT * FROM autoservice_schema."order" WHERE id = 12;
```

![img_133.png](images/img_133.png)


T1:
```sql
COMMIT;
```

T2:
```sql
SELECT * FROM autoservice_schema."order" WHERE id = 12;
```

![img_134.png](images/img_134.png)

Видим, что данные в T2 обновились только после COMMIT в T1, несмотря на выставленный уровень READ UNCOMMITTED
Вывод, postgres не разрешает READ UNCOMMITTED

### 2.2. READ COMMITTED

T1:
```sql
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT *
FROM autoservice_schema."order"
WHERE id = 12;
```

![img_127.png](images/img_127.png)

T2:
```sql
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE autoservice_schema."order" SET description = 'Ремонт аккумулятора' WHERE "order".id = 12;
COMMIT;
```

T1:
```sql
SELECT *
FROM autoservice_schema."order"
WHERE id = 12;
```

![img_128.png](images/img_128.png)

Если во время выполнения T1, другая транзакция изменит данные, то T1 будет использовать изменённые данные, что не всегда ожидаемо

### 2.3. REPEATABLE READ

#### T1 не видит изменений от T2, пока не завершится

T1:
```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT *
FROM autoservice_schema."order"
WHERE id = 12;
```
![img_129.png](images/img_129.png)

T2:
```sql
BEGIN;
UPDATE autoservice_schema."order" SET description = 'Ремонт шины' WHERE id = 12;
COMMIT;
```

T1:
```sql
SELECT * FROM autoservice_schema."order" WHERE id = 12;

COMMIT;
```

![img_130.png](images/img_130.png)

#### фантомное чтение через INSERT в T2

T1:
```sql
BEGIN;

SELECT *
FROM autoservice_schema.customer
WHERE id > 10;
```

![img_131.png](images/img_131.png)

T2:
```sql
BEGIN;
INSERT INTO autoservice_schema.customer (full_name, phone_number) VALUES ('Гарри Поттер', '+44 7700 900000');
COMMIT;
```

T1:
```sql
SELECT *
FROM autoservice_schema.customer
WHERE id > 10;

COMMIT;
```

![img_132.png](images/img_132.png)

Можно сделать вывод, что в postgres при уровне REPEATABLE READ фантомное чтение невозможно, несмотря на таблицу
Для этого нужно понизить уровень изоляции до READ COMMITTED


### 2.4. SERIALIZABLE

T1:
```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

UPDATE autoservice_schema.customer SET full_name = 'Паровозов Оркадий' WHERE id = 15;

-- запускаем T2
```

T2:
```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

UPDATE autoservice_schema.customer SET full_name = 'Паровозов Олладий' WHERE id = 15;

COMMIT;
```

Здесь запрос не выполнялся, пока не дождался коммита на предыдущем

![img_135.png](images/img_135.png)

T1:
```sql
COMMIT;
```

Теперь выполнился T2 и вызвал ошибку could not serialize access due to concurrent update

![img_136.png](images/img_136.png)

Повторим T2
```sql
ROLLBACK;
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

UPDATE autoservice_schema.customer SET full_name = 'Паровозов Олладий' WHERE id = 15;

COMMIT;
```
Успешно
![img_137.png](images/img_137.png)


## 3. SAVEPOINT

Изначально таблица выглядит так:

![img_138.png](images/img_138.png)


```sql
BEGIN;

SAVEPOINT before_update1;
UPDATE autoservice_schema.customer SET full_name = 'Паровозов Палладий' WHERE id = 15;

SAVEPOINT before_update2;
UPDATE autoservice_schema.customer SET full_name = 'Паровозов Палладий' WHERE id = 20;
SELECT *
FROM autoservice_schema.customer
WHERE id >= 15;
```

![img_139.png](images/img_139.png)


Откатываемся до первой точки сохранения
```sql
ROLLBACK TO before_update1;

SELECT *
FROM autoservice_schema.customer
WHERE id >= 15;
```

![img_140.png](images/img_140.png)

Откатываемся до второй сохранения
```sql
ROLLBACK TO before_update2;

SELECT *
FROM autoservice_schema.customer
WHERE id >= 15;
```

![img_141.png](images/img_141.png)

Ожидаемо ловим ошибку, так как, откатившивсь на первую точку сохранения бд уже не знает о существовании второй, объявленной позже

