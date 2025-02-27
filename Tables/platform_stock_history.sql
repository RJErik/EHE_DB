CREATE TABLE platform_stock_history (
    platform_stock_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    platform_stock_id INT,
    platform_name VARCHAR(100),
    stock_symbol VARCHAR(50),
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
