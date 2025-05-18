CREATE TABLE portfolio_history (
    portfolio_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8969) PRIMARY KEY,
    portfolio_id INT NOT NULL,
    user_id INT NOT NULL,
    api_key_id INT,
    portfolio_name VARCHAR(100) NOT NULL,
    portfolio_type VARCHAR(50) NOT NULL,
    reserved_cash DECIMAL(18, 8),
    creation_date TIMESTAMP NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);