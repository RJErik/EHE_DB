CREATE TABLE holding (
    holding_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8593) PRIMARY KEY,
    portfolio_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    purchase_price DECIMAL(18, 8) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE holding
ADD CONSTRAINT fk_holding_portfolio
FOREIGN KEY (portfolio_id) REFERENCES portfolio(portfolio_id);

ALTER TABLE holding
ADD CONSTRAINT fk_holding_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE holding
ADD CONSTRAINT chk_holding_quantity
CHECK (quantity > 0);

ALTER TABLE holding
ADD CONSTRAINT chk_holding_purchase_price
CHECK (purchase_price > 0);

CREATE OR REPLACE FUNCTION trg_holding_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO holding_history (
            holding_id, portfolio_id, platform_stock_id, quantity, 
            purchase_price, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.holding_id, NEW.portfolio_id, NEW.platform_stock_id, NEW.quantity, 
            NEW.purchase_price, NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO holding_history (
            holding_id, portfolio_id, platform_stock_id, quantity, 
            purchase_price, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.holding_id, OLD.portfolio_id, OLD.platform_stock_id, OLD.quantity, 
            OLD.purchase_price, OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO holding_history (
            holding_id, portfolio_id, platform_stock_id, quantity, 
            purchase_price, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.holding_id, OLD.portfolio_id, OLD.platform_stock_id, OLD.quantity, 
            OLD.purchase_price, OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_holding_audit
BEFORE INSERT OR UPDATE OR DELETE ON holding
FOR EACH ROW
EXECUTE PROCEDURE trg_holding_audit();
