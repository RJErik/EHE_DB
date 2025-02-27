CREATE TABLE text_annotation (
    text_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8000) PRIMARY KEY,
    canvas_id INT NOT NULL,
    x TIMESTAMP NOT NULL,
    y DECIMAL(18,8) NOT NULL,
    content VARCHAR(500) NOT NULL,
    color VARCHAR(7) NOT NULL,
    font_size INT NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE text_annotation
ADD CONSTRAINT fk_text_annotation_canvas
FOREIGN KEY (canvas_id) REFERENCES canvas(canvas_id);

ALTER TABLE text_annotation
ADD CONSTRAINT chk_text_annotation_color
CHECK (color ~ '^#[0-9A-Fa-f]{6}$');

ALTER TABLE text_annotation
ADD CONSTRAINT chk_text_annotation_font_size
CHECK (font_size BETWEEN 8 AND 72);

ALTER TABLE text_annotation
ADD CONSTRAINT chk_text_annotation_content
CHECK (LENGTH(content) BETWEEN 1 AND 500);

ALTER TABLE line
ADD CONSTRAINT chk_text_annotation_x_axis_date
CHECK (x <= CURRENT_TIMESTAMP);

ALTER TABLE text_annotation
ADD CONSTRAINT chk_text_annotation_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_text_annotation_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO text_annotation_history (
            text_id, canvas_id, x, y, content, color, font_size, creation_date,
            audit_created_by, audit_created_date, audit_updated_by,
            audit_updated_date, audit_version_number, history_dml_type,
            history_logged_date
        ) VALUES (
            NEW.text_id, NEW.canvas_id, NEW.x, NEW.y, NEW.content, NEW.color, NEW.font_size,
            NEW.creation_date, NEW.audit_created_by, NEW.audit_created_date,
            NULL, NULL, NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO text_annotation_history (
            text_id, canvas_id, x, y, content, color, font_size, creation_date,
            audit_created_by, audit_created_date, audit_updated_by,
            audit_updated_date, audit_version_number, history_dml_type,
            history_logged_date
        ) VALUES (
            OLD.text_id, OLD.canvas_id, OLD.x, OLD.y, OLD.content, OLD.color, OLD.font_size,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            NEW.audit_updated_by, NEW.audit_updated_date, NEW.audit_version_number,
            'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO text_annotation_history (
            text_id, canvas_id, x, y, content, color, font_size, creation_date,
            audit_created_by, audit_created_date, audit_updated_by,
            audit_updated_date, audit_version_number, history_dml_type,
            history_logged_date
        ) VALUES (
            OLD.text_id, OLD.canvas_id, OLD.x, OLD.y, OLD.content, OLD.color, OLD.font_size,
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date,
            OLD.audit_updated_by, OLD.audit_updated_date, OLD.audit_version_number,
            'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_text_annotation_audit
BEFORE INSERT OR UPDATE OR DELETE ON text_annotation
FOR EACH ROW
EXECUTE PROCEDURE trg_text_annotation_audit();
