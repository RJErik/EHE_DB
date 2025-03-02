CREATE TABLE watchlist (
    watchlist_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3338) PRIMARY KEY,
    user_id INT NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE watchlist
ADD CONSTRAINT fk_watchlist_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

CREATE OR REPLACE FUNCTION trg_watchlist_audit()
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
        entity_record := OLD;
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;
    ELSIF TG_OP = 'DELETE' THEN
        dml_type := 'd';
        entity_record := OLD;
    END IF;
    INSERT INTO watchlist_history (
        watchlist_id, user_id, 
        audit_created_by, audit_created_date, 
        audit_updated_by, audit_updated_date, 
        audit_version_number, history_dml_type, 
        history_logged_date
    ) VALUES (
        entity_record.watchlist_id, entity_record.user_id, 
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

CREATE TRIGGER trg_watchlist_audit
BEFORE INSERT OR UPDATE OR DELETE ON watchlist
FOR EACH ROW
EXECUTE PROCEDURE trg_watchlist_audit();
