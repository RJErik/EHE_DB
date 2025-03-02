CREATE TABLE line_history (
    line_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 9983) PRIMARY KEY,
    line_id INT NOT NULL,
    canvas_id INT NOT NULL,
    x1 TIMESTAMP NOT NULL,
    y1 DECIMAL(18,8) NOT NULL,
    x2 TIMESTAMP NOT NULL,
    y2 DECIMAL(18,8) NOT NULL,
    color VARCHAR(7) NOT NULL,
    thickness INT NOT NULL,
    creation_date TIMESTAMP NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
