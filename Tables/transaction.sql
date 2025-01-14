CREATE TABLE transaction (
    transaction_id INT GENERATED ALWAYS AS IDENTITY (START WITH 3718) PRIMARY KEY,
    portfolio_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    price DECIMAL(18, 8) NOT NULL,
    api_key_id INT NOT NULL,
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL
);

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_portfolio
FOREIGN KEY (portfolio_id) REFERENCES portfolio(portfolio_id);

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_api_key
FOREIGN KEY (api_key_id) REFERENCES api_key(api_key_id);

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_transaction_type
CHECK (transaction_type IN ('Buy', 'Sell'));

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_quantity
CHECK (quantity > 0);

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_price
CHECK (price > 0);

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_status
CHECK (status IN ('Pending', 'Completed', 'Failed'));

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_transaction_date
CHECK (transaction_date <= CURRENT_TIMESTAMP);
