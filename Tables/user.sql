CREATE TABLE "user" (
    user_id INT GENERATED ALWAYS AS IDENTITY (START WITH 1541) PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email_hash VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    account_status VARCHAR(50) NOT NULL,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE "user"
ADD CONSTRAINT chk_user_user_name
CHECK (LENGTH(user_name) >= 3 AND user_name ~ '^[a-zA-Z0-9_]+$');

ALTER TABLE "user"
ADD CONSTRAINT chk_user_account_status
CHECK (account_status IN ('ACTIVE', 'SUSPENDED'));

ALTER TABLE "user"
ADD CONSTRAINT chk_user_registration_date
CHECK (registration_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_user_audit()
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
    INSERT INTO user_history (
        user_id, user_name, email_hash, password_hash, 
        account_status, registration_date, 
        audit_created_by, audit_created_date, 
        audit_updated_by, audit_updated_date, 
        audit_version_number, history_dml_type, 
        history_logged_date
    ) VALUES (
        entity_record.user_id, entity_record.user_name, entity_record.email_hash, entity_record.password_hash, 
        entity_record.account_status, entity_record.registration_date, 
        entity_record.audit_created_by, entity_record.audit_created_date, 
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

CREATE TRIGGER trg_user_audit
BEFORE INSERT OR UPDATE OR DELETE ON "user"
FOR EACH ROW
EXECUTE PROCEDURE trg_user_audit();
