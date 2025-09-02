CREATE TABLE portfolio (
    portfolio_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8154) PRIMARY KEY,
    user_id INT NOT NULL,
    api_key_id INT,
    portfolio_name VARCHAR(100) NOT NULL,
    portfolio_type VARCHAR(50) NOT NULL,
    reserved_cash DECIMAL(18, 8),
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
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
FOREIGN KEY (api_key_id) REFERENCES api_key(api_key_id);

ALTER TABLE portfolio
ADD CONSTRAINT chk_portfolio_portfolio_type
CHECK (portfolio_type IN ('Real', 'Simulated'));

ALTER TABLE portfolio
ADD CONSTRAINT chk_portfolio_real_api_key
CHECK (portfolio_type != 'Real' OR api_key_id IS NOT NULL);

ALTER TABLE portfolio
ADD CONSTRAINT chk_portfolio_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

CREATE OR REPLACE FUNCTION trg_portfolio_set_audit_fields()
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
        portfolio_id, user_id, api_key_id, portfolio_name, portfolio_type,
        reserved_cash, creation_date, audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.portfolio_id, entity_record.user_id, entity_record.api_key_id,
        entity_record.portfolio_name, entity_record.portfolio_type, entity_record.reserved_cash,
        entity_record.creation_date, entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type,
        CURRENT_TIMESTAMP
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_portfolio_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON portfolio
FOR EACH ROW
EXECUTE PROCEDURE trg_portfolio_audit_log_history();
