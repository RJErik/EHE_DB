CREATE TABLE market_candle (
    market_candle_id INT GENERATED ALWAYS AS IDENTITY (START WITH 7958) PRIMARY KEY,
    platform_stock_id INT NOT NULL,
    timeframe VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    open_price DECIMAL(18, 8) NOT NULL,
    close_price DECIMAL(18, 8) NOT NULL,
    high_price DECIMAL(18, 8) NOT NULL,
    low_price DECIMAL(18, 8) NOT NULL,
    volume DECIMAL(18, 8) NOT NULL
);

ALTER TABLE market_candle
ADD CONSTRAINT fk_market_candle_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_timeframe
CHECK (timeframe IN ('1m', '5m', '15m', '1h', '4h', '1d'));

ALTER TABLE market_candle
ADD CONSTRAINT chk_market_candle_timestamp
CHECK (timestamp <= CURRENT_TIMESTAMP);

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
