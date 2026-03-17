INSERT INTO autoservice_schema.branch_office (id, address, phone_number)
VALUES
    (1, 'г. Москва, ул. Ленина, д. 10', '+7 (999) 111-22-33'),
    (2, 'г. Санкт-Петербург, Невский пр., 45', '+7 (999) 444-55-66'),
    (3, 'г. Казань, ул. Баумана, д. 20', '+7 (999) 777-88-99')
ON CONFLICT (id)
    DO NOTHING;

SELECT setval('autoservice_schema.branch_office_id_seq', (SELECT MAX(id) FROM autoservice_schema.branch_office));