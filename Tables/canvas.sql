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
CHECK (creation_date <= CURRENT_TIMESTAMP);

ALTER TABLE canvas
ADD CONSTRAINT chk_canvas_name
CHECK (LENGTH(name) BETWEEN 1 AND 100);

CREATE OR REPLACE FUNCTION trg_canvas_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO canvas_history (
            canvas_id, user_id, platform_stock_id, name,
            creation_date, audit_created_by, audit_created_date,
            audit_updated_by, audit_updated_date, audit_version_number,
            history_dml_type, history_logged_date
        ) VALUES (
            NEW.canvas_id, NEW.user_id, NEW.platform_stock_id, NEW.name,
            NEW.creation_date, NEW.audit_created_by, NEW.audit_created_date,
            NULL, NULL, NEW.audit_version_number,
            'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO canvas_history (
            canvas_id, user_id, platform_stock_id, name,
            creation_date, audit_created_by, audit_created_date,
            audit_updated_by, audit_updated_date, audit_version_number,
            history_dml_type, history_logged_date
        ) VALUES (
            OLD.canvas_id, OLD.user_id, OLD.platform_stock_id, OLD.name,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            NEW.audit_updated_by, NEW.audit_updated_date, NEW.audit_version_number,
            'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO canvas_history (
            canvas_id, user_id, platform_stock_id, name,
            creation_date, audit_created_by, audit_created_date,
            audit_updated_by, audit_updated_date, audit_version_number,
            history_dml_type, history_logged_date
        ) VALUES (
            OLD.canvas_id, OLD.user_id, OLD.platform_stock_id, OLD.name,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            OLD.audit_updated_by, OLD.audit_updated_date, OLD.audit_version_number,
            'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_canvas_audit
BEFORE INSERT OR UPDATE OR DELETE ON canvas
FOR EACH ROW
EXECUTE PROCEDURE trg_canvas_audit();
