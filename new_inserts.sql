BEGIN;

-- branch_office
INSERT INTO autoservice_schema.branch_office (address, phone_number)
VALUES
    ('Казань, ул. Пушкина, 10', '+7-843-100-01-01'),
    ('Казань, пр. Победы, 45', '+7-843-100-02-02')
RETURNING id;

-- provider
INSERT INTO autoservice_schema.provider (address, phone_number)
VALUES
    ('Москва, ул. Тверская, 7', '+7-495-200-00-01'),
    ('Санкт-Петербург, Невский пр., 12', '+7-812-300-00-02');

-- customer
INSERT INTO autoservice_schema.customer (full_name, phone_number)
VALUES
    ('Иванов Иван', '+7-900-111-11-11'),
    ('Петров Пётр', '+7-900-222-22-22'),
    ('Сидорова Анна', '+7-900-333-33-33');

-- worker (ссылка на branch_office.id = 1/2)
INSERT INTO autoservice_schema.worker (full_name, role, phone_number, id_branch_office)
VALUES
    ('Смирнов Сергей', 'Механик', '+7-900-555-55-01', 1),
    ('Кузнецова Мария', 'Диагност', '+7-900-555-55-02', 1),
    ('Алексеев Алексей', 'Приёмщик', '+7-900-555-55-03', 2);

-- branch_office_manager (один менеджер на офис)
INSERT INTO autoservice_schema.branch_office_manager (branch_office_id, manager_id)
VALUES
    (1, 3),
    (2, 3);

-- box (привязаны к офисам)
INSERT INTO autoservice_schema.box (id_branch_office, box_type)
VALUES
    (1, 'Подъемник 2-стоечный'),
    (1, 'Диагностическая линия'),
    (2, 'Подъемник 4-стоечный');

-- car (VIN 17 символов, box_id существует)
INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id)
VALUES
    ('WVWZZZ1JZXW000001', 'VW Golf', 'A001AA116', 'в работе', 1),
    ('WBAAA31070B000002', 'BMW 3', 'A002AA116', 'ожидает', 2),
    ('XTA210990Y0000003','Lada 21099','A003AA116','готово', 3);

-- purchase (покупки от провайдеров, даты относительно текущего момента)
INSERT INTO autoservice_schema.purchase (provider_id, date, value)
VALUES
    (1, CURRENT_TIMESTAMP - INTERVAL '7 days', 35000.00),
    (2, CURRENT_TIMESTAMP - INTERVAL '3 days', 18500.50);

-- order (без status, без completion_date; создаём открытые заказы)
INSERT INTO autoservice_schema."order" (customer_id, creation_date, description)
VALUES
    (1, CURRENT_TIMESTAMP - INTERVAL '2 days', 'ТО-1, замена масла и фильтров'),
    (2, CURRENT_TIMESTAMP - INTERVAL '1 days', 'Диагностика подвески, люфт'),
    (3, CURRENT_TIMESTAMP - INTERVAL '10 hours', 'Шиномонтаж, балансировка');

-- order_closure_date (закрываем выборочно 1 заказ)
INSERT INTO autoservice_schema.order_closure_date (order_id, closure_date)
VALUES
    (1, CURRENT_TIMESTAMP - INTERVAL '1 days');

-- order_car (связываем заказы и машины)
INSERT INTO autoservice_schema.order_car (order_id, car_id)
VALUES
    (1, 'WVWZZZ1JZXW000001'),
    (2, 'WBAAA31070B000002'),
    (3, 'XTA210990Y0000003');

-- task (без task_type; value >= 0; ссылки на order, worker, car)
INSERT INTO autoservice_schema.task (order_id, value, worker_id, description, car_id)
VALUES
    (1, 2500.00, 1, 'Замена масла двигателя', 'WVWZZZ1JZXW000001'),
    (1, 800.00, 2, 'Замена масляного фильтра', 'WVWZZZ1JZXW000001'),
    (2, 1500.00, 2, 'Диагностика подвески', 'WBAAA31070B000002'),
    (3, 2200.00, 1, 'Шиномонтаж 4 колёс', 'XTA210990Y0000003');

-- autopart (task_id UNIQUE; опционально привязываем к purchase)
INSERT INTO autoservice_schema.autopart (name, purchase_id, task_id)
VALUES
    ('Масло 5W-30', 1, 1),
    ('Фильтр масляный', 1, 2),
    ('Балансировочные грузики', 2, 4);

-- payout (привязка к worker_id)
INSERT INTO autoservice_schema.payout (value, date, payout_type, worker_id)
VALUES
    (3000, CURRENT_TIMESTAMP - INTERVAL '1 days', 'Премия', 1),
    (2500, CURRENT_TIMESTAMP - INTERVAL '2 days', 'Сдельная', 2),
    (4000, CURRENT_TIMESTAMP - INTERVAL '5 days', 'Премия', 3);

COMMIT;