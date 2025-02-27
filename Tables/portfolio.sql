CREATE TABLE portfolio (
    portfolio_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8154) PRIMARY KEY,
    user_id INT NOT NULL,
    portfolio_name VARCHAR(100) NOT NULL,
    portfolio_type VARCHAR(50) NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_created_by VARCHAR(255) NOT NULL DEFAULT current_setting('myapp.current_user', true),
    audit_created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    audit_updated_by VARCHAR(255),
    audit_updated_date TIMESTAMP,
    audit_version_number INT NOT NULL DEFAULT 0
);

ALTER TABLE portfolio
ADD CONSTRAINT fk_portfolio_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE portfolio
ADD CONSTRAINT chk_portfolio_portfolio_type
CHECK (portfolio_type IN ('Real', 'Simulated'));

ALTER TABLE portfolio
ADD CONSTRAINT chk_portfolio_creation_date
CHECK (creation_date <= CURRENT_TIMESTAMP);

CREATE OR REPLACE FUNCTION trg_portfolio_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.audit_created_by := current_setting('myapp.current_user', true);
        NEW.audit_created_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := 0;

        INSERT INTO portfolio_history (
            portfolio_id, user_id, portfolio_name, portfolio_type, 
            creation_date, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            NEW.portfolio_id, NEW.user_id, NEW.portfolio_name, NEW.portfolio_type, 
            NEW.creation_date, NEW.audit_created_by, NEW.audit_created_date, 
            NULL, NULL, 
            NEW.audit_version_number, 'i', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.audit_updated_by := current_setting('myapp.current_user', true);
        NEW.audit_updated_date := CURRENT_TIMESTAMP;
        NEW.audit_version_number := OLD.audit_version_number + 1;

        INSERT INTO portfolio_history (
            portfolio_id, user_id, portfolio_name, portfolio_type, 
            creation_date, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.portfolio_id, OLD.user_id, OLD.portfolio_name, OLD.portfolio_type, 
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date, 
            NEW.audit_updated_by, NEW.audit_updated_date, 
            NEW.audit_version_number, 'u', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO portfolio_history (
            portfolio_id, user_id, portfolio_name, portfolio_type, 
            creation_date, audit_created_by, audit_created_date, 
            audit_updated_by, audit_updated_date, 
            audit_version_number, history_dml_type, 
            history_logged_date
        ) VALUES (
            OLD.portfolio_id, OLD.user_id, OLD.portfolio_name, OLD.portfolio_type, 
            OLD.creation_date, OLD.audit_created_by, OLD.audit_created_date, 
            OLD.audit_updated_by, OLD.audit_updated_date, 
            OLD.audit_version_number, 'd', CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_portfolio_audit
BEFORE INSERT OR UPDATE OR DELETE ON portfolio
FOR EACH ROW
EXECUTE PROCEDURE trg_portfolio_audit();
