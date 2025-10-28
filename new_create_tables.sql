-- SCHEMA: autoservice_schema

-- DROP SCHEMA IF EXISTS autoservice_schema ;

CREATE SCHEMA IF NOT EXISTS autoservice_schema;

create table autoservice_schema.branch_office
(
    id           SERIAL PRIMARY KEY,
    address      VARCHAR NOT NULL,
    phone_number VARCHAR NOT NULL
);

create table autoservice_schema.worker
(
    id               SERIAL PRIMARY KEY,
    full_name        VARCHAR                                              NOT NULL,
    role             VARCHAR                                              NOT NULL,
    phone_number     VARCHAR                                              NOT NULL,
    id_branch_office INT REFERENCES autoservice_schema.branch_office (id) NOT NULL
);

create table autoservice_schema.provider
(
    id           SERIAL PRIMARY KEY,
    address      VARCHAR,
    phone_number VARCHAR
);

create table autoservice_schema.customer
(
    id           SERIAL PRIMARY KEY,
    full_name    VARCHAR NOT NULL,
    phone_number VARCHAR NOT NULL
);

create table autoservice_schema.purchase
(
    id          SERIAL PRIMARY KEY,
    provider_id INT REFERENCES autoservice_schema.provider (id),
    date        TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    value       DECIMAL(100, 2)
);


create table autoservice_schema.order
(
    id              SERIAL PRIMARY KEY,
    customer_id     INT REFERENCES autoservice_schema.customer (id) NOT NULL,
    creation_date   TIMESTAMP WITHOUT TIME ZONE                                       NOT NULL,
    completion_date TIMESTAMP WITHOUT TIME ZONE                                        NOT NULL,
    status          varchar                                         NOT NULL,
    description     varchar

);

create table autoservice_schema.box
(
    id               SERIAL PRIMARY KEY,
    id_branch_office INT REFERENCES autoservice_schema.branch_office (id) NOT NULL,
    box_type         VARCHAR                                              NOT NULL
);

create table autoservice_schema.car
(
    vin          varchar(17) PRIMARY KEY,
    model        varchar                                    NOT NULL,
    plate_number varchar                                    NOT NULL,
    status       varchar                                    NOT NULL,
    box_id       INT REFERENCES autoservice_schema.box (id) NOT NULL

);

create table autoservice_schema.task
(
    id          SERIAL PRIMARY KEY,
    order_id    INT REFERENCES autoservice_schema.order (id)    NOT NULL,
    cost       DECIMAL(100, 2),
    worker_id   INT REFERENCES autoservice_schema.worker (id)   NOT NULL,
    task_type   varchar                                         NOT NULL,
    description varchar,
    car_id      VARCHAR REFERENCES autoservice_schema.car (vin) NOT NULL
);


create table autoservice_schema.autopart
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR NOT NULL,
    purchase_id INT REFERENCES autoservice_schema.purchase (id),
    task_id     INT UNIQUE REFERENCES autoservice_schema.task (id)
);



create table autoservice_schema.order_car
(
    order_id INT REFERENCES autoservice_schema.order (id)    NOT NULL,
    car_id   VARCHAR REFERENCES autoservice_schema.car (vin) NOT NULL
);

create table autoservice_schema.payout
(
    id          SERIAL PRIMARY KEY,
    value       INT     NOT NULL,
    date        TIMESTAMP WITHOUT TIME ZONE                                      NOT NULL,
    payout_type VARCHAR NOT NULL
);

ALTER TABLE autoservice_schema.branch_office
    add id_manager INT REFERENCES autoservice_schema.worker (id) NOT NULL;

ALTER TABLE autoservice_schema.payout
    add worker_id INT REFERENCES autoservice_schema.worker (id) NOT NULL;

ALTER TABLE autoservice_schema.task
    RENAME COLUMN cost TO value;

ALTER TABLE autoservice_schema.task
    ADD CONSTRAINT positive_value CHECK (value >= 0);

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