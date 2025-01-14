CREATE TABLE admin (
    admin_id INT PRIMARY KEY,
    permission_level VARCHAR(100) NOT NULL
);

ALTER TABLE admin
ADD CONSTRAINT fk_admin_user
FOREIGN KEY (admin_id) REFERENCES "user"(user_id);