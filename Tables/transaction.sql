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
CHECK (transaction_date <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

CREATE OR REPLACE FUNCTION trg_transaction_audit()
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
        entity_record := OLD;
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;
    ELSIF TG_OP = 'DELETE' THEN
        dml_type := 'd';
        entity_record := OLD;
    END IF;
    INSERT INTO transaction_history (
        transaction_id, portfolio_id, platform_stock_id, transaction_type, 
        quantity, price, api_key_id, transaction_date, status, 
        audit_created_by, audit_created_date, 
        audit_updated_by, audit_updated_date, 
        audit_version_number, history_dml_type, 
        history_logged_date
    ) VALUES (
        entity_record.transaction_id, entity_record.portfolio_id, entity_record.platform_stock_id, 
        entity_record.transaction_type, entity_record.quantity, entity_record.price, entity_record.api_key_id, 
        entity_record.transaction_date, entity_record.status, entity_record.audit_created_by, 
        entity_record.audit_created_date, 
        CASE WHEN TG_OP = 'UPDATE' THEN NEW.audit_updated_by ELSE entity_record.audit_updated_by END,
        CASE WHEN TG_OP = 'UPDATE' THEN NEW.audit_updated_date ELSE entity_record.audit_updated_date END,
        CASE WHEN TG_OP = 'UPDATE' THEN NEW.audit_version_number ELSE entity_record.audit_version_number END,
        dml_type, CURRENT_TIMESTAMP
    );
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transaction_audit
BEFORE INSERT OR UPDATE OR DELETE ON transaction
FOR EACH ROW
EXECUTE PROCEDURE trg_transaction_audit();
