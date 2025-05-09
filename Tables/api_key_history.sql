CREATE TABLE api_key_history (
    api_key_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 7529) PRIMARY KEY,
    api_key_id INT NOT NULL,
    user_id INT NOT NULL,
    platform_name VARCHAR(100) NOT NULL,
    api_key_value_encrypt VARCHAR(255) NOT NULL,
    date_added TIMESTAMP NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
