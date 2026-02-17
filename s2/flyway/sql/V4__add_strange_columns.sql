
ALTER TABLE autoservice_schema.customer
    -- Высокая кардинальность (почти все уникальные, ~100%)
    ADD COLUMN email VARCHAR(255),

    -- Низкая селективность (3-5 значений: Bronze, Silver, Gold, Platinum)
    -- Будет использоваться для Skewed распределения
    ADD COLUMN loyalty_tier VARCHAR(20) DEFAULT 'Bronze',

    -- JSONB: Хранение профиля, настроек
    ADD COLUMN profile_data JSONB,

    -- Массивы: Теги интересов ['oil', 'tires', 'tuning']
    ADD COLUMN tags TEXT[];


ALTER TABLE autoservice_schema."order"
    -- NULL-значения (в 20% строк будет NULL)
    -- Используется для partial index
    ADD COLUMN discount_percent DECIMAL(5,2),

    -- Range-тип: Временной слот записи (tsrange)
    ADD COLUMN scheduling_slot TSRANGE,

    -- Текстовое поле для NULL-тестов и полнотекста
    ADD COLUMN manager_notes TEXT;


ALTER TABLE autoservice_schema.task
    -- Диапазонные значения (numrange) - например, [1000, 5000)
    ADD COLUMN estimated_cost_range NUMRANGE,

    -- Range-тип: Гарантийный период (daterange)
    ADD COLUMN warranty_period DATERANGE,

    -- Поле для Равномерного распределения (Uniform)
    -- Будем генерировать числа от 1 до 100 равномерно
    ADD COLUMN difficulty_score INT CHECK (difficulty_score BETWEEN 1 AND 100);


ALTER TABLE autoservice_schema.car
    -- Поле для Range-запросов (пробег)
    ADD COLUMN mileage INT DEFAULT 0,

    -- Вектор для полнотекстового поиска (tsvector)
    ADD COLUMN description_search TSVECTOR,

    -- Просто текстовое описание для генерации вектора
    ADD COLUMN history_log TEXT;
