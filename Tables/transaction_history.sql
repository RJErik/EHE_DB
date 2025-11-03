CREATE TABLE transaction_history (
    transaction_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 7123) PRIMARY KEY,
    transaction_id INT NOT NULL,
    portfolio_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    price DECIMAL(18, 8) NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);