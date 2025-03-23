CREATE TABLE alert (
    alert_id INT GENERATED ALWAYS AS IDENTITY (START WITH 1457) PRIMARY KEY,
    user_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    condition_type VARCHAR(50) NOT NULL,
    threshold_value DECIMAL(18, 8) NOT NULL,
    date_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE alert
ADD CONSTRAINT fk_alert_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE alert
ADD CONSTRAINT fk_alert_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE alert
ADD CONSTRAINT chk_alert_condition_type
CHECK (condition_type IN ('Price above', 'Price below'));

ALTER TABLE alert
ADD CONSTRAINT chk_alert_threshold_value
CHECK (threshold_value > 0);

ALTER TABLE alert
ADD CONSTRAINT chk_alert_date_created
CHECK (date_created <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

CREATE OR REPLACE FUNCTION trg_alert_audit()
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

    INSERT INTO alert_history (
        alert_id, user_id, platform_stock_id, condition_type, 
        threshold_value, date_created, is_active, 
        audit_created_by, audit_created_date, 
        audit_updated_by, audit_updated_date, 
        audit_version_number, history_dml_type, 
        history_logged_date
    ) VALUES (
        entity_record.alert_id, entity_record.user_id, entity_record.platform_stock_id, 
        entity_record.condition_type, entity_record.threshold_value, entity_record.date_created, 
        entity_record.is_active, entity_record.audit_created_by, entity_record.audit_created_date, 
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

CREATE TRIGGER trg_alert_audit
BEFORE INSERT OR UPDATE OR DELETE ON alert
FOR EACH ROW
EXECUTE PROCEDURE trg_alert_audit();
