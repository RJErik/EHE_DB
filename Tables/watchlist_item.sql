CREATE TABLE watchlist_item (
    watchlist_item_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3569) PRIMARY KEY,
    watchlist_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    date_added TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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
