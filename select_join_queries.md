- Покупки: метка дорогая/дешевая
```sql
SELECT id, CASE WHEN value >= 1000 THEN "Дорого" ELSE "Дёшево" END AS тип_стоимости
FROM autoservice_schema.PURCHASE;
```

- Заказы: метка новый/старый
```sql
SELECT id, CASE WHEN creation_date >= "20.08.2025" THEN "Новый" ELSE "Старый" END AS тип_заказа_по_дате
FROM autoservice_schema.ORDER;
```

- Сотрудники и выплаты
```sql
SELECT full_name, value
FROM autoservice_schema.worker INNER JOIN autoservice_schema.payout ON worker.id = payout.worker_id;
```

- Клиенты и статусы заказов
```sql
SELECT full_name, status
FROM autoservice_schema.customer INNER JOIN autoservice_schema."order" o on customer.id = o.customer_id;
```

- Сотрудники и их филиалы
```sql
SELECT full_name, role, address AS filial_director_address
FROM autoservice_schema.worker LEFT JOIN autoservice_schema.branch_office bo on worker.id = bo.id_manager;
```

- Сотрудники и их филиалы (повтор)
```sql
SELECT full_name, role, address AS filial_director_address
FROM autoservice_schema.worker LEFT JOIN autoservice_schema.branch_office bo on worker.id = bo.id_manager;
```

- Поставщики и покупки
```sql
SELECT address, value
FROM autoservice_schema.provider LEFT JOIN autoservice_schema.purchase p on provider.id = p.provider_id;
```

- Авто и их задачи
```sql
SELECT plate_number, task_type, status
FROM autoservice_schema.task RIGHT JOIN autoservice_schema.car ON task.car_id = car.vin;
```

- Задачи и запчасти
```sql
SELECT order_id, task_type, name
FROM autoservice_schema.autopart RIGHT JOIN autoservice_schema.task ON autopart.task_id = task.id;
```

- Все пары сотрудник × филиал
```sql
SELECT *
FROM autoservice_schema.worker CROSS JOIN autoservice_schema.branch_office;
```

- Все пары поставщик × покупка
```sql
SELECT *
FROM autoservice_schema.provider CROSS JOIN autoservice_schema.purchase;
```

- Все сотрудники и филиалы
```sql
SELECT *
FROM autoservice_schema.worker full outer join autoservice_schema.branch_office bo on worker.id = bo.id_manager;
```

- Все поставщики и покупки
```sql
SELECT *
FROM autoservice_schema.provider full outer join autoservice_schema.purchase p on provider.id = p.provider_id;
```