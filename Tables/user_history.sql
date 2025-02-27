CREATE TABLE user_history (
    user_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT,
    user_name VARCHAR(100),
    email_hash VARCHAR(255),
    password_hash VARCHAR(255),
    account_status VARCHAR(50),
    registration_date TIMESTAMP,
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
