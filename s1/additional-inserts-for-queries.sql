-- Дополнительные INSERT для работы всех подзапросов

BEGIN;

-- Добавляем дополнительные закупки у разных поставщиков для запроса 6.3
INSERT INTO autoservice_schema.purchase (provider_id, date, value) VALUES
(1, '2024-01-15 10:00:00', 15000.00), -- Москва
(1, '2024-02-20 14:30:00', 8000.00),  -- Москва
(2, '2024-03-10 09:15:00', 22000.00), -- СПб
(2, '2024-04-05 16:45:00', 12000.00); -- СПб

-- Добавляем дополнительные автомобили с одинаковыми моделями для запроса 8.2
INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id) VALUES
('1HGBH41JXMN109186', 'Toyota Camry', 'А123БВ116', 'В ремонте', 1),
('JH4TB2H26CC000001', 'Toyota Camry', 'В456ГД116', 'Готов', 2),
('1HGBH41JXMN109187', 'Honda Civic', 'Д789ЕЖ116', 'В ремонте', 3),
('JH4TB2H26CC000002', 'Honda Civic', 'З012ИК116', 'Ожидает', 1);

-- Добавляем дублирующего поставщика для запроса 8.3
INSERT INTO autoservice_schema.provider (address, phone_number) VALUES
('Москва, ул. Тверская, 7', '+7-495-200-00-01'); -- Дубль первого поставщика

-- Добавляем автозапчасти для связи с закупками
INSERT INTO autoservice_schema.autopart (name, purchase_id, task_id) VALUES
('Масляный фильтр Toyota', 1, NULL),
('Тормозные колодки', 2, NULL),
('Свечи зажигания Honda', 3, NULL),
('Амортизатор передний', 4, NULL),
('Масляный фильтр универсальный', 5, NULL);

COMMIT;

-- Проверочные запросы для тестирования:

-- Тест 6.3: Закупки дороже минимальной закупки у поставщика ID=1
SELECT pur.id, pur.date, pur.value, 'Тест 6.3' as test_name
FROM autoservice_schema.purchase pur
WHERE pur.value > ANY (
    SELECT pur2.value
    FROM autoservice_schema.purchase pur2
    WHERE pur2.provider_id = 1
);

-- Тест 8.1: Работники из филиалов с несколькими сотрудниками
SELECT w1.full_name, w1.role, w1.id_branch_office, 'Тест 8.1' as test_name
FROM autoservice_schema.worker w1
WHERE w1.id_branch_office IN (
    SELECT w2.id_branch_office
    FROM autoservice_schema.worker w2
    WHERE w2.id != w1.id
    GROUP BY w2.id_branch_office
    HAVING COUNT(*) > 0
);

-- Тест 8.2: Автомобили с повторяющимися моделями
SELECT c1.vin, c1.model, c1.status, c1.plate_number, 'Тест 8.2' as test_name
FROM autoservice_schema.car c1
WHERE c1.model IN (
    SELECT c2.model
    FROM autoservice_schema.car c2
    WHERE c2.vin != c1.vin
);

-- Тест 8.3: Поставщики с одинаковыми данными
SELECT p1.id, p1.address, p1.phone_number, 'Тест 8.3' as test_name
FROM autoservice_schema.provider p1
WHERE (p1.address, p1.phone_number) IN (
    SELECT p2.address, p2.phone_number
    FROM autoservice_schema.provider p2
    WHERE p2.id != p1.id
    AND p2.address IS NOT NULL
    AND p2.phone_number IS NOT NULL
);