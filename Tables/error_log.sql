CREATE TABLE error_log (
    error_log_id INT GENERATED ALWAYS AS IDENTITY (START WITH 5762) PRIMARY KEY,
    user_id INT NOT NULL,
    error_description TEXT NOT NULL,
    stack_trace TEXT NOT NULL,
    error_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE error_log
ADD CONSTRAINT fk_error_log_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);

ALTER TABLE error_log
ADD CONSTRAINT chk_error_log_error_date
CHECK (error_date <= CURRENT_TIMESTAMP);
