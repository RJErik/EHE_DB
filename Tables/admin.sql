CREATE TABLE admin (
    admin_id INT PRIMARY KEY,
    permission_level VARCHAR(100) NOT NULL,
    audit_created_by INT NOT NULL,
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by INT,
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE admin
ADD CONSTRAINT fk_admin_user
FOREIGN KEY (admin_id) REFERENCES "user"(user_id);

CREATE OR REPLACE FUNCTION trg_admin_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO admin_history (
            admin_id, permission_level, audit_created_by, 
            audit_created_date, audit_updated_by, 
            audit_updated_date, audit_version_number, 
            history_dml_type, history_logged_date
        ) VALUES (
            NEW.admin_id, NEW.permission_level, NEW.audit_created_by, 
            NEW.audit_created_date, NEW.audit_updated_by, 
            NEW.audit_updated_date, NEW.audit_version_number, 
            'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by = NEW.audit_created_by;
        NEW.audit_updated_date = CURRENT_TIMESTAMP;
        NEW.audit_version_number = NEW.audit_version_number + 1;
        INSERT INTO admin_history (
            admin_id, permission_level, audit_created_by, 
            audit_created_date, audit_updated_by, 
            audit_updated_date, audit_version_number, 
            history_dml_type, history_logged_date
        ) VALUES (
            OLD.admin_id, OLD.permission_level, OLD.audit_created_by, 
            OLD.audit_created_date, NEW.audit_updated_by, 
            CURRENT_TIMESTAMP, NEW.audit_version_number, 
            'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO admin_history (
            admin_id, permission_level, audit_created_by, 
            audit_created_date, audit_updated_by, 
            audit_updated_date, audit_version_number, 
            history_dml_type, history_logged_date
        ) VALUES (
            OLD.admin_id, OLD.permission_level, OLD.audit_created_by, 
            OLD.audit_created_date, OLD.audit_updated_by, 
            OLD.audit_updated_date, OLD.audit_version_number, 
            'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_admin_audit
BEFORE INSERT OR UPDATE OR DELETE ON admin
FOR EACH ROW
EXECUTE PROCEDURE trg_admin_audit();
