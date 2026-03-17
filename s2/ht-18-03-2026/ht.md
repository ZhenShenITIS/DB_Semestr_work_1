### Смотрим на WAL и LSN по ходу транзакции

```sql
BEGIN;

SELECT pg_current_wal_lsn() AS lsn_before; 

INSERT INTO autoservice_schema.branch_office (address, phone_number)
VALUES ('ул. Тестовая, 1', '+79991234567');

SELECT pg_current_wal_lsn() AS lsn_after_insert;

COMMIT;

SELECT pg_current_wal_lsn() AS lsn_after_commit;
```
```sql
 lsn_before 
------------
 0/441DAF60 -- 1142796128

 
  lsn_after_insert 
------------------
 0/441DB300 -- 1142797056

 
  lsn_after_commit 
------------------
 0/441DB360 -- 1142797152
```


### WAL после массовой операции
```sql
DO $$
DECLARE 
    lsn_start pg_lsn; 
    lsn_end pg_lsn;
BEGIN
    lsn_start := pg_current_wal_lsn();
    

    INSERT INTO autoservice_schema.customer (full_name, phone_number, loyalty_tier)
    SELECT 'Клиент ' || i, '+7900' || LPAD(i::text, 7, '0'), 'Bronze'
    FROM generate_series(1, 10000) i;
    
    lsn_end := pg_current_wal_lsn();
    
    RAISE NOTICE 'Сгенерировано WAL (байт): %', pg_wal_lsn_diff(lsn_end, lsn_start);
END $$;
```

```sql
NOTICE:  Сгенерировано WAL (байт): 22129560
```


### Дамп всей БД и последующее восстановление
```shell
docker exec autoservice_postgres pg_dump -U postgres -d autoservice -F c > autoservice_full.dump

docker exec -it autoservice_postgres createdb -U postgres new_autoservice

docker exec -i autoservice_postgres pg_restore -U postgres -d new_autoservice -1 < autoservice_full.dump
```

Убедимся что данные есть
```shell
docker exec -it autoservice_postgres psql -U postgres -d new_autoservice 
```

```sql
new_autoservice=# SELECT COUNT(*) FROM autoservice_schema."order";
 count  
--------
 350000
(1 row)

new_autoservice=# 
```

### Дамп структуры

```shell
docker exec autoservice_postgres createdb -U postgres new_2_autoservice

docker exec autoservice_postgres pg_dump -U postgres -d autoservice -s > schema_only.sql

docker exec -i autoservice_postgres psql -U postgres -d new_2_autoservice < schema_only.sql
```

Убедимся что схема есть, но данных нет

```sql
new_2_autoservice=# SELECT COUNT(*)
                    FROM (SELECT id
                          FROM autoservice_schema.customer
                          UNION ALL
                          SELECT box_id
                          FROM autoservice_schema.car
                          UNION ALL
                          SELECT id
                          FROM autoservice_schema."order");
count 
-------
     0
(1 row)


```


### Дамп одной таблицы
```shell
docker exec autoservice_postgres pg_dump -U postgres -d autoservice -a -t 'autoservice_schema.branch_office' > only_office.sql

docker exec -i autoservice_postgres psql -U postgres -d new_2_autoservice < only_office.sql
```

Проверяем что только 1 таблица скопировалась
```sql

new_2_autoservice=# SELECT COUNT(*)
                    FROM (SELECT id
                          FROM autoservice_schema.customer
                          UNION ALL
                          SELECT box_id
                          FROM autoservice_schema.car
                          UNION ALL
                          SELECT id
                          FROM autoservice_schema."order"
                          UNION ALL
                          SELECT id
                          FROM autoservice_schema.branch_office);
count 
-------
     6
(1 row)

```



### Seed

```sql
new_2_autoservice=# TRUNCATE autoservice_schema.branch_office CASCADE;
NOTICE:  truncate cascades to table "box"
NOTICE:  truncate cascades to table "branch_office_manager"
NOTICE:  truncate cascades to table "worker"
NOTICE:  truncate cascades to table "car"
NOTICE:  truncate cascades to table "payout"
NOTICE:  truncate cascades to table "task"
NOTICE:  truncate cascades to table "autopart"
NOTICE:  truncate cascades to table "order_car"
TRUNCATE TABLE
new_2_autoservice=#
```

#### Заполнение таблицы офисов
```sql
INSERT INTO autoservice_schema.branch_office (id, address, phone_number)
VALUES
    (1, 'г. Москва, ул. Ленина, д. 10', '+7 (999) 111-22-33'),
    (2, 'г. Санкт-Петербург, Невский пр., 45', '+7 (999) 444-55-66'),
    (3, 'г. Казань, ул. Баумана, д. 20', '+7 (999) 777-88-99')
ON CONFLICT (id)
    DO NOTHING;

SELECT setval('autoservice_schema.branch_office_id_seq', (SELECT MAX(id) FROM autoservice_schema.branch_office));
```


