-- branch_office
INSERT INTO autoservice_schema.branch_office (address, phone_number)
VALUES ('123 Main St', '+1234567890'),
       ('456 Oak Ave', '+0987654321'),
       ('789 Maple Rd', '+1122334455');

-- worker
INSERT INTO autoservice_schema.worker (full_name, role, phone_number, id_branch_office)
VALUES ('Ivan Ivanov', 'Manager', '+1111111111', 23),
       ('Petr Petrov', 'Mechanic', '+2222222222', 23),
       ('Svetlana Sidorova', 'Receptionist', '+3333333333', 24);

-- Обновление id_manager в branch_office (через UPDATE)
UPDATE autoservice_schema.branch_office
SET id_manager = 22
WHERE id = 23;

UPDATE autoservice_schema.branch_office
SET id_manager = 23
WHERE id = 24;

UPDATE autoservice_schema.branch_office
SET id_manager = 24
WHERE id = 25;

-- provider
INSERT INTO autoservice_schema.provider (address, phone_number)
VALUES ('Supplier St 1', '+5555555555'),
       ('Supplier St 2', '+6666666666'),
       ('Supplier St 3', '+7777777777');

-- customer
INSERT INTO autoservice_schema.customer (full_name, phone_number)
VALUES ('Alex Johnson', '+4444444444'),
       ('Maria White', '+5555555555'),
       ('John Black', '+6666666666');

-- purchase
INSERT INTO autoservice_schema.purchase (provider_id, date, value)
VALUES (1, '2025-09-29 09:00:00', 1500.00),
       (2, '2025-09-28 14:30:00', 2300.50),
       (3, '2025-09-27 16:00:00', 499.99);

-- order
INSERT INTO autoservice_schema.order (customer_id, creation_date, completion_date, status, description)
VALUES (1, '2025-09-20 08:00:00', '2025-09-25 18:00:00', 'Completed', 'Oil change and tire rotation'),
       (2, '2025-09-22 09:30:00', '2025-09-27 17:00:00', 'In Progress', 'Brake replacement'),
       (3, '2025-09-23 10:00:00', '2025-09-29 12:00:00', 'Pending', 'Engine diagnostics');

-- box
INSERT INTO autoservice_schema.box (id_branch_office, box_type)
VALUES (23, 'Repair'),
       (23, 'Painting'),
       (24, 'Inspection');

-- car
INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id)
VALUES ('1HGBH41JXMN109186', 'Toyota Corolla', 'A123BC77', 'In Service', 7),
       ('4T1BF1FK5HU123456', 'Honda Civic', 'B456CD99', 'Waiting', 8),
       ('KM8J33AL1JU622222', 'Hyundai Tucson', 'C789EF33', 'Completed', 9);

-- task
INSERT INTO autoservice_schema.task (order_id, value, worker_id, task_type, description, car_id)
VALUES (4, 100.00, 22, 'Maintenance', 'Changed oil and rotated tires', '1HGBH41JXMN109186'),
       (5, 300.00, 22, 'Repair', 'Replaced brake pads', '4T1BF1FK5HU123456'),
       (6, 150.00, 23, 'Diagnostics', 'Engine check and error code reading', 'KM8J33AL1JU622222');

-- autopart
INSERT INTO autoservice_schema.autopart (name, purchase_id, task_id)
VALUES ('Oil Filter', 4, 7),
       ('Brake Pad Set', 5, 8),
       ('Engine Sensor', 6, 9);

-- order_car
INSERT INTO autoservice_schema.order_car (order_id, car_id)
VALUES (4, '1HGBH41JXMN109186'),
       (5, '4T1BF1FK5HU123456'),
       (6, 'KM8J33AL1JU622222');

-- payout
INSERT INTO autoservice_schema.payout (worker_id, value, date, payout_type)
VALUES (22, 500, '2025-09-30 10:00:00', 'Salary'),
       (24, 150, '2025-09-30 10:00:00', 'Bonus'),
       (23, 100, '2025-10-01 10:00:00', 'Overtime');



UPDATE autoservice_schema.branch_office
SET phone_number = '+19998887766'
WHERE id = 23;


UPDATE autoservice_schema.worker
SET role = 'Senior Mechanic'
WHERE id = 24;


UPDATE autoservice_schema.car
SET status = 'Ready for Pickup'
WHERE vin = '1HGBH41JXMN109186';


UPDATE autoservice_schema."order"
SET status          = 'Completed',
    completion_date = CURRENT_TIMESTAMP
WHERE id = 4;

UPDATE autoservice_schema.task
SET value = 120.00
WHERE id = 7;