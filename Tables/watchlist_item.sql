CREATE TABLE watchlist_item (
    watchlist_item_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3569) PRIMARY KEY,
    user_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    date_added TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE watchlist_item
ADD CONSTRAINT fk_watchlist_item_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE watchlist_item
ADD CONSTRAINT fk_watchlist_item_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE watchlist_item
ADD CONSTRAINT chk_watchlist_item_date_added
CHECK (date_added <= CURRENT_TIMESTAMP + INTERVAL '1 minute');

CREATE OR REPLACE FUNCTION trg_watchlist_item_set_audit_fields()
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

CREATE TRIGGER trg_watchlist_item_set_audit_fields
BEFORE UPDATE ON watchlist_item
FOR EACH ROW
EXECUTE PROCEDURE trg_watchlist_item_set_audit_fields();

CREATE OR REPLACE FUNCTION trg_watchlist_item_audit_log_history()
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

    INSERT INTO watchlist_item_history (
        watchlist_item_id, user_id, platform_stock_id, date_added,
        audit_created_by, audit_created_date,
        audit_updated_by, audit_updated_date,
        audit_version_number, history_dml_type,
        history_logged_date
    ) VALUES (
        entity_record.watchlist_item_id, entity_record.user_id, entity_record.platform_stock_id,
        entity_record.date_added, entity_record.audit_created_by, entity_record.audit_created_date,
        entity_record.audit_updated_by, entity_record.audit_updated_date,
        entity_record.audit_version_number,
        dml_type,
        CURRENT_TIMESTAMP
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_watchlist_item_audit_log_history
AFTER INSERT OR UPDATE OR DELETE ON watchlist_item
FOR EACH ROW
EXECUTE PROCEDURE trg_watchlist_item_audit_log_history();
