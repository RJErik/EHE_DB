CREATE TABLE email_change_request_history (
    email_change_request_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 7421) PRIMARY KEY,
    email_change_request_id INT NOT NULL,
    verification_token_id INT NOT NULL,
    new_email VARCHAR(255) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

