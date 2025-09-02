CREATE TABLE api_key (
    api_key_id INT GENERATED ALWAYS AS IDENTITY (START WITH 4438) PRIMARY KEY,
    user_id INT NOT NULL,
    platform_name VARCHAR(100) NOT NULL,
    api_key_value_encrypt VARCHAR(255) NOT NULL,
    secret_key_encrypt VARCHAR(255),
    date_added TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE api_key
ADD CONSTRAINT fk_api_key_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE api_key
ADD CONSTRAINT chk_api_key_date_added
CHECK (date_added <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

CREATE OR REPLACE FUNCTION trg_api_key_set_audit_fields()
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

CREATE TRIGGER trg_api_key_set_audit_fields
BEFORE UPDATE ON api_key
FOR EACH ROW
EXECUTE PROCEDURE trg_api_key_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_api_key_audit_log_history()
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

    INSERT INTO api_key_history (
        api_key_id, user_id, platform_name, api_key_value_encrypt,
        secret_key_encrypt, date_added, audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.api_key_id, entity_record.user_id, entity_record.platform_name,
        entity_record.api_key_value_encrypt, entity_record.secret_key_encrypt,
        entity_record.date_added, entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type,
        CURRENT_TIMESTAMP
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_api_key_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON api_key
FOR EACH ROW
EXECUTE PROCEDURE trg_api_key_audit_log_history();
