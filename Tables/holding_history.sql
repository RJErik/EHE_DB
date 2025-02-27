CREATE TABLE holding_history (
    holding_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    holding_id INT,
    portfolio_id INT,
    platform_stock_id INT,
    quantity DECIMAL(18, 8),
    purchase_price DECIMAL(18, 8),
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