```sql
new_2_autoservice=# INSERT INTO autoservice_schema.branch_office (id, address, phone_number)
VALUES 
    (1, 'г. Москва, ул. Ленина, д. 10', '+7 (999) 111-22-33'),
    (2, 'г. Санкт-Петербург, Невский пр., 45', '+7 (999) 444-55-66'),
    (3, 'г. Казань, ул. Баумана, д. 20', '+7 (999) 777-88-99')
ON CONFLICT (id) 
DO NOTHING; 
INSERT 0 3
new_2_autoservice=# SELECT setval('autoservice_schema.branch_office_id_seq', (SELECT MAX(id) FROM autoservice_schema.branch_office));
 setval 
--------
      3
(1 row)

new_2_autoservice=#
```


#### Заполнение машин 
```sql
INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id, mileage)
VALUES ('VIN1234567890ABCD', 'Toyota Camry', 'А111АА77', 'in_progress', 1, 15000),
       ('VIN9876543210ZYXW', 'Hyundai Solaris', 'В222ВВ99', 'done', 2, 45000)
ON CONFLICT (vin)
    DO UPDATE SET model        = EXCLUDED.model,
                  plate_number = EXCLUDED.plate_number,
                  status       = EXCLUDED.status,
                  box_id       = EXCLUDED.box_id,
                  mileage      = EXCLUDED.mileage;
```

#### Заполнение клиентов
```sql
INSERT INTO autoservice_schema.customer (id, full_name, phone_number, email, loyalty_tier)
VALUES (1, 'Иван Иванов', '+79001112233', 'ivan@example.com', 'Gold'),
       (2, 'Петр Петров', '+79004445566', 'petr@example.com', 'Silver'),
       (3, 'Анна Смирнова', '+79007778899', 'anna@example.com', 'Platinum')
ON CONFLICT (id)
    DO UPDATE SET full_name    = EXCLUDED.full_name,
                  phone_number = EXCLUDED.phone_number,
                  email        = EXCLUDED.email,
                  loyalty_tier = EXCLUDED.loyalty_tier;

SELECT setval('autoservice_schema.customer_id_seq', (SELECT MAX(id) FROM autoservice_schema.customer));
```


#### Проверка идемпотентности

```sql
new_2_autoservice=# INSERT INTO autoservice_schema.customer (id, full_name, phone_number, email, loyalty_tier)
VALUES (1, 'Иван Иванов', '+79001112233', 'ivan@example.com', 'Gold'),
       (2, 'Петр Петров', '+79004445566', 'petr@example.com', 'Silver'),
       (3, 'Анна Смирнова', '+79007778899', 'anna@example.com', 'Platinum')
ON CONFLICT (id)
    DO UPDATE SET full_name    = EXCLUDED.full_name,
                  phone_number = EXCLUDED.phone_number,
                  email        = EXCLUDED.email,
                  loyalty_tier = EXCLUDED.loyalty_tier;

SELECT setval('autoservice_schema.customer_id_seq', (SELECT MAX(id) FROM autoservice_schema.customer));
INSERT 0 3
 setval 
--------
      3
(1 row)

new_2_autoservice=# INSERT INTO autoservice_schema.customer (id, full_name, phone_number, email, loyalty_tier)
VALUES (1, 'Иван Иванов', '+79001112233', 'ivan@example.com', 'Gold'),
       (2, 'Петр Петров', '+79004445566', 'petr@example.com', 'Silver'),
       (3, 'Анна Смирнова', '+79007778899', 'anna@example.com', 'Platinum')
ON CONFLICT (id)
    DO UPDATE SET full_name    = EXCLUDED.full_name,
                  phone_number = EXCLUDED.phone_number,
                  email        = EXCLUDED.email,
                  loyalty_tier = EXCLUDED.loyalty_tier;

SELECT setval('autoservice_schema.customer_id_seq', (SELECT MAX(id) FROM autoservice_schema.customer));
INSERT 0 3
 setval 
--------
      3
(1 row)

new_2_autoservice=# INSERT INTO autoservice_schema.customer (id, full_name, phone_number, email, loyalty_tier)
VALUES (1, 'Иван Иванов', '+79001112233', 'ivan@example.com', 'Gold'),
       (2, 'Петр Петров', '+79004445566', 'petr@example.com', 'Silver'),
       (3, 'Анна Смирнова', '+79007778899', 'anna@example.com', 'Platinum')
ON CONFLICT (id)
    DO UPDATE SET full_name    = EXCLUDED.full_name,
                  phone_number = EXCLUDED.phone_number,
                  email        = EXCLUDED.email,
                  loyalty_tier = EXCLUDED.loyalty_tier;

SELECT setval('autoservice_schema.customer_id_seq', (SELECT MAX(id) FROM autoservice_schema.customer));
INSERT 0 3
 setval 
--------
      3
(1 row)

new_2_autoservice=# SELECT * FROM autoservice_schema.customer;
id |   full_name   | phone_number |      email       | loyalty_tier | profile_data | tags 
----+---------------+--------------+------------------+--------------+--------------+------
  1 | Иван Иванов   | +79001112233 | ivan@example.com | Gold         |              | 
  2 | Петр Петров   | +79004445566 | petr@example.com | Silver       |              | 
  3 | Анна Смирнова | +79007778899 | anna@example.com | Platinum     |              | 
(3 rows)

```

Скрипт был запущен 3 раза, и вывод одинаковый всегда без каких-либо ошибок