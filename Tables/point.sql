CREATE TABLE point (
    point_id INT GENERATED ALWAYS AS IDENTITY (START WITH 28723) PRIMARY KEY,
    canvas_id INT NOT NULL,
    x TIMESTAMP NOT NULL,
    y DECIMAL(18,8) NOT NULL,
    color VARCHAR(7) NOT NULL,
    size INT NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE point
ADD CONSTRAINT fk_point_canvas
FOREIGN KEY (canvas_id) REFERENCES canvas(canvas_id);

ALTER TABLE point
ADD CONSTRAINT chk_point_color
CHECK (color ~ '^#[0-9A-Fa-f]{6}$');  -- Hex color validation

ALTER TABLE point
ADD CONSTRAINT chk_point_size 
CHECK (size BETWEEN 1 AND 50);  -- Point size range

ALTER TABLE point
ADD CONSTRAINT chk_point_x_axis_date
CHECK (x <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

ALTER TABLE point
ADD CONSTRAINT chk_point_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

CREATE OR REPLACE FUNCTION trg_point_set_audit_fields()
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

CREATE TRIGGER trg_point_set_audit_fields
BEFORE UPDATE ON point
FOR EACH ROW
EXECUTE PROCEDURE trg_point_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_point_audit_log_history()
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
	
    INSERT INTO point_history (
        point_id, canvas_id, x, y, color, size, creation_date,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.point_id, entity_record.canvas_id, entity_record.x, entity_record.y,
        entity_record.color, entity_record.size, entity_record.creation_date,
        entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type,
        CURRENT_TIMESTAMP
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_point_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON point
FOR EACH ROW
EXECUTE PROCEDURE trg_point_audit_log_history();
