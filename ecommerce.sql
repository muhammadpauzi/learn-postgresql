/*
Pages:

#USERS
#PRODUCTS
#ORDERS
#TRIGGERS
#JOIN

* just find by the pages id (eg. #USERS)
*/

-- Active: 1735479244248@@127.0.0.1@5432@ecommerce
CREATE DATABASE ecommerce;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- Install the UUID extension (if not already installed)


-- #TRIGGERS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- #ENDTRIGGERS

-- #USERS
CREATE TABLE users (
    "id" BIGSERIAL PRIMARY KEY,
    "name" VARCHAR(64) NOT NULL,
    "email" VARCHAR(128) UNIQUE NOT NULL,
    "password" VARCHAR(256) NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO "users" ("name", "email", "password") VALUES
('John Doe', 'john.doe@example.com', '??'),
('Jane Smith', 'jane.smith@example.com', '??'),
('Alice Johnson', 'alice.johnson@example.com', '??'),
('Bob Brown', 'bob.brown@example.com', '??'),
('Charlie Davis', 'charlie.davis@example.com', '??'),
('David Wilson', 'david.wilson@example.com', '??'),
('Eve Clark', 'eve.clark@example.com', '??'),
('Frank Miller', 'frank.miller@example.com', '??'),
('Grace Lee', 'grace.lee@example.com', '??'),
('Hank Harris', 'hank.harris@example.com', '??'),
('Ivy Walker', 'ivy.walker@example.com', '??'),
('Jack Hall', 'jack.hall@example.com', '??'),
('Kathy Young', 'kathy.young@example.com', '??'),
('Leo King', 'leo.king@example.com', '??'),
('Mia Scott', 'mia.scott@example.com', '??'),
('Nina Green', 'nina.green@example.com', '??'),
('Oscar Adams', 'oscar.adams@example.com', '??'),
('Paul Baker', 'paul.baker@example.com', '??'),
('Quinn Carter', 'quinn.carter@example.com', '??'),
('Rita Evans', 'rita.evans@example.com', '??');

SELECT * FROM users;

-- automatically update "updated_at" field
UPDATE users SET password = '**??**' WHERE id = 1;
SELECT * FROM users WHERE id = 1;
-- #ENDUSERS

-- #PRODUCTS
CREATE TABLE "products" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(128) NOT NULL,
    description TEXT,
    price DECIMAL(20, 2) NOT NULL DEFAULT 0,
    tags TEXT[],
    details JSONB,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE products;

INSERT INTO products (name, description, tags, details) VALUES
('Laptop X1', 'Powerful laptop with 16GB RAM and 1TB SSD', ARRAY['electronics', 'computers', 'laptops'],
 '{"processor": "Intel i7", "ram": "16GB", "storage": "1TB SSD", "screen_size": "15.6 inch"}'),
('T-Shirt Y', 'Cotton T-shirt in various colors', ARRAY['clothing', 'shirts', 'casual'],
 '{"color": "red", "size": "M", "material": "100% cotton"}'),
('Book Z', 'A thrilling mystery novel', ARRAY['books', 'fiction', 'mystery'],
 '{"author": "John Doe", "pages": 320, "isbn": "978-1234567890"}');

-- if frequently searched
CREATE INDEX idx_products_name ON products (name);

-- use GIN, because GIN fit for array searches
CREATE INDEX idx_products_tags ON products USING GIN (tags); 

SELECT * FROM products;
SELECT * FROM products WHERE tags && ARRAY['electronics', 'books']; -- Products with either 'electronics' OR 'books' tag (or both)
SELECT * FROM products WHERE tags @> ARRAY['electronics'];

SELECT * FROM products WHERE details @> '{"isbn": "978-1234567890"}';
-- #ENDPRODUCTS

-- #ORDERS
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    ordered_at TIMESTAMP NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'waiting'
)

CREATE TABLE order_details (
    id BIGSERIAL PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER
);

CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE INDEX idx_order_details_product_id ON order_details (product_id);
CREATE INDEX idx_order_details_order_id ON order_details (order_id);

INSERT INTO orders (user_id, ordered_at, status) VALUES ((SELECT id FROM users WHERE email = 'john.doe@example.com'), CURRENT_TIMESTAMP, 'done');

INSERT INTO order_details (order_id, product_id, quantity) VALUES
('c7492896-bdb1-4686-847e-d9c3628c299a', (SELECT id FROM products WHERE name = 'Laptop X1'), 2);

SELECT * FROM orders;

SELECT * FROM order_details;

TRUNCATE TABLE orders;

DELETE FROM orders;

TRUNCATE TABLE order_details;

DROP TABLE orders;

DROP TABLE order_details;

-- REMOVE CONSTRAINTS
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'order_details';

ALTER TABLE order_details
DROP CONSTRAINT order_details_order_id_fkey;
-- #ENDORDERS

-- #JOIN
SELECT orders.id as order_id, users.id as user_id, users.name, orders.status FROM orders
LEFT JOIN users ON orders.user_id = users.id;
-- #ENDJOIN