
```sql
-- Процедура для добавления нового клиента с проверкой телефона
CREATE OR REPLACE PROCEDURE autoservice_schema.add_new_customer(
    p_full_name VARCHAR,
    p_phone_number VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_phone_number LIKE '+7%' THEN
        INSERT INTO autoservice_schema.customer (full_name, phone_number)
        VALUES (p_full_name, p_phone_number);
    END IF;
END;
$$;

CALL autoservice_schema.add_new_customer('Тестов Тест', '+7-901-123-45-67');
```

![Процедура для добавления нового клиента с проверкой телефона](images-26-11/vin1.png)

```sql
-- Функция для подсчета общего количества задач для работника
CREATE OR REPLACE FUNCTION autoservice_schema.get_worker_tasks_count(
    p_worker_id INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM autoservice_schema.task
    WHERE worker_id = p_worker_id);
END;
$$;

SELECT autoservice_schema.get_worker_tasks_count(4);
```

![Функция для подсчета общего количества задач для работника](images-26-11/vin2.png)

```sql
-- Функция для расчета средней стоимости задач для конкретного заказа
CREATE OR REPLACE FUNCTION autoservice_schema.calculate_order_avg_task_value(
    p_order_id INT
)
RETURNS DECIMAL(10, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    avg_value DECIMAL(10, 2);
    total_value DECIMAL(10, 2);
    task_count INT;
BEGIN
    SELECT COALESCE(SUM(value), 0), COUNT(*)
    INTO total_value, task_count
    FROM autoservice_schema.task
    WHERE order_id = p_order_id;

    IF task_count > 0 THEN
        avg_value := total_value / task_count;
    ELSE
        avg_value := 0;
    END IF;

    RETURN avg_value;
END;
$$;

SELECT autoservice_schema.calculate_order_avg_task_value(1);
```

![Функция для расчета средней стоимости задач для конкретного заказа](images-26-11/vin3.png)

```sql
-- Блок DO для обновления статуса автомобилей в конкретном боксе
DO $$
DECLARE
    updated_count INT;
BEGIN
    UPDATE autoservice_schema.car
    SET status = 'готово'
    WHERE box_id = 1 AND status != 'готово';

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    RAISE NOTICE 'Обновлено автомобилей: %', updated_count;
END;
$$;
```

![Блок DO для обновления статуса автомобилей в конкретном боксе](images-26-11/vin4.png)

```sql
-- Просмотр всех процедур в схеме autoservice_schema
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_type = 'PROCEDURE' AND routine_schema = 'autoservice_schema'
```

![Просмотр всех процедур в схеме autoservice_schema](images-26-11/vin1.png)

```sql
-- RAISE 1: Функция с информационным сообщением RAISE NOTICE
CREATE OR REPLACE FUNCTION autoservice_schema.get_car_info(p_vin VARCHAR)
RETURNS TABLE(
    vin VARCHAR,
    model VARCHAR,
    plate_number VARCHAR,
    status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Запрос информации об автомобиле с VIN: %', p_vin;

    RETURN QUERY
    SELECT c.vin, c.model, c.plate_number, c.status
    FROM autoservice_schema.car c
    WHERE c.vin = p_vin;

    IF NOT FOUND THEN
        RAISE WARNING 'Автомобиль с VIN % не найден', p_vin;
    END IF;
END;
$$;

SELECT * FROM autoservice_schema.get_car_info('WVWZZZ1JZXW000002');
```

![RAISE 1: Функция с информационным сообщением RAISE NOTICE](images-26-11/vin5.png)

```sql
-- RAISE 2: Применить скидку от клиента
CREATE OR REPLACE PROCEDURE autoservice_schema.apply_discount(
    p_task_id INT,
    p_discount_percent INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_discount_percent < 0 OR p_discount_percent > 100 THEN
        RAISE EXCEPTION 'Скидка должна быть от 0 до 100 процентов, получено: %', p_discount_percent;
    END IF;
    
    UPDATE autoservice_schema.task
    SET value = value * (1 - p_discount_percent / 100.0)
    WHERE id = p_task_id;
    
    RAISE NOTICE 'Скидка % применена к задаче ID %', p_discount_percent, p_task_id;
END;
$$;

CALL autoservice_schema.apply_discount(1, 10);
CALL autoservice_schema.apply_discount(1, 150);
```

![RAISE 2: Применить скидку от клиента](images-26-11/vin6.png)