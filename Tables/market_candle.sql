CREATE TABLE market_candle (
    market_candle_id INT GENERATED ALWAYS AS IDENTITY (START WITH 7958) PRIMARY KEY,
    platform_stock_id INT NOT NULL,
    timeframe VARCHAR(50) NOT NULL,
    timestamp timestamp NOT NULL,
    open_price DECIMAL(18, 8) NOT NULL,
    close_price DECIMAL(18, 8) NOT NULL,
    high_price DECIMAL(18, 8) NOT NULL,
    low_price DECIMAL(18, 8) NOT NULL,
    volume DECIMAL(18, 8) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('ehe.current_user', true),
    audit_created_date timestamp NOT NULL DEFAULT CURRENT_timestamp,
    audit_updated_by VARCHAR(255),
    audit_updated_date timestamp,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE market_candle
ADD CONSTRAINT fk_market_candle_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_timeframe
CHECK (timeframe IN ('1m', '5m', '15m', '1h', '4h', '1d'));

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_prices_positive
CHECK (open_price > 0 AND close_price > 0 AND high_price > 0 AND low_price > 0);

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_high_price
CHECK (high_price >= open_price AND high_price >= close_price AND high_price >= low_price);

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_low_price
CHECK (low_price <= open_price AND low_price <= close_price AND low_price <= high_price);

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_open_price_range
CHECK (open_price BETWEEN low_price AND high_price);

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_close_price_range
CHECK (close_price BETWEEN low_price AND high_price);

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_volume
CHECK (volume >= 0);

ALTER TABLE market_candle 
ADD CONSTRAINT uq_market_candle 
UNIQUE (platform_stock_id, timeframe, timestamp);


CREATE OR REPLACE FUNCTION trg_market_candle_set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('ehe.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_market_candle_set_audit_fields
BEFORE UPDATE ON market_candle
FOR EACH ROW
EXECUTE PROCEDURE trg_market_candle_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_market_candle_audit_log_history()
RETURNS TRIGGER AS $$
DECLARE
    dml_type CHAR(1);
    entity_record RECORD;
BEGIN
    IF TG_OP = 'INSERT' THEN
        dml_type := 'i';
        entity_record := NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        dml_type := 'u';
        entity_record := NEW;
    ELSIF TG_OP = 'DELETE' THEN
        dml_type := 'd';
        entity_record := OLD;
    END IF;

    INSERT INTO market_candle_history (
        market_candle_id, platform_stock_id, timeframe, timestamp,
        open_price, close_price, high_price, low_price, volume,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type
    ) VALUES (
        entity_record.market_candle_id, entity_record.platform_stock_id, entity_record.timeframe, entity_record.timestamp,
        entity_record.open_price, entity_record.close_price, entity_record.high_price, entity_record.low_price, entity_record.volume,
        entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_market_candle_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON market_candle
FOR EACH ROW
EXECUTE PROCEDURE trg_market_candle_audit_log_history();

-- Primary lookup index: Used by findByPlatformStockAndTimeframeAndTimestampEquals
CREATE INDEX idx_market_candle_stock_timeframe_timestamp 
ON market_candle(platform_stock_id, timeframe, timestamp);

-- Foreign key lookup optimization
CREATE INDEX idx_market_candle_platform_stock_id 
ON market_candle(platform_stock_id);

-- Time-based queries (finding latest candles)
CREATE INDEX idx_market_candle_timestamp_desc 
ON market_candle(timestamp DESC);