
### Процедура добавления премии определенному сотруднику
```sql
CREATE OR REPLACE PROCEDURE assign_bonus (
   worker_id INT,
   bonus_value INT
)
LANGUAGE plpgsql
AS $$
    BEGIN
        INSERT INTO autoservice_schema.payout (value, date, payout_type, worker_id) VALUES (bonus_value, date(now()), 'Премия', assign_bonus.worker_id);
    end;
$$;

CALL assign_bonus(2, 10000);
```


### Функция подсчета суммы всех задач определенного сотрудника
```sql
CREATE OR REPLACE FUNCTION calculate_tasks_values (
   w_id INT
)
RETURNS numeric(100, 2)
LANGUAGE sql
AS $$
   SELECT SUM(value)
    FROM autoservice_schema.task where worker_id = w_id ;
$$;


SELECT calculate_tasks_values(2);
```


### Функция подсчета суммы всех задач определенного сотрудника c переменной
```sql
CREATE OR REPLACE FUNCTION calculate_tasks_values_with_var (
   w_id INT
)
RETURNS numeric(100, 2)
LANGUAGE plpgsql
AS $$
DECLARE total_sum numeric(100, 2);
    BEGIN 
   SELECT SUM(value) into total_sum
    FROM autoservice_schema.task where worker_id = w_id;
   RETURN total_sum;
    END;
$$;


SELECT calculate_tasks_values_with_var(2);
```


### DO. Проставить статус "Готово" машинам, у которых привязанный заказ завершен
```sql
DO
$$
    DECLARE
        vin_to_update text;
    BEGIN
        FOR vin_to_update in
            select vin
            from autoservice_schema.car
                     join autoservice_schema.order_car oc on car.vin = oc.car_id
                     join autoservice_schema.order_closure_date ocd on oc.order_id = ocd.order_id
            LOOP
                update autoservice_schema.car SET status='Готово' where vin = vin_to_update;
                RAISE NOTICE 'Машина с VIN % обновлена', vin_to_update;
            end loop;
    END;
$$
```


### Получение всех функций
```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_type = 'FUNCTION' AND routine_schema = 'public'
```




### EXCEPTION. Узнаем эффективность работника: разделить его выплаты на количество задач
```sql
DO
$$
   DECLARE
      sum_payouts numeric(100, 2);
      count_task  numeric(100, 2);
   BEGIN
      SELECT sum(value)
      into sum_payouts
      FROM autoservice_schema.payout
      where worker_id = 3;

      SELECT COUNT(*)
      into count_task
      FROM autoservice_schema.task
      where worker_id = 3;

      RAISE NOTICE 'Эффективность работника: %', sum_payouts / count_task;
   EXCEPTION
      WHEN division_by_zero THEN
         RAISE NOTICE 'Деление невозможно, у сотрудника 0 задач';

   END;
$$ 
```


### EXCEPTION. Пытаемся вставить существующего работника
```sql
CREATE OR REPLACE PROCEDURE add_worker(
   worker_id INT,
   full_name varchar,
   role varchar,
   phone_number varchar,
   id_branch_office int
)
   LANGUAGE plpgsql
AS
$$
BEGIN
   INSERT INTO autoservice_schema.worker (id, full_name, role, phone_number, id_branch_office)
   VALUES (worker_id, add_worker.full_name, add_worker.role, add_worker.phone_number, add_worker.id_branch_office);
EXCEPTION
   WHEN unique_violation THEN RAISE NOTICE 'Работник с ID % уже существует!', worker_id;
end;
$$;

call add_worker(1, 'Тестовый', 'Механик', '89275438989', 4);
```