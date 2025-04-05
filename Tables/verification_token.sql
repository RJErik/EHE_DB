
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


-- Audit Trigger Function (Updated to include status)
CREATE OR REPLACE FUNCTION trg_verification_token_audit()
RETURNS TRIGGER AS $$
DECLARE
    dml_type CHAR(1);
    entity_record RECORD;
BEGIN
    IF TG_OP = 'INSERT' THEN
        dml_type := 'i';
        entity_record := NEW;
        -- Ensure status is set if default wasn't applied (shouldn't happen with default)
        IF entity_record.status IS NULL THEN
             entity_record.status := 'ACTIVE';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        dml_type := 'u';
        entity_record := OLD;
        -- Only update audit fields if non-audit columns changed, or specifically if status changed
        IF OLD IS DISTINCT FROM NEW AND OLD.status IS DISTINCT FROM NEW.status THEN
            NEW.audit_updated_by := current_setting('myapp.current_user', true);
            NEW.audit_updated_date := CURRENT_TIMESTAMP;
            NEW.audit_version_number := OLD.audit_version_number + 1;
        ELSE
             -- If only audit columns changed somehow, revert them
             NEW.audit_updated_by := OLD.audit_updated_by;
             NEW.audit_updated_date := OLD.audit_updated_date;
             NEW.audit_version_number := OLD.audit_version_number;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        dml_type := 'd';
        entity_record := OLD;
    END IF;

    INSERT INTO verification_token_history (
        verification_token_id, user_id, token, token_type, status, -- Added status
        issue_date, expiry_date,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.verification_token_id, entity_record.user_id, entity_record.token, entity_record.token_type,
        entity_record.status, -- Added status
        entity_record.issue_date, entity_record.expiry_date,
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

-- Audit Trigger
CREATE TRIGGER trg_verification_token_audit
BEFORE INSERT OR UPDATE OR DELETE ON verification_token
FOR EACH ROW
EXECUTE PROCEDURE trg_verification_token_audit();