CREATE TABLE platform_stock (
    platform_stock_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3073) PRIMARY KEY,
    platform_name VARCHAR(100) NOT NULL UNIQUE,
    stock_symbol VARCHAR(50) NOT NULL UNIQUE,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION trg_platform_stock_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO platform_stock_history (
            platform_stock_id, platform_name, stock_symbol, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.platform_stock_id, NEW.platform_name, NEW.stock_symbol, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO platform_stock_history (
            platform_stock_id, platform_name, stock_symbol, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.platform_stock_id, OLD.platform_name, OLD.stock_symbol, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO platform_stock_history (
            platform_stock_id, platform_name, stock_symbol, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.platform_stock_id, OLD.platform_name, OLD.stock_symbol, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_platform_stock_audit
BEFORE INSERT OR UPDATE OR DELETE ON platform_stock
FOR EACH ROW
EXECUTE PROCEDURE trg_platform_stock_audit();
