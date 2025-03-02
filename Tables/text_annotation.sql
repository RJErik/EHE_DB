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

ALTER TABLE text_annotation
ADD CONSTRAINT chk_text_annotation_x_axis_date
CHECK (x <= CURRENT_TIMESTAMP);

ALTER TABLE text_annotation
ADD CONSTRAINT chk_text_annotation_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_text_annotation_audit()
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
    
    INSERT INTO text_annotation_history (
        text_id, canvas_id, x, y, content, color, font_size, creation_date,
        audit_created_by, audit_created_date, 
        audit_updated_by, audit_updated_date, 
        audit_version_number, history_dml_type, 
        history_logged_date
    ) VALUES (
        entity_record.text_id, entity_record.canvas_id, entity_record.x, entity_record.y, 
        entity_record.content, entity_record.color, entity_record.font_size, entity_record.creation_date,
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

CREATE TRIGGER trg_text_annotation_audit
BEFORE INSERT OR UPDATE OR DELETE ON text_annotation
FOR EACH ROW
EXECUTE PROCEDURE trg_text_annotation_audit();