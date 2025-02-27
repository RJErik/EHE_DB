CREATE TABLE portfolio_history (
    portfolio_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    portfolio_id INT,
    user_id INT,
    portfolio_name VARCHAR(100),
    portfolio_type VARCHAR(50),
    creation_date TIMESTAMP,
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
