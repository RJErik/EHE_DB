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
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
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
ADD CONSTRAINT chk_market_candle_timestamp
CHECK (timestamp <= CURRENT_timestamp);

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

CREATE OR REPLACE FUNCTION trg_market_candle_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_timestamp;
        NEW.audit_version_number := 0;

        INSERT INTO market_candle_history (
            market_candle_id, platform_stock_id, timeframe, timestamp, 
            open_price, close_price, high_price, low_price, volume, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.market_candle_id, NEW.platform_stock_id, NEW.timeframe, NEW.timestamp, 
            NEW.open_price, NEW.close_price, NEW.high_price, NEW.low_price, NEW.volume, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_timestamp
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_timestamp;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO market_candle_history (
            market_candle_id, platform_stock_id, timeframe, timestamp, 
            open_price, close_price, high_price, low_price, volume, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.market_candle_id, OLD.platform_stock_id, OLD.timeframe, OLD.timestamp, 
            OLD.open_price, OLD.close_price, OLD.high_price, OLD.low_price, OLD.volume, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_timestamp
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO market_candle_history (
            market_candle_id, platform_stock_id, timeframe, timestamp, 
            open_price, close_price, high_price, low_price, volume, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.market_candle_id, OLD.platform_stock_id, OLD.timeframe, OLD.timestamp, 
            OLD.open_price, OLD.close_price, OLD.high_price, OLD.low_price, OLD.volume, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_timestamp
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_market_candle_audit
BEFORE INSERT OR UPDATE OR DELETE ON market_candle
FOR EACH ROW
EXECUTE PROCEDURE trg_market_candle_audit();
