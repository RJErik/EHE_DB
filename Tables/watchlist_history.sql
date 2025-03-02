CREATE TABLE watchlist_history (
    watchlist_history_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8259) PRIMARY KEY,
    watchlist_id INT NOT NULL,
    user_id INT NOT NULL,
    audit_created_by VARCHAR(255) NOT NULL,
    audit_created_date TIMESTAMP NOT NULL,
    audit_updated_by VARCHAR(255) NOT NULL,
    audit_updated_date TIMESTAMP,
    audit_version_number INT,
    history_dml_type CHAR(1) NOT NULL CHECK (history_dml_type IN ('i', 'u', 'd')),
    history_logged_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
