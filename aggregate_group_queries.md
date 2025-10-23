### COUNT, SUM, AVG, MIN, MAX, STRING_AGG

- Количество заказов у каждого клиента
SELECT c.id AS customer_id,
       c.full_name,
       COUNT(o.id) AS orders_count
FROM autoservice_schema.customer c
LEFT JOIN autoservice_schema."order" o ON o.customer_id = c.id
GROUP BY c.id, c.full_name;

- Количество машин в каждом заказе
SELECT oc.order_id,
       COUNT(oc.car_id) AS cars_in_order
FROM autoservice_schema.order_car oc
GROUP BY oc.order_id;


- Сумма стоимостей задач по каждому заказу
SELECT t.order_id,
       SUM(t.value) AS total_task_value
FROM autoservice_schema.task t
GROUP BY t.order_id;


- Средняя стоимость задачи по типу работы
SELECT t.task_type,
       AVG(t.value) AS avg_task_value
FROM autoservice_schema.task t
GROUP BY t.task_type;


- Минимальная и максимальная дата создания заказа по статусу
SELECT o.status,
       MIN(o.creation_date) AS first_created,
       MAX(o.creation_date) AS last_created
FROM autoservice_schema."order" o
GROUP BY o.status;


- Список VIN всех машин в заказе одной строкой
SELECT oc.order_id,
       STRING_AGG(oc.car_id, ', ' ORDER BY oc.car_id) AS vin_list
FROM autoservice_schema.order_car oc
GROUP BY oc.order_id;


### GROUP BY, HAVING

- Клиенты с 3+ заказами
SELECT c.id AS customer_id,
       c.full_name,
       COUNT(o.id) AS orders_count
FROM autoservice_schema.customer c
JOIN autoservice_schema."order" o ON o.customer_id = c.id
GROUP BY c.id, c.full_name
HAVING COUNT(o.id) >= 3;


- Типы задач, где средняя стоимость > 500
SELECT t.task_type,
       AVG(t.value) AS avg_value
FROM autoservice_schema.task t
GROUP BY t.task_type
HAVING AVG(t.value) > 500;



### GROUPING SETS, ROLLUP, CUBE

- Кол-во задач по статусу заказа и по клиенту, плюс промежуточные и общий итоги (GROUPING SETS)
SELECT
  o.status,
  o.customer_id,
  COUNT(t.id) AS tasks_count
FROM autoservice_schema."order" o
LEFT JOIN autoservice_schema.task t ON t.order_id = o.id
GROUP BY GROUPING SETS (
  (o.status, o.customer_id),
  (o.status),
  (o.customer_id),
  ()
)
ORDER BY o.status NULLS LAST, o.customer_id NULLS LAST;


- Иерархические итоги по филиалу → боксу → общему количеству машин (ROLLUP)
SELECT
  b.id_branch_office AS branch_id,
  b.id AS box_id,
  COUNT(ca.vin) AS cars_count
FROM autoservice_schema.box b
LEFT JOIN autoservice_schema.car ca ON ca.box_id = b.id
GROUP BY ROLLUP (b.id_branch_office, b.id)
ORDER BY branch_id NULLS LAST, box_id NULLS LAST;


- Полные комбинации количества заказов по статусу и клиенту (CUBE)
SELECT
  o.status,
  o.customer_id,
  COUNT(o.id) AS orders_count
FROM autoservice_schema."order" o
GROUP BY CUBE (o.status, o.customer_id)
ORDER BY o.status NULLS LAST, o.customer_id NULLS LAST;



### SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY

- Топ‑5 клиентов по сумме работ в их заказах за последний год
SELECT
  c.id AS customer_id,
  c.full_name,
  SUM(t.value) AS total_work_value
FROM autoservice_schema.customer c
JOIN autoservice_schema."order" o ON o.customer_id = c.id
JOIN autoservice_schema.task t ON t.order_id = o.id
WHERE o.creation_date >= NOW() - INTERVAL '1 year'
GROUP BY c.id, c.full_name
HAVING SUM(t.value) > 0
ORDER BY total_work_value DESC, c.full_name ASC
LIMIT 5;


- Статусы заказов, у которых средняя длительность выполнения > 24 часа, по убыванию среднего времени
SELECT
  o.status,
  AVG(EXTRACT(EPOCH FROM (o.completion_date - o.creation_date)) / 3600.0) AS avg_hours
FROM autoservice_schema."order" o
GROUP BY o.status
HAVING AVG(EXTRACT(EPOCH FROM (o.completion_date - o.creation_date)) / 3600.0) > 24
ORDER BY avg_hours DESC, o.status ASC;
