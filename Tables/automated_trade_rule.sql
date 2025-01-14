CREATE TABLE automated_trade_rule (
    rule_id INT GENERATED ALWAYS AS IDENTITY (START WITH 9090) PRIMARY KEY,
    user_id INT NOT NULL,
    portfolio_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    condition_type VARCHAR(50) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    threshold_value DECIMAL(18, 8) NOT NULL,
    api_key_id INT NOT NULL,
    date_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL
);

ALTER TABLE automated_trade_rule
ADD CONSTRAINT fk_automated_trade_rule_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE automated_trade_rule
ADD CONSTRAINT fk_automated_trade_rule_portfolio
FOREIGN KEY (portfolio_id) REFERENCES portfolio(portfolio_id);

ALTER TABLE automated_trade_rule
ADD CONSTRAINT fk_automated_trade_rule_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE automated_trade_rule
ADD CONSTRAINT fk_automated_trade_rule_api_key
FOREIGN KEY (api_key_id) REFERENCES api_key(api_key_id);

ALTER TABLE automated_trade_rule
ADD CONSTRAINT chk_automated_trade_rule_condition_type
CHECK (condition_type IN ('Price above', 'Price below'));

ALTER TABLE automated_trade_rule
ADD CONSTRAINT chk_automated_trade_rule_action_type
CHECK (action_type IN ('Buy', 'Sell'));

ALTER TABLE automated_trade_rule
ADD CONSTRAINT chk_automated_trade_rule_quantity
CHECK (quantity > 0);

ALTER TABLE automated_trade_rule
ADD CONSTRAINT chk_automated_trade_rule_threshold_value
CHECK (threshold_value > 0);

ALTER TABLE automated_trade_rule
ADD CONSTRAINT chk_automated_trade_rule_date_created
CHECK (date_created <= CURRENT_TIMESTAMP);
