CREATE TABLE api_key (
    api_key_id INT GENERATED ALWAYS AS IDENTITY (START WITH 4438) PRIMARY KEY,
    user_id INT NOT NULL,
    platform_name VARCHAR(100) NOT NULL,
    api_key_value_hash VARCHAR(255) NOT NULL,
    date_added TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE api_key
ADD CONSTRAINT fk_api_key_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE api_key
ADD CONSTRAINT chk_api_key_date_added
CHECK (date_added <= CURRENT_TIMESTAMP);
