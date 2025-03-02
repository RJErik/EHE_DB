CREATE TABLE text_annotation_history (
    text_annotation_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 2532) PRIMARY KEY,
    text_id INT NOT NULL,
    canvas_id INT NOT NULL,
    x TIMESTAMP NOT NULL,
    y DECIMAL(18,8) NOT NULL,
    content VARCHAR(500) NOT NULL,
    color VARCHAR(7) NOT NULL,
    font_size INT NOT NULL,
    creation_date TIMESTAMP NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
