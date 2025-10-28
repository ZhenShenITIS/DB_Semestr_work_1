---
modified: 2025-10-14T17:07:55+03:00
created: 2025-10-14T17:00:41+03:00
---
### Аномалия таблицы Заказ
В таблице были поля дата закрытия и статус, которые создавали нетривиальную зависимость. Дата закрытия определяла статус. Также при создании заказа, изначально в дате закрытия ставился null.

Как решили:
- Удалили поле статус
- Выделили отдельную таблицу Заказ_датаЗакрытия. Записи в неё добавляются, при закрытии заказа

### Аномалия таблицы Задача
В таблице Задача. Тип задачи определял описание

Как решили:
- Удалили поле тип задачи

Избавились от избыточности в базе данных. Повысили согласованность данных

### Аномалия связи таблиц Офис и Работник
При создании офиса, обязательно должен быть указан id работника - управляющего офисом
Работник же может создаться, только если он прикреплён к какому-то офису. Получается, что база данных не может быть наполнена данными до разрешения данной проблемы
Как решили:
- Создали новую таблицу офис_управляющий

Решили проблему вставки
```
BEGIN;

-- 1) Заказ: убрать поле "status"
ALTER TABLE autoservice_schema."order"
  DROP COLUMN IF EXISTS status;  -- синтаксис DROP COLUMN для PostgreSQL [web:14][web:1]

-- 2) Заказ: выделить таблицу для дат закрытия
--    Логика: запись создаётся только при закрытии заказа; допускается одна дата закрытия на заказ
CREATE TABLE IF NOT EXISTS autoservice_schema.order_closure_date
(
    order_id INT PRIMARY KEY
        REFERENCES autoservice_schema."order"(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,  -- стандартное добавление FK через CREATE TABLE ... REFERENCES [web:9][web:12]
    closure_date TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

ALTER TABLE autoservice_schema."order"
  DROP COLUMN IF EXISTS completion_date;


-- 3) Задача: удалить поле "task_type"
ALTER TABLE autoservice_schema.task
  DROP COLUMN IF EXISTS task_type;  -- удаление лишнего атрибута по DROP COLUMN [web:11][web:8]
  
-- 4) Задача: создать таблицу офис_менеджер
CREATE TABLE IF NOT EXISTS autoservice_schema.branch_office_manager (
    branch_office_id INT PRIMARY KEY
        REFERENCES autoservice_schema.branch_office(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    manager_id INT NOT NULL
        REFERENCES autoservice_schema.worker(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

ALTER TABLE autoservice_schema.branch_office
      DROP COLUMN id_manager;
      
COMMIT;


```