CREATE TABLE line_history (
    line_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    line_id INT,
    canvas_id INT,
    x1 TIMESTAMP,
    y1 DECIMAL(18,8),
    x2 TIMESTAMP,
    y2 DECIMAL(18,8),
    color VARCHAR(7),
    thickness INT,
    creation_date TIMESTAMP,
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
