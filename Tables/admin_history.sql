CREATE TABLE admin_history (
    admin_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 7499) PRIMARY KEY,
    admin_id INT NOT NULL,
    permission_level VARCHAR(100) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
