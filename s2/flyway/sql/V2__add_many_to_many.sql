CREATE TABLE IF NOT EXISTS autoservice_schema.branch_office_manager
(
    branch_office_id INT PRIMARY KEY
        REFERENCES autoservice_schema.branch_office (id)
            ON DELETE CASCADE
            ON UPDATE CASCADE,
    manager_id       INT NOT NULL
        REFERENCES autoservice_schema.worker (id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE
);