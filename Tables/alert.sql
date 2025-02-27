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
    audit_updated_by VARCHAR(255),
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
CHECK (date_created <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_alert_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO alert_history (
            alert_id, user_id, platform_stock_id, condition_type, 
            threshold_value, date_created, is_active, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.alert_id, NEW.user_id, NEW.platform_stock_id, NEW.condition_type, 
            NEW.threshold_value, NEW.date_created, NEW.is_active, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO alert_history (
            alert_id, user_id, platform_stock_id, condition_type, 
            threshold_value, date_created, is_active, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.alert_id, OLD.user_id, OLD.platform_stock_id, OLD.condition_type, 
            OLD.threshold_value, OLD.date_created, OLD.is_active, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO alert_history (
            alert_id, user_id, platform_stock_id, condition_type, 
            threshold_value, date_created, is_active, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.alert_id, OLD.user_id, OLD.platform_stock_id, OLD.condition_type, 
            OLD.threshold_value, OLD.date_created, OLD.is_active, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alert_audit
BEFORE INSERT OR UPDATE OR DELETE ON alert
FOR EACH ROW
EXECUTE PROCEDURE trg_alert_audit();
