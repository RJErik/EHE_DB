CREATE TABLE line (
    line_id INT GENERATED ALWAYS AS IDENTITY (START WITH 76338) PRIMARY KEY,
    canvas_id INT NOT NULL,
    x1 TIMESTAMP NOT NULL,
    y1 DECIMAL(18,8) NOT NULL,
    x2 TIMESTAMP NOT NULL,
    y2 DECIMAL(18,8) NOT NULL,
    color VARCHAR(7) NOT NULL,
    thickness INT NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE line
ADD CONSTRAINT fk_line_canvas
FOREIGN KEY (canvas_id) REFERENCES canvas(canvas_id);

ALTER TABLE line
ADD CONSTRAINT chk_line_color_format
CHECK (color ~ '^#[0-9A-Fa-f]{6}$');

ALTER TABLE line
ADD CONSTRAINT chk_line_thickness
CHECK (thickness BETWEEN 1 AND 10);

ALTER TABLE line
ADD CONSTRAINT chk_line_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP);

ALTER TABLE line
ADD CONSTRAINT chk_line_x_axis_date
CHECK (x1 <= CURRENT_TIMESTAMP OR x2 <= CURRENT_TIMESTAMP);

ALTER TABLE line
ADD CONSTRAINT chk_line_coordinates
CHECK (x1 != x2 OR y1 != y2);  -- Prevent zero-length lines

CREATE OR REPLACE FUNCTION trg_line_audit()
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
    
    INSERT INTO line_history (
        line_id, canvas_id, x1, y1, x2, y2, color, thickness,
        creation_date, audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date, audit_version_number,
        history_dml_type, history_logged_date
    ) VALUES (
        entity_record.line_id, entity_record.canvas_id, entity_record.x1, entity_record.y1,
        entity_record.x2, entity_record.y2, entity_record.color, entity_record.thickness,
        entity_record.creation_date, entity_record.audit_created_by, entity_record.audit_created_date,
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

CREATE TRIGGER trg_line_audit
BEFORE INSERT OR UPDATE OR DELETE ON line
FOR EACH ROW
EXECUTE PROCEDURE trg_line_audit();
