CREATE TABLE error_log (
    error_log_id INT GENERATED ALWAYS AS IDENTITY (START WITH 5762) PRIMARY KEY,
    user_id INT NOT NULL,
    error_description TEXT NOT NULL,
    stack_trace TEXT NOT NULL,
    error_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE error_log
ADD CONSTRAINT fk_error_log_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE error_log
ADD CONSTRAINT chk_error_log_error_date
CHECK (error_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_error_log_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO error_log_history (
            error_log_id, user_id, error_description, stack_trace, 
            error_date, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.error_log_id, NEW.user_id, NEW.error_description, NEW.stack_trace, 
            NEW.error_date, NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO error_log_history (
            error_log_id, user_id, error_description, stack_trace, 
            error_date, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.error_log_id, OLD.user_id, OLD.error_description, OLD.stack_trace, 
            OLD.error_date, OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO error_log_history (
            error_log_id, user_id, error_description, stack_trace, 
            error_date, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.error_log_id, OLD.user_id, OLD.error_description, OLD.stack_trace, 
            OLD.error_date, OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_error_log_audit
BEFORE INSERT OR UPDATE OR DELETE ON error_log
FOR EACH ROW
EXECUTE PROCEDURE trg_error_log_audit();
