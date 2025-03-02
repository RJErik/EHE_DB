CREATE TABLE point_history (
    point_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 2673) PRIMARY KEY,
    point_id INT NOT NULL,
    canvas_id INT NOT NULL,
    x TIMESTAMP NOT NULL,
    y DECIMAL(18,8) NOT NULL,
    color VARCHAR(7) NOT NULL,
    size INT NOT NULL,
    creation_date TIMESTAMP NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
