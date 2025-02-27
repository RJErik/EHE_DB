CREATE TABLE alert_history (
    alert_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alert_id INT,
    user_id INT,
    platform_stock_id INT,
    condition_type VARCHAR(50),
    threshold_value DECIMAL(18, 8),
    date_created TIMESTAMP,
    is_active BOOLEAN,
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
