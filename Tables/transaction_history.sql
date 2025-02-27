CREATE TABLE transaction_history (
    transaction_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id INT,
    portfolio_id INT,
    platform_stock_id INT,
    transaction_type VARCHAR(50),
    quantity DECIMAL(18, 8),
    price DECIMAL(18, 8),
    api_key_id INT,
    transaction_date TIMESTAMP,
    status VARCHAR(50),
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
