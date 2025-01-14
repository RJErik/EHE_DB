CREATE TABLE watchlist (
    watchlist_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3338) PRIMARY KEY,
    user_id INT NOT NULL
);

ALTER TABLE watchlist
ADD CONSTRAINT fk_watchlist_user
FOREIGN KEY (user_id) REFERENCES "user"(user_id);
