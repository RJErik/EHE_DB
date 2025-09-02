
CREATE TABLE verification_token (
    verification_token_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    token_type VARCHAR(50) NOT NULL, -- e.g., REGISTRATION, PASSWORD_RESET, EMAIL_CHANGE
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- Status of the token
    issue_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

-- Foreign Key constraint
ALTER TABLE verification_token
ADD CONSTRAINT fk_verification_token_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE;

-- Check constraint for token type
ALTER TABLE verification_token
ADD CONSTRAINT chk_verification_token_type
CHECK (token_type IN ('REGISTRATION', 'PASSWORD_RESET', 'EMAIL_CHANGE'));

-- Check constraint for token status
ALTER TABLE verification_token
ADD CONSTRAINT chk_verification_token_status
CHECK (status IN ('ACTIVE', 'USED', 'EXPIRED', 'INVALIDATED'));

-- Index for faster token lookup
CREATE INDEX idx_verification_token_token ON verification_token(token);

-- Index for faster user token lookup
CREATE INDEX idx_verification_token_user_id ON verification_token(user_id);
CREATE INDEX idx_verification_token_user_type ON verification_token(user_id, token_type); -- For finding user tokens

CREATE OR REPLACE FUNCTION trg_verification_token_set_audit_fields()
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

CREATE TRIGGER trg_verification_token_set_audit_fields
BEFORE UPDATE ON verification_token
FOR EACH ROW
EXECUTE PROCEDURE trg_verification_token_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_verification_token_audit_log_history()
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

    INSERT INTO verification_token_history (
        verification_token_id, user_id, token, token_type, status,
        issue_date, expiry_date,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.verification_token_id, entity_record.user_id, entity_record.token, entity_record.token_type,
        entity_record.status,
        entity_record.issue_date, entity_record.expiry_date,
        entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type,
        CURRENT_TIMESTAMP
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verification_token_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON verification_token
FOR EACH ROW
EXECUTE PROCEDURE trg_verification_token_audit_log_history();