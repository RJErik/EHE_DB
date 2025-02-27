CREATE TABLE automated_trade_rule (
    automated_trade_rule_id INT GENERATED ALWAYS AS IDENTITY (START WITH 9090) PRIMARY KEY,
    user_id INT NOT NULL,
    portfolio_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    condition_type VARCHAR(50) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    threshold_value DECIMAL(18, 8) NOT NULL,
    api_key_id INT NOT NULL,
    date_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
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

CREATE OR REPLACE FUNCTION trg_automated_trade_rule_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO automated_trade_rule_history (
            automated_trade_rule_id, user_id, portfolio_id, platform_stock_id, 
            condition_type, action_type, quantity, threshold_value, 
            api_key_id, date_created, is_active, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.automated_trade_rule_id, NEW.user_id, NEW.portfolio_id, NEW.platform_stock_id, 
            NEW.condition_type, NEW.action_type, NEW.quantity, NEW.threshold_value, 
            NEW.api_key_id, NEW.date_created, NEW.is_active, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO automated_trade_rule_history (
            automated_trade_rule_id, user_id, portfolio_id, platform_stock_id, 
            condition_type, action_type, quantity, threshold_value, 
            api_key_id, date_created, is_active, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.automated_trade_rule_id, OLD.user_id, OLD.portfolio_id, OLD.platform_stock_id, 
            OLD.condition_type, OLD.action_type, OLD.quantity, OLD.threshold_value, 
            OLD.api_key_id, OLD.date_created, OLD.is_active, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO automated_trade_rule_history (
            automated_trade_rule_id, user_id, portfolio_id, platform_stock_id, 
            condition_type, action_type, quantity, threshold_value, 
            api_key_id, date_created, is_active, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.automated_trade_rule_id, OLD.user_id, OLD.portfolio_id, OLD.platform_stock_id, 
            OLD.condition_type, OLD.action_type, OLD.quantity, OLD.threshold_value, 
            OLD.api_key_id, OLD.date_created, OLD.is_active, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_automated_trade_rule_audit
BEFORE INSERT OR UPDATE OR DELETE ON automated_trade_rule
FOR EACH ROW
EXECUTE PROCEDURE trg_automated_trade_rule_audit();
