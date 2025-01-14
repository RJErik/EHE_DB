CREATE TABLE alert (
    alert_id INT GENERATED ALWAYS AS IDENTITY (START WITH 1457) PRIMARY KEY,
    user_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    condition_type VARCHAR(50) NOT NULL,
    threshold_value DECIMAL(18, 8) NOT NULL,
    date_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL
);

ALTER TABLE alert
ADD CONSTRAINT fk_alert_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE alert
ADD CONSTRAINT fk_alert_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE alert
ADD CONSTRAINT chk_alert_condition_type
CHECK (condition_type IN ('Price above', 'Price below'));

ALTER TABLE alert
ADD CONSTRAINT chk_alert_threshold_value
CHECK (threshold_value > 0);

ALTER TABLE alert
ADD CONSTRAINT chk_alert_date_created
CHECK (date_created <= CURRENT_TIMESTAMP);
