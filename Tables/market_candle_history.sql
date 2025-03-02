CREATE TABLE market_candle_history (
    market_candle_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 5472) PRIMARY KEY,
    market_candle_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    timeframe VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    open_price DECIMAL(18, 8) NOT NULL,
    close_price DECIMAL(18, 8) NOT NULL,
    high_price DECIMAL(18, 8) NOT NULL,
    low_price DECIMAL(18, 8) NOT NULL,
    volume DECIMAL(18, 8) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
