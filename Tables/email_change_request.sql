CREATE TABLE email_change_request (
    email_change_request_id INT GENERATED ALWAYS AS IDENTITY (START WITH 9607) PRIMARY KEY,
    verification_token_id INT NOT NULL UNIQUE,
    new_email VARCHAR(255) NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('ehe.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE email_change_request
ADD CONSTRAINT fk_email_change_request_verification_token
FOREIGN KEY (verification_token_id) REFERENCES verification_token(verification_token_id) ON DELETE CASCADE;

ALTER TABLE email_change_request
ADD CONSTRAINT chk_email_change_request_new_email
CHECK (new_email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

CREATE INDEX idx_email_change_request_token_id ON email_change_request(verification_token_id);

CREATE OR REPLACE FUNCTION trg_email_change_request_set_audit_fields()
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

CREATE TRIGGER trg_email_change_request_set_audit_fields
BEFORE UPDATE ON email_change_request
FOR EACH ROW
EXECUTE PROCEDURE trg_email_change_request_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_email_change_request_audit_log_history()
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

    INSERT INTO email_change_request_history (
        email_change_request_id, verification_token_id, new_email,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type
    ) VALUES (
        entity_record.email_change_request_id, entity_record.verification_token_id, entity_record.new_email,
        entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_email_change_request_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON email_change_request
FOR EACH ROW
EXECUTE PROCEDURE trg_email_change_request_audit_log_history();

