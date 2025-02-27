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
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO line_history (
            line_id, canvas_id, x1, y1, x2, y2, color, thickness,
            creation_date, audit_created_by, audit_created_date,
            audit_updated_by, audit_updated_date, audit_version_number,
            history_dml_type, history_logged_date
        ) VALUES (
            NEW.line_id, NEW.canvas_id, NEW.x1, NEW.y1, NEW.x2, NEW.y2, NEW.color, NEW.thickness,
            NEW.creation_date, NEW.audit_created_by, NEW.audit_created_date,
            NULL, NULL, NEW.audit_version_number,
            'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO line_history (
            line_id, canvas_id, x1, y1, x2, y2, color, thickness,
            creation_date, audit_created_by, audit_created_date,
            audit_updated_by, audit_updated_date, audit_version_number,
            history_dml_type, history_logged_date
        ) VALUES (
            OLD.line_id, OLD.canvas_id, OLD.x1, OLD.y1, OLD.x2, OLD.y2, OLD.color, OLD.thickness,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            NEW.audit_updated_by, NEW.audit_updated_date, NEW.audit_version_number,
            'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO line_history (
            line_id, canvas_id, x1, y1, x2, y2, color, thickness,
            creation_date, audit_created_by, audit_created_date,
            audit_updated_by, audit_updated_date, audit_version_number,
            history_dml_type, history_logged_date
        ) VALUES (
            OLD.line_id, OLD.canvas_id, OLD.x1, OLD.y1, OLD.x2, OLD.y2, OLD.color, OLD.thickness,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            OLD.audit_updated_by, OLD.audit_updated_date, OLD.audit_version_number,
            'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_line_audit
BEFORE INSERT OR UPDATE OR DELETE ON line
FOR EACH ROW
EXECUTE PROCEDURE trg_line_audit();
