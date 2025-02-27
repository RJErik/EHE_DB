CREATE TABLE error_log_history (
    error_log_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    error_log_id INT,
    user_id INT,
    error_description TEXT,
    stack_trace TEXT,
    error_date TIMESTAMP,
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);