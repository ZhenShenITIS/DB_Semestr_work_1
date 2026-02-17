# 1. Процедуры и функции

## Процедуры

### Процедура регистрирует нового клиента
```sql
CREATE OR REPLACE PROCEDURE autoservice_schema.add_customer(
    full_name VARCHAR,
    phone_number VARCHAR
)
    LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO autoservice_schema.customer (full_name, phone_number)
    VALUES (full_name, phone_number);

END;
$$;

CALL autoservice_schema.add_customer('Дарт Вейдер', '+666-666-6666');
```

### 1.2. Процедура



### 1.3. Процедура


## Функции

### Функции без переменных

#### 2.1.1 Узнать есть ли клиент с таким номером телефона

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.is_customer_phone_number(phone__number VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
    BEGIN
    RETURN (SELECT count(*)
            FROM autoservice_schema.customer
            WHERE phone_number = phone__number) >= 1;
    END;
$$;

SELECT autoservice_schema.is_customer_phone_number('+666-666-6666');
```


### Функции c переменными

#### 2.2.1 Получить общую сумму выплат на сотрудника

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.get_worker_payouts(worker__id INT)
    RETURNS INT
    LANGUAGE plpgsql
AS $$
DECLARE
    total_payouts INT;
BEGIN
    SELECT SUM(t.value) INTO total_payouts
    FROM autoservice_schema.worker w
             JOIN autoservice_schema.task t ON w.id = t.worker_id
    WHERE w.id = worker__id
    LIMIT 1;

    RETURN total_payouts;
END;
$$;

SELECT autoservice_schema.get_worker_payouts(4);
```

## Блок DO

### 3.1. Добавляет владельца в базу данных

```sql
DO $$
BEGIN
    INSERT INTO autoservice_schema.worker(full_name, role, phone_number, id_branch_office)
    VALUES ('Скрудж Макдак', ' Владелец', '+7-777-777-77-77', 1);
END;
$$;
```

## Управляющие конструкции

### IF

#### 4.1.1 Узнаёт дорогой ли заказ

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.is_rich_order(order__id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
    DECLARE
        order_value INT;

    BEGIN
        SELECT SUM(value) INTO order_value
        FROM autoservice_schema."order"
            JOIN autoservice_schema.task t on "order".id = t.order_id
        WHERE order_id = order__id;


        IF order_value > 5000 THEN
            RETURN 'Дорогой';
        ELSE
            RETURN 'Дешёвый';
        end if;

    END;
$$;

SELECT autoservice_schema.is_rich_order(1);
```

### CASE

#### 4.2.1

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.is_rich_order_with_case(order__id INT)
    RETURNS VARCHAR
    LANGUAGE plpgsql
AS $$
DECLARE
    order_value INT;

BEGIN
    SELECT SUM(value) INTO order_value
    FROM autoservice_schema."order"
             JOIN autoservice_schema.task t on "order".id = t.order_id
    WHERE order_id = order__id;

    CASE
        WHEN order_value > 5000 THEN RETURN 'Дорогой';
        WHEN order_value > 4000 THEN RETURN 'Дороговатый';
        WHEN order_value > 3000 THEN RETURN 'Нормальный';
        WHEN order_value > 1000 THEN RETURN 'Дешевый';
        ELSE RETURN 'Копеечный';
    END CASE;

END;
$$;


SELECT autoservice_schema.is_rich_order_with_case(1);
```

### WHILE

#### 4.3.1 создать n заказчиков для теста

```sql
CREATE OR REPLACE PROCEDURE autoservice_schema.create_n_test_customers(count_customers INT)
LANGUAGE plpgsql
AS $$
    DECLARE
        i INT := 0;

    BEGIN
        WHILE i < count_customers LOOP
            CALL autoservice_schema.add_customer(concat('test', i), concat('+7-000-000-00-', i));
            i := i + 1;
        END LOOP;
    END;
$$;


CALL autoservice_schema.create_n_test_customers(3);
```

#### 4.3.2 напечатать n звездочек

```sql
CREATE OR REPLACE PROCEDURE autoservice_schema.print_stars(count_start INT)
LANGUAGE plpgsql
AS $$
    BEGIN

        WHILE count_start > 0 LOOP
            RAISE NOTICE '*';
            count_start := count_start - 1;
        END LOOP;

    END;
$$;

CALL autoservice_schema.print_stars(3);

```

### EXCEPTION

#### 4.4.1


### RAISE

#### 4.5.1