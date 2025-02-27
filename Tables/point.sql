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
CHECK (x <= CURRENT_TIMESTAMP);

ALTER TABLE point
ADD CONSTRAINT chk_point_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_point_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO point_history (
            point_id, canvas_id, x, y, color, size, creation_date,
            audit_created_by, audit_created_date, audit_updated_by, 
            audit_updated_date, audit_version_number, history_dml_type,
            history_logged_date
        ) VALUES (
            NEW.point_id, NEW.canvas_id, NEW.x, NEW.y, NEW.color, NEW.size,
            NEW.creation_date, NEW.audit_created_by, NEW.audit_created_date,
            NULL, NULL, NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO point_history (
            point_id, canvas_id, x, y, color, size, creation_date,
            audit_created_by, audit_created_date, audit_updated_by,
            audit_updated_date, audit_version_number, history_dml_type,
            history_logged_date
        ) VALUES (
            OLD.point_id, OLD.canvas_id, OLD.x, OLD.y, OLD.color, OLD.size,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            NEW.audit_updated_by, NEW.audit_updated_date, NEW.audit_version_number,
            'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO point_history (
            point_id, canvas_id, x, y, color, size, creation_date,
            audit_created_by, audit_created_date, audit_updated_by,
            audit_updated_date, audit_version_number, history_dml_type,
            history_logged_date
        ) VALUES (
            OLD.point_id, OLD.canvas_id, OLD.x, OLD.y, OLD.color, OLD.size,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            OLD.audit_updated_by, OLD.audit_updated_date, OLD.audit_version_number,
            'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_point_audit
BEFORE INSERT OR UPDATE OR DELETE ON point
FOR EACH ROW
EXECUTE PROCEDURE trg_point_audit();
