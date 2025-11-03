CREATE TABLE jwt_refresh_token_history (
    jwt_refresh_token_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 1831) PRIMARY KEY,
    jwt_refresh_token_id INT NOT NULL,
    user_id INT,
    jwt_refresh_token_hash VARCHAR(255) NOT NULL,
    jwt_refresh_token_expiry_date TIMESTAMP NOT NULL,
    jwt_refresh_token_max_expiry_date TIMESTAMP NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);