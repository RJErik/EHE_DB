CREATE TABLE error_log_history (
    error_log_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 2208) PRIMARY KEY,
    error_log_id INT NOT NULL,
    user_id INT NOT NULL,
    error_description TEXT NOT NULL,
    stack_trace TEXT NOT NULL,
    error_date TIMESTAMP NOT NULL,
    audit_created_by INT NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);