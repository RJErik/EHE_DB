CREATE TABLE log (
    log_id INT GENERATED ALWAYS AS IDENTITY (START WITH 9867) PRIMARY KEY,
    user_id INT NOT NULL,
    log_description TEXT NOT NULL,
    log_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by INT NOT NULL,
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE log
ADD CONSTRAINT fk_log_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE log
ADD CONSTRAINT chk_log_log_date
CHECK (log_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_log_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO log_history (
            log_id, user_id, log_description, log_date, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.log_id, NEW.user_id, NEW.log_description, NEW.log_date, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by = NEW.audit_created_by;
        NEW.audit_updated_date = CURRENT_TIMESTAMP;
        NEW.audit_version_number = NEW.audit_version_number + 1;
        INSERT INTO log_history (
            log_id, user_id, log_description, log_date, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.log_id, OLD.user_id, OLD.log_description, OLD.log_date, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, CURRENT_TIMESTAMP, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO log_history (
            log_id, user_id, log_description, log_date, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.log_id, OLD.user_id, OLD.log_description, OLD.log_date, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_audit
BEFORE INSERT OR UPDATE OR DELETE ON log
FOR EACH ROW
EXECUTE PROCEDURE trg_log_audit();
