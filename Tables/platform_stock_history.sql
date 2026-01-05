CREATE TABLE platform_stock_history (
    platform_stock_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3706) PRIMARY KEY,
    platform_stock_id INT NOT NULL,
    platform_id INT NOT NULL,
    stock_id INT NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);