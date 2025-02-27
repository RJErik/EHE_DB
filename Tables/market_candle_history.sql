CREATE TABLE market_candle_history (
    market_candle_history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    market_candle_id INT,
    platform_stock_id INT,
    timeframe VARCHAR(50),
    timestamp TIMESTAMP,
    open_price DECIMAL(18, 8),
    close_price DECIMAL(18, 8),
    high_price DECIMAL(18, 8),
    low_price DECIMAL(18, 8),
    volume DECIMAL(18, 8),
    audit_created_by INT,
    audit_created_date TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
