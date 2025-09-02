CREATE TABLE platform_stock (
    platform_stock_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3073) PRIMARY KEY,
    platform_name VARCHAR(100) NOT NULL,
    stock_symbol VARCHAR(50) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE platform_stock ADD CONSTRAINT unique_platform_stock_platform_symbol
UNIQUE (platform_name, stock_symbol);

CREATE OR REPLACE FUNCTION trg_platform_stock_set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_platform_stock_set_audit_fields
BEFORE UPDATE ON platform_stock
FOR EACH ROW
EXECUTE PROCEDURE trg_platform_stock_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_platform_stock_audit_log_history()
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

    INSERT INTO platform_stock_history (
        platform_stock_id, platform_name, stock_symbol,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.platform_stock_id, entity_record.platform_name, entity_record.stock_symbol,
        entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type,
        CURRENT_TIMESTAMP
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_platform_stock_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON platform_stock
FOR EACH ROW
EXECUTE PROCEDURE trg_platform_stock_audit_log_history();