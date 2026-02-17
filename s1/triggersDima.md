### Триггер OLD. Блокировка изменения VIN

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.prevent_vin_change_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.vin <> OLD.vin THEN
        RAISE EXCEPTION 'Изменение VIN-номера запрещено! Старый: %, Новый: %', OLD.vin, NEW.vin;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_vin_change
BEFORE UPDATE ON autoservice_schema.car
FOR EACH ROW
EXECUTE FUNCTION autoservice_schema.prevent_vin_change_func();

UPDATE autoservice_schema.car 
SET vin = 'NEW_FAKE_VIN_1234' 
WHERE vin = 'WVWZZZ1JZXW000001';
```

![](images-07-dima/vin1.png)

### Триггер BEFORE. Коррекция отрицательной стоимости

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.validate_task_value_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.value < 0 THEN
        RAISE NOTICE 'Отрицательная стоимость задачи (%) исправлена на 0', NEW.value;
        NEW.value := 0; 
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_task_value
BEFORE INSERT ON autoservice_schema.task
FOR EACH ROW
EXECUTE FUNCTION autoservice_schema.validate_task_value_func();

INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
VALUES (1, -5000.00, 1, 'Попытка ввода неверной цены', 'WVWZZZ1JZXW000001');

SELECT id, description, value 
FROM autoservice_schema.task 
WHERE description = 'Попытка ввода неверной цены'
ORDER BY id DESC LIMIT 1;
```

![](images-07-dima/vin2.png)
### Триггер Row level. Автоматическое обновление статуса авто

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.update_car_status_func()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE autoservice_schema.car
    SET status = 'в работе'
    WHERE vin = NEW.car_id;

    RAISE NOTICE 'Статус автомобиля % изменен на "в работе"', NEW.car_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_car_status
AFTER INSERT ON autoservice_schema.task
FOR EACH ROW
EXECUTE FUNCTION autoservice_schema.update_car_status_func();

UPDATE autoservice_schema.car 
SET status = 'ожидает' 
WHERE vin = 'WBAAA31070B000002';

INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
VALUES (2, 1000.00, 2, 'Новая задача запускает ремонт', 'WBAAA31070B000002');

SELECT vin, model, status 
FROM autoservice_schema.car 
WHERE vin = 'WBAAA31070B000002';
```

![](images-07-dima/vin3.png)

### Триггер Statement level. Логирование массовых изменений 

```sql
CREATE OR REPLACE FUNCTION autoservice_schema.audit_payout_update_func()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'В таблице выплат (payout) произошли изменения (Statement Level Trigger)';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_payout_stmt
AFTER UPDATE ON autoservice_schema.payout
FOR EACH STATEMENT
EXECUTE FUNCTION autoservice_schema.audit_payout_update_func();

UPDATE autoservice_schema.payout
SET value = value + 100
WHERE id IN (1, 2, 3);
```

![](images-07-dima/vin4.png)

### Крон. Ежедневная очистка старых закупок

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
    'clean_old_purchases',
    '0 3 * * *',
    $$DELETE FROM autoservice_schema.purchase WHERE date < now() - INTERVAL '5 years'$$
);

SELECT * FROM cron.job;
```

![](images-07-dima/vin5.png)

### Отображение списка триггеров

```sql
SELECT * FROM information_schema.triggers
```

![](images-07-dima/vin6.png)