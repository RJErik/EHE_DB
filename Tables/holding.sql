CREATE TABLE holding (
    holding_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8593) PRIMARY KEY,
    portfolio_id INT NOT NULL,
    platform_stock_id INT NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    purchase_price DECIMAL(18, 8) NOT NULL
);

ALTER TABLE holding
ADD CONSTRAINT fk_holding_portfolio
FOREIGN KEY (portfolio_id) REFERENCES portfolio(portfolio_id);

ALTER TABLE holding
ADD CONSTRAINT fk_holding_platform_stock
FOREIGN KEY (platform_stock_id) REFERENCES platform_stock(platform_stock_id);

ALTER TABLE holding
ADD CONSTRAINT chk_holding_quantity
CHECK (quantity > 0);

ALTER TABLE holding
ADD CONSTRAINT chk_holding_purchase_price
CHECK (purchase_price > 0);
