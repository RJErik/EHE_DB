CREATE TABLE canvas (
    canvas_id INT GENERATED ALWAYS AS IDENTITY (START WITH 61221) PRIMARY KEY,
    user_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE canvas
ADD CONSTRAINT fk_canvas_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE canvas
ADD CONSTRAINT fk_canvas_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE canvas
ADD CONSTRAINT chk_canvas_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

ALTER TABLE canvas
ADD CONSTRAINT chk_canvas_name
CHECK (LENGTH(name) BETWEEN 1 AND 100);

CREATE OR REPLACE FUNCTION trg_canvas_audit()
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
    INSERT INTO canvas_history (
        canvas_id, user_id, platform_stock_id, name,
        creation_date, audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date, audit_version_number,
        history_dml_type, history_logged_date
    ) VALUES (
        entity_record.canvas_id, entity_record.user_id, entity_record.platform_stock_id, 
        entity_record.name, entity_record.creation_date, entity_record.audit_created_by, 
        entity_record.audit_created_date, 
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

CREATE TRIGGER trg_canvas_audit
BEFORE INSERT OR UPDATE OR DELETE ON canvas
FOR EACH ROW
EXECUTE PROCEDURE trg_canvas_audit();

