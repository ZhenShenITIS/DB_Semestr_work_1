INSERT INTO autoservice_schema.customer (id, full_name, phone_number, email, loyalty_tier)
VALUES
    (1, 'Иван Иванов', '+79001112233', 'ivan@example.com', 'Gold'),
    (2, 'Петр Петров', '+79004445566', 'petr@example.com', 'Silver'),
    (3, 'Анна Смирнова', '+79007778899', 'anna@example.com', 'Platinum')
ON CONFLICT (id)
    DO UPDATE SET
                  full_name = EXCLUDED.full_name,
                  phone_number = EXCLUDED.phone_number,
                  email = EXCLUDED.email,
                  loyalty_tier = EXCLUDED.loyalty_tier;

SELECT setval('autoservice_schema.customer_id_seq', (SELECT MAX(id) FROM autoservice_schema.customer));