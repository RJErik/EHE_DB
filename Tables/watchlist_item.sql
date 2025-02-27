CREATE TABLE watchlist_item (
    watchlist_item_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3569) PRIMARY KEY,
    watchlist_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    date_added TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE watchlist_item
ADD CONSTRAINT fk_watchlist_item_watchlist
FOREIGN KEY (watchlist_id) REFERENCES watchlist(watchlist_id);

ALTER TABLE watchlist_item
ADD CONSTRAINT fk_watchlist_item_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE watchlist_item
ADD CONSTRAINT chk_watchlist_item_date_added
CHECK (date_added <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_watchlist_item_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO watchlist_item_history (
            watchlist_item_id, watchlist_id, platform_stock_id, date_added, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.watchlist_item_id, NEW.watchlist_id, NEW.platform_stock_id, NEW.date_added, 
            NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO watchlist_item_history (
            watchlist_item_id, watchlist_id, platform_stock_id, date_added, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.watchlist_item_id, OLD.watchlist_id, OLD.platform_stock_id, OLD.date_added, 
            OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO watchlist_item_history (
            watchlist_item_id, watchlist_id, platform_stock_id, date_added, 
            audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.watchlist_item_id, OLD.watchlist_id, OLD.platform_stock_id, OLD.date_added, 
            OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_watchlist_item_audit
BEFORE INSERT OR UPDATE OR DELETE ON watchlist_item
FOR EACH ROW
EXECUTE PROCEDURE trg_watchlist_item_audit();
