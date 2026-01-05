CREATE TABLE portfolio (
    portfolio_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8154) PRIMARY KEY,
    user_id INT NOT NULL,
    api_key_id INT NOT NULL,
    portfolio_name VARCHAR(100) NOT NULL UNIQUE,
    reserved_cash DECIMAL(18, 8) NOT NULL DEFAULT 0,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('ehe.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE portfolio
ADD CONSTRAINT fk_portfolio_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE portfolio
ADD CONSTRAINT fk_portfolio_api_key
FOREIGN KEY (api_key_id) REFERENCES api_key(api_key_id)
ON DELETE CASCADE;

ALTER TABLE portfolio
ADD CONSTRAINT chk_portfolio_reserved_cash
CHECK (reserved_cash >= 0);

ALTER TABLE portfolio
ADD CONSTRAINT chk_portfolio_portfolio_name
CHECK (portfolio_name ~ '^[a-zA-Z0-9_]{1,100}$');

CREATE OR REPLACE FUNCTION trg_portfolio_set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('ehe.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_portfolio_set_audit_fields
BEFORE UPDATE ON portfolio
FOR EACH ROW
EXECUTE PROCEDURE trg_portfolio_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_portfolio_audit_log_history()
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

    INSERT INTO portfolio_history (
        portfolio_id, user_id, api_key_id, portfolio_name,
        reserved_cash, creation_date, audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type
    ) VALUES (
        entity_record.portfolio_id, entity_record.user_id, entity_record.api_key_id,
        entity_record.portfolio_name, entity_record.reserved_cash,
        entity_record.creation_date, entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_portfolio_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON portfolio
FOR EACH ROW
EXECUTE PROCEDURE trg_portfolio_audit_log_history();