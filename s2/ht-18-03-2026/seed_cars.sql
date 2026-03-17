INSERT INTO autoservice_schema.car (vin, model, plate_number, status, box_id, mileage)
VALUES
    ('VIN1234567890ABCD', 'Toyota Camry', 'А111АА77', 'in_progress', 1, 15000),
    ('VIN9876543210ZYXW', 'Hyundai Solaris', 'В222ВВ99', 'done', 2, 45000)
ON CONFLICT (vin)
    DO UPDATE SET
                  model = EXCLUDED.model,
                  plate_number = EXCLUDED.plate_number,
                  status = EXCLUDED.status,
                  box_id = EXCLUDED.box_id,
                  mileage = EXCLUDED.mileage;