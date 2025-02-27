CREATE TABLE transaction (
    transaction_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3718) PRIMARY KEY,
    portfolio_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    price DECIMAL(18, 8) NOT NULL,
    api_key_id INT NOT NULL,
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_portfolio
FOREIGN KEY (portfolio_id) REFERENCES portfolio(portfolio_id);

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_api_key
FOREIGN KEY (api_key_id) REFERENCES api_key(api_key_id);

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_transaction_type
CHECK (transaction_type IN ('Buy', 'Sell'));

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_quantity
CHECK (quantity > 0);

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_price
CHECK (price > 0);

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_status
CHECK (status IN ('Pending', 'Completed', 'Failed'));

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_transaction_date
CHECK (transaction_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_transaction_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO transaction_history (
            transaction_id, portfolio_id, platform_stock_id, transaction_type, 
            quantity, price, api_key_id, transaction_date, status, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.transaction_id, NEW.portfolio_id, NEW.platform_stock_id, NEW.transaction_type, 
            NEW.quantity, NEW.price, NEW.api_key_id, NEW.transaction_date, NEW.status, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO transaction_history (
            transaction_id, portfolio_id, platform_stock_id, transaction_type, 
            quantity, price, api_key_id, transaction_date, status, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.transaction_id, OLD.portfolio_id, OLD.platform_stock_id, OLD.transaction_type, 
            OLD.quantity, OLD.price, OLD.api_key_id, OLD.transaction_date, OLD.status, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO transaction_history (
            transaction_id, portfolio_id, platform_stock_id, transaction_type, 
            quantity, price, api_key_id, transaction_date, status, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.transaction_id, OLD.portfolio_id, OLD.platform_stock_id, OLD.transaction_type, 
            OLD.quantity, OLD.price, OLD.api_key_id, OLD.transaction_date, OLD.status, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transaction_audit
BEFORE INSERT OR UPDATE OR DELETE ON transaction
FOR EACH ROW
EXECUTE PROCEDURE trg_transaction_audit();
