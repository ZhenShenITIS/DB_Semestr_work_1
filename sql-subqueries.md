# Примеры SQL подзапросов для БД автосервиса

## 1. Подзапрос в SELECT

### 1.1. Информация о работниках с подсчетом их задач
```sql
SELECT w.full_name,
       (SELECT COUNT(*) 
        FROM autoservice_schema.task t 
        WHERE t.worker_id = w.id) as task_count
FROM autoservice_schema.worker w;
```
![img_4.png](img_4.png)


### 1.2. Заказы с расчетом общей стоимости задач
```sql
SELECT o.id, o.description,
       (SELECT SUM(t.value) 
        FROM autoservice_schema.task t 
        WHERE t.order_id = o.id) as total_cost
FROM autoservice_schema.order o;
```
![img_5.png](img_5.png)


### 1.3. Филиалы с количеством боксов в каждом
```sql
SELECT bo.address,
       (SELECT COUNT(*) 
        FROM autoservice_schema.box b 
        WHERE b.id_branch_office = bo.id) as box_count
FROM autoservice_schema.branch_office bo;
```
![img_6.png](img_6.png)


## 2. Подзапрос в FROM

### 2.1. Средняя стоимость задач по профессиям работников
```sql
SELECT worker_stats.role, AVG(worker_stats.avg_task_value) as avg_by_role
FROM (SELECT w.role, w.id, AVG(t.value) as avg_task_value
      FROM autoservice_schema.worker w
      JOIN autoservice_schema.task t ON w.id = t.worker_id
      GROUP BY w.role, w.id) as worker_stats
GROUP BY worker_stats.role;
```
![img_7.png](img_7.png)


### 2.2. Клиенты с максимальным количеством заказов
```sql
SELECT customer_orders.full_name, customer_orders.order_count
FROM (SELECT c.id, c.full_name, COUNT(o.id) as order_count
      FROM autoservice_schema.customer c
      LEFT JOIN autoservice_schema.order o ON c.id = o.customer_id
      GROUP BY c.id, c.full_name) as customer_orders
WHERE customer_orders.order_count = (
    SELECT MAX(order_count) FROM (
        SELECT COUNT(o.id) as order_count
        FROM autoservice_schema.customer c
        LEFT JOIN autoservice_schema.order o ON c.id = o.customer_id
        GROUP BY c.id
    ) max_orders
);
```
![img_8.png](img_8.png)


### 2.3. Статистика по филиалам: работники и боксы
```sql
SELECT branch_stats.address, branch_stats.worker_count, branch_stats.box_count
FROM (SELECT bo.id, bo.address,
             (SELECT COUNT(*) FROM autoservice_schema.worker w WHERE w.id_branch_office = bo.id) as worker_count,
             (SELECT COUNT(*) FROM autoservice_schema.box b WHERE b.id_branch_office = bo.id) as box_count
      FROM autoservice_schema.branch_office bo) as branch_stats;
```
![img_9.png](img_9.png)


## 3. Подзапрос в WHERE/HAVING

### 3.1. Работники с количеством задач выше среднего
```sql
SELECT w.full_name, w.role
FROM autoservice_schema.worker w
WHERE (SELECT COUNT(*) FROM autoservice_schema.task t WHERE t.worker_id = w.id) >
      (SELECT AVG(task_count) FROM 
       (SELECT COUNT(*) as task_count FROM autoservice_schema.task GROUP BY worker_id) counts);
```



### 3.2. Заказы с общей стоимостью выше среднего чека
```sql
SELECT o.id, o.description
FROM autoservice_schema.order o
WHERE (SELECT SUM(t.value) FROM autoservice_schema.task t WHERE t.order_id = o.id) >
      (SELECT AVG(order_total) FROM 
       (SELECT SUM(t.value) as order_total FROM autoservice_schema.task t GROUP BY t.order_id) totals);
```
![img_10.png](img_10.png)



