CREATE TABLE portfolio (
    portfolio_id INT GENERATED ALWAYS AS IDENTITY (START WITH 8154) PRIMARY KEY,
    user_id INT NOT NULL,
    portfolio_name VARCHAR(100) NOT NULL,
    portfolio_type VARCHAR(50) NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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
