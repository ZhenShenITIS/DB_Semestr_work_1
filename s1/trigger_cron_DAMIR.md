# Триггеры и кроны

## 1. Триггеры

### 1.1 Триггеры на NEW
#### 1.1.1 если новая цена задачи меньше старой, то возвращаем старую
```sql
CREATE OR REPLACE FUNCTION autoservice_schema.defeat_lower_task_values()
    RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.value < OLD.VALUE THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    end if;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER defeat_task_values_trigger
    BEFORE UPDATE ON autoservice_schema.task
    FOR EACH ROW
EXECUTE FUNCTION autoservice_schema.defeat_lower_task_values();


SELECT id, value
FROM autoservice_schema.task
WHERE id = 26;

UPDATE autoservice_schema.task SET value = 1000 WHERE id = 26;

SELECT id, value
FROM autoservice_schema.task
WHERE id = 26;
```

![img_27.png](images-damir-01-12-25/img_27.png)

### 1.2. Триггеры на OLD
#### 1.2.1
```sql
CREATE OR REPLACE FUNCTION autoservice_schema.defeat_task_values()
    RETURNS TRIGGER
AS $$
BEGIN
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER defeat_task_values_trigger
    BEFORE UPDATE ON autoservice_schema.task
    FOR EACH ROW
EXECUTE FUNCTION autoservice_schema.defeat_task_values();

SELECT id, value
FROM autoservice_schema.task
WHERE id = 24;

UPDATE autoservice_schema.task SET value = 200 WHERE id = 24;

SELECT id, value
FROM autoservice_schema.task
WHERE id = 24;
```

![img_26.png](images-damir-01-12-25/img_26.png)

### 1.3. Триггеры на BEFORE
#### 1.3.1 триггер ставит цену задачи 100, если она меньше
```sql
CREATE OR REPLACE FUNCTION autoservice_schema.defeat_insert_lower_than_min_value()
    RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.value < 100 THEN
        NEW.value := 100;
    end if;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER defeat_insert_lower_than_min_value
    BEFORE INSERT ON autoservice_schema.task
    FOR EACH ROW
    EXECUTE FUNCTION autoservice_schema.defeat_insert_lower_than_min_value();

INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id) VALUES (1, 10, 1, 'ура ура гол', 'XTA210990Y0000003');

SELECT order_id, value
FROM autoservice_schema.task
WHERE description = 'ура ура гол';
```
![img_25.png](images-damir-01-12-25/img_25.png)

### 1.4. Триггеры на AFTER
#### 1.4.1 триггер пишет в консоль при создании нового пользователя
```sql
CREATE OR REPLACE FUNCTION autoservice_schema.add_customer_logging()
RETURNS TRIGGER
AS $$
    BEGIN
        RAISE NOTICE 'Создали пользователя %', NEW.full_name;
        RETURN NEW;
    END;

$$ LANGUAGE plpgsql;


CREATE TRIGGER add_customer_logging
    AFTER INSERT ON autoservice_schema.customer
    FOR EACH ROW
    EXECUTE FUNCTION autoservice_schema.add_customer_logging();

INSERT INTO autoservice_schema.customer (full_name, phone_number) VALUES ('новый чел', '+599434');
```

![img142.png](img142.png)
## 2. Кроны

### 2.1 Запросы на кроны

#### 2.1.1 каждую минуту/две меняет стоимость задачи

```sql
SELECT cron.schedule(
               'update_task27_value',
               '*/1 * * * *',
               'UPDATE autoservice_schema.task SET value = 10000 WHERE id = 27'
       );

SELECT cron.schedule(
               'update_task27_value2',
               '*/2 * * * *',
               'UPDATE autoservice_schema.task SET value = 5000 WHERE id = 27'
       );
```



#### 2.1.2

#### 2.1.3

### 2.2 Служебные запросы на кроны

#### 2.2.1 запрос на просмотр выполнения кронов

```sql
SELECT * FROM cron.job_run_details;
```

![img_28.png](images-damir-01-12-25/img_28.png)
![img_29.png](images-damir-01-12-25/img_29.png)


#### 2.2.2