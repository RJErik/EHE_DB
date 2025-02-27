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
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO user_history (
            user_id, user_name, email_hash, password_hash, 
            account_status, registration_date, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.user_id, NEW.user_name, NEW.email_hash, NEW.password_hash, 
            NEW.account_status, NEW.registration_date, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO user_history (
            user_id, user_name, email_hash, password_hash, 
            account_status, registration_date, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.user_id, OLD.user_name, OLD.email_hash, OLD.password_hash, 
            OLD.account_status, OLD.registration_date, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO user_history (
            user_id, user_name, email_hash, password_hash, 
            account_status, registration_date, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.user_id, OLD.user_name, OLD.email_hash, OLD.password_hash, 
            OLD.account_status, OLD.registration_date, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_audit
BEFORE INSERT OR UPDATE OR DELETE ON "user"
FOR EACH ROW
EXECUTE PROCEDURE trg_user_audit();
