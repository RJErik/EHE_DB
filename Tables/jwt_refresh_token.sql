CREATE TABLE jwt_refresh_token (
    jwt_refresh_token_id INT GENERATED ALWAYS AS IDENTITY (START WITH 5508) PRIMARY KEY,
	user_id INT,
	jwt_refresh_token_hash VARCHAR(255) NOT NULL,
	jwt_refresh_token_expiry_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP + INTERVAL '7 day',
	jwt_refresh_token_max_expiry_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP + INTERVAL '30 day',
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE jwt_refresh_token
ADD CONSTRAINT fk_jwt_refresh_token_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE jwt_refresh_token
ADD CONSTRAINT chk_jwt_refresh_token_expiry_date
CHECK (jwt_refresh_token_expiry_date <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

ALTER TABLE jwt_refresh_token
ADD CONSTRAINT chk_jwt_refresh_token_max_expiry_date
CHECK (jwt_refresh_token_max_expiry_date <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

ALTER TABLE jwt_refresh_token
ADD CONSTRAINT chk_jwt_refresh_token_expiry_order
CHECK (jwt_refresh_token_expiry_date <= jwt_refresh_token_max_expiry_date);

CREATE OR REPLACE FUNCTION trg_jwt_refresh_token_set_audit_fields()
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

CREATE TRIGGER trg_jwt_refresh_token_set_audit_fields
BEFORE UPDATE ON jwt_refresh_token
FOR EACH ROW
EXECUTE PROCEDURE trg_jwt_refresh_token_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_jwt_refresh_token_audit_log_history()
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

    INSERT INTO jwt_refresh_token_history (
        jwt_refresh_token_id, user_id, jwt_refresh_token_hash,
        jwt_refresh_token_expiry_date, jwt_refresh_token_max_expiry_date,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.jwt_refresh_token_id, entity_record.user_id, entity_record.jwt_refresh_token_hash,
        entity_record.jwt_refresh_token_expiry_date, entity_record.jwt_refresh_token_max_expiry_date,
        entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type,
        CURRENT_TIMESTAMP
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_jwt_refresh_token_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON jwt_refresh_token
FOR EACH ROW
EXECUTE PROCEDURE trg_jwt_refresh_token_audit_log_history();