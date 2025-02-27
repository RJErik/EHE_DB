CREATE TABLE api_key (
    api_key_id INT GENERATED ALWAYS AS IDENTITY (START WITH 4438) PRIMARY KEY,
    user_id INT NOT NULL,
    platform_name VARCHAR(100) NOT NULL,
    api_key_value_encrypt VARCHAR(255) NOT NULL,
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
CHECK (date_added <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_api_key_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO api_key_history (
            api_key_id, user_id, platform_name, api_key_value_encrypt, 
            date_added, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.api_key_id, NEW.user_id, NEW.platform_name, NEW.api_key_value_encrypt, 
            NEW.date_added, NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO api_key_history (
            api_key_id, user_id, platform_name, api_key_value_encrypt, 
            date_added, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.api_key_id, OLD.user_id, OLD.platform_name, OLD.api_key_value_encrypt, 
            OLD.date_added, OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO api_key_history (
            api_key_id, user_id, platform_name, api_key_value_encrypt, 
            date_added, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.api_key_id, OLD.user_id, OLD.platform_name, OLD.api_key_value_encrypt, 
            OLD.date_added, OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_api_key_audit
BEFORE INSERT OR UPDATE OR DELETE ON api_key
FOR EACH ROW
EXECUTE PROCEDURE trg_api_key_audit();
