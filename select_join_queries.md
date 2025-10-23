
SELECT * FROM ORDER
SELECT * FROM WORKER

```
SELECT id, CASE WHEN value >= 1000 THEN "Дорого" ELSE "Дёшево" END AS тип_стоимости
FROM PURCHASE
```

```
SELECT id, CASE WHEN creation_date >= "20.08.2025" THEN "Новый" ELSE "Старый" END AS тип_заказа_по_дате
FROM ORDER
```

```
SELECT full_name, value
FROM autoservice_schema.worker INNER JOIN autoservice_schema.payout ON worker.id = payout.worker_id;
```

```
SELECT full_name, status
FROM autoservice_schema.customer INNER JOIN autoservice_schema."order" o on customer.id = o.customer_id;
```

```
SELECT full_name, role, address AS filial_director_address
FROM autoservice_schema.worker LEFT JOIN autoservice_schema.branch_office bo on worker.id = bo.id_manager;
```

```
SELECT full_name, role, address AS filial_director_address
FROM autoservice_schema.worker LEFT JOIN autoservice_schema.branch_office bo on worker.id = bo.id_manager;
```

```
SELECT address, value
FROM autoservice_schema.provider LEFT JOIN autoservice_schema.purchase p on provider.id = p.provider_id;
```

```
SELECT plate_number, task_type, status
FROM autoservice_schema.task RIGHT JOIN autoservice_schema.car ON task.car_id = car.vin;
```

```
SELECT order_id, task_type, name
FROM autoservice_schema.autopart RIGHT JOIN autoservice_schema.task ON autopart.task_id = task.id;
```

```
SELECT *
FROM autoservice_schema.worker CROSS JOIN autoservice_schema.branch_office;
```

```
SELECT *
FROM autoservice_schema.provider CROSS JOIN autoservice_schema.purchase;
```

```
SELECT *
FROM autoservice_schema.worker full outer join autoservice_schema.branch_office bo on worker.id = bo.id_manager;
```
```
SELECT *
FROM autoservice_schema.provider full outer join autoservice_schema.purchase p on provider.id = p.provider_id;
```