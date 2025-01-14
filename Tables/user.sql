CREATE TABLE "user" (
    user_id INT GENERATED ALWAYS AS IDENTITY (START WITH 1541) PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    email_hash VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    account_status VARCHAR(50) NOT NULL,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE "user"
ADD CONSTRAINT chk_user_user_name
CHECK (LENGTH(user_name) >= 3 AND user_name ~ '^[a-zA-Z0-9_]+$');

ALTER TABLE "user"
ADD CONSTRAINT chk_user_account_status
CHECK (account_status IN ('ACTIVE', 'SUSPENDED'));

ALTER TABLE "user"
ADD CONSTRAINT chk_user_registration_date
CHECK (registration_date <= CURRENT_TIMESTAMP);