### 3.3. Филиалы с избытком работников относительно боксов
```sql
SELECT bo.address
FROM autoservice_schema.branch_office bo
WHERE (SELECT COUNT(*) FROM autoservice_schema.worker w WHERE w.id_branch_office = bo.id) >
      (SELECT COUNT(*) FROM autoservice_schema.box b WHERE b.id_branch_office = bo.id);
```



## 4. ALL

### 4.1. Работник с максимальной суммарной стоимостью задач
```sql
SELECT w.full_name, SUM(t.value) as total_value
FROM autoservice_schema.worker w
JOIN autoservice_schema.task t ON w.id = t.worker_id
GROUP BY w.id, w.full_name
HAVING SUM(t.value) >= ALL (
    SELECT SUM(t2.value)
    FROM autoservice_schema.task t2
    GROUP BY t2.worker_id
);
```
![img_11.png](img_11.png)


### 4.2. Заказы с максимальной общей стоимостью
```sql
SELECT o.id, o.description, SUM(t.value) as total_cost
FROM autoservice_schema.order o
JOIN autoservice_schema.task t ON o.id = t.order_id
GROUP BY o.id, o.description
HAVING SUM(t.value) >= ALL (
    SELECT SUM(t2.value)
    FROM autoservice_schema.task t2
    GROUP BY t2.order_id
);
```
![img_12.png](img_12.png)



### 4.3. Поставщики с максимальной суммой закупок
```sql
SELECT p.id, p.address, SUM(pur.value) as total_purchases
FROM autoservice_schema.provider p
JOIN autoservice_schema.purchase pur ON p.id = pur.provider_id
GROUP BY p.id, p.address
HAVING SUM(pur.value) >= ALL (
    SELECT SUM(pur2.value)
    FROM autoservice_schema.purchase pur2
    GROUP BY pur2.provider_id
);
```
![img_13.png](img_13.png)


## 5. IN

### 5.1. Работники из филиалов с диагностическими боксами
```sql
SELECT w.full_name, w.role
FROM autoservice_schema.worker w
WHERE w.id_branch_office IN (
    SELECT DISTINCT b.id_branch_office
    FROM autoservice_schema.box b
    WHERE b.box_type = 'diagnostic'
);
```



### 5.2. Автомобили с дорогостоящими задачами
```sql
SELECT c.vin, c.model, c.plate_number
FROM autoservice_schema.car c
WHERE c.vin IN (
    SELECT t.car_id
    FROM autoservice_schema.task t
    WHERE t.value > 5000
);
```



### 5.3. Клиенты, использовавшие автозапчасти в заказах
```sql
SELECT DISTINCT cust.full_name, cust.phone_number
FROM autoservice_schema.customer cust
WHERE cust.id IN (
    SELECT o.customer_id
    FROM autoservice_schema.order o
    JOIN autoservice_schema.task t ON o.id = t.order_id
    WHERE t.id IN (SELECT ap.task_id FROM autoservice_schema.autopart ap WHERE ap.task_id IS NOT NULL)
);
```
![img_14.png](img_14.png)



## 6. ANY

### 6.1. Работники с зарплатой выше любой выплаты менеджера
```sql
SELECT DISTINCT w.full_name, w.role
FROM autoservice_schema.worker w
JOIN autoservice_schema.payout p ON w.id = p.worker_id
WHERE p.value > ANY (
    SELECT p2.value
    FROM autoservice_schema.payout p2
    JOIN autoservice_schema.worker w2 ON p2.worker_id = w2.id
    WHERE w2.role = 'manager'
);
```

**РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА** — таблица с двумя столбцами: ФИО работника (full_name) и роль (role) для работников, получавших выплаты больше хотя бы одной выплаты менеджера

### 6.2. Заказы дороже любого заказа конкретного клиента
```sql
SELECT o.id, o.description, SUM(t.value) as total_cost
FROM autoservice_schema.order o
JOIN autoservice_schema.task t ON o.id = t.order_id
GROUP BY o.id, o.description
HAVING SUM(t.value) > ANY (
    SELECT SUM(t2.value)
    FROM autoservice_schema.order o2
    JOIN autoservice_schema.task t2 ON o2.id = t2.order_id
    JOIN autoservice_schema.customer c ON o2.customer_id = c.id
    WHERE c.full_name = 'Иванов И.И.'
    GROUP BY o2.id
);
```

**РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА** — таблица с тремя столбцами: ID заказа (id), описание (description) и общая стоимость (total_cost) для заказов дороже хотя бы одного заказа клиента Иванова И.И.

### 6.3. Автозапчасти из дорогих закупок
```sql
SELECT ap.name
FROM autoservice_schema.autopart ap
JOIN autoservice_schema.purchase pur ON ap.purchase_id = pur.id
WHERE pur.value > ANY (
    SELECT pur2.value
    FROM autoservice_schema.purchase pur2
    WHERE pur2.provider_id = 1
);
```

**РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА** — таблица с одним столбцом: название автозапчасти (name) из закупок дороже хотя бы одной закупки у поставщика с ID=1

## 7. EXISTS

### 7.1. Клиенты, имеющие заказы
```sql
SELECT c.full_name, c.phone_number
FROM autoservice_schema.customer c
WHERE EXISTS (
    SELECT 1
    FROM autoservice_schema.order o
    WHERE o.customer_id = c.id
);
```
![img_15.png](img_15.png)



### 7.2. Работники, использовавшие автозапчасти в работе
```sql
SELECT DISTINCT w.full_name, w.role
FROM autoservice_schema.worker w
WHERE EXISTS (
    SELECT 1
    FROM autoservice_schema.task t
    JOIN autoservice_schema.autopart ap ON t.id = ap.task_id
    WHERE t.worker_id = w.id
);
```
![img_16.png](img_16.png)


### 7.3. Филиалы с закрытыми заказами
```sql
SELECT bo.address, bo.phone_number
FROM autoservice_schema.branch_office bo
WHERE EXISTS (
    SELECT 1
    FROM autoservice_schema.worker w
    JOIN autoservice_schema.task t ON w.id = t.worker_id
    JOIN autoservice_schema.order o ON t.order_id = o.id
    JOIN autoservice_schema.order_closure_date ocd ON o.id = ocd.order_id
    WHERE w.id_branch_office = bo.id
);
```
![img_17.png](img_17.png)



## 8. Сравнение по нескольким столбцам

### 8.1. Работники с дублированными ролью и телефоном
```sql
SELECT w1.full_name, w1.role, w1.phone_number, bo.address
FROM autoservice_schema.worker w1
JOIN autoservice_schema.branch_office bo ON w1.id_branch_office = bo.id
WHERE (w1.role, w1.phone_number) IN (
    SELECT w2.role, w2.phone_number
    FROM autoservice_schema.worker w2
    WHERE w2.id != w1.id
);
```

**РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА** — таблица с четырьмя столбцами: ФИО работника (full_name), роль (role), номер телефона (phone_number) и адрес филиала (address) для работников с одинаковой комбинацией роли и телефона

### 8.2. Автомобили с одинаковой моделью и статусом
```sql
SELECT c1.vin, c1.model, c1.status, c1.plate_number
FROM autoservice_schema.car c1
WHERE (c1.model, c1.status) IN (
    SELECT c2.model, c2.status
    FROM autoservice_schema.car c2
    WHERE c2.vin != c1.vin
    GROUP BY c2.model, c2.status
    HAVING COUNT(*) > 1
);
```

**РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА** — таблица с четырьмя столбцами: VIN номер (vin), модель (model), статус (status) и государственный номер (plate_number) для автомобилей с дублирующейся комбинацией модели и статуса

### 8.3. Поставщики с одинаковыми контактными данными
```sql
SELECT p1.id, p1.address, p1.phone_number
FROM autoservice_schema.provider p1
WHERE (p1.address, p1.phone_number) IN (
    SELECT p2.address, p2.phone_number
    FROM autoservice_schema.provider p2
    WHERE p2.id != p1.id
    AND p2.address IS NOT NULL 
    AND p2.phone_number IS NOT NULL
);
```

**РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА** — таблица с тремя столбцами: ID поставщика (id), адрес (address) и номер телефона (phone_number) для поставщиков с идентичными контактными данными
