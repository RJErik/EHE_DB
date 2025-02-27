CREATE TABLE text_annotation_history (
    text_annotation_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    text_id INT,
    canvas_id INT,
    x TIMESTAMP,
    y DECIMAL(18,8),
    content VARCHAR(500),
    color VARCHAR(7),
    font_size INT,
    creation_date TIMESTAMP,
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
