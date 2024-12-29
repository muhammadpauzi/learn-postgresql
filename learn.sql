CREATE DATABASE learn_psql;

/*

"" double quotes is using for table name, column name, ...
'' single quote is using for values

like this: INSERT INTO "employees" ("name", "username") VALUES ('Karyawan #1', 'k1');

*/

-- USE learn_psql; -- there is not USE command
-- \c learn_psql; -- use this instead on psql cli

/*
instead of INT/BIGINT and auto increment, in postgresql we can use SERIAL/BIGSERIAL, where is automatically creates:
1. AUTO INCREMENT, 
2. INTEGER (4 BYTES),
3. NOT NULL

see `id2`
*/

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    username VARCHAR(64) NOT NULL UNIQUE
);

CREATE SEQUENCE employees_id_seq;
CREATE TABLE employees (
    id INTEGER PRIMARY KEY DEFAULT nextval('employees_id_seq') NOT NULL,
    name VARCHAR(64) NOT NULL,
    username VARCHAR(64) NOT NULL UNIQUE
);

-- SHOW TABLES;
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'; -- Or another schema name

-- DESCRIBE employees;
select column_name, data_type, character_maximum_length, column_default, is_nullable
from INFORMATION_SCHEMA.COLUMNS where table_name = 'employees';

INSERT INTO "employees" ("name", "username") VALUES ('Karyawan #1', 'k1');
INSERT INTO "employees" ("name", "username") VALUES ('Karyawan #2', 'k2');
SELECT * FROM employees;

INSERT INTO "users" ("name", "username") VALUES ('User #1', 'u1');
INSERT INTO "users" ("name", "username") VALUES ('User #2', 'u2');

SELECT * FROM "users";

/*
# JSON

*/

ALTER TABLE "users"
ADD COLUMN "details" JSONB;

INSERT INTO users (name, username, details)
VALUES ('User #3', 'u3', '{"country": "IDN", "age": 20, "hobbies": ["CODING", "SLEEP", "EAT"]}');
UPDATE users SET details = '{"country": "IDN", "age": 21, "hobbies": ["CODING"]}' WHERE id = 4;

SELECT * FROM "users";

-- -> (Get JSON object field): Returns a JSON object field.
SELECT details -> 'description' FROM "users";

-- ->> (Get JSON object field as text): Returns a JSON object field as text. This is often more convenient than ->
SELECT details ->> 'description' FROM "users";

-- where age === 21
SELECT * FROM "users" WHERE details @> '{"age": 21}';

-- where data have 'age' key
SELECT * FROM "users" WHERE details ? 'age';

/* 
JSON index

Index algo: GIN index (most common)

This creates a GIN index that is suitable for queries using the @>, ?, ?|, and ?& operators.
*/

CREATE INDEX idx_users_details ON users USING GIN (details jsonb_path_ops);

EXPLAIN SELECT * FROM "users" WHERE details ? 'age';


/*
# INDEX

Types of Indexes in PostgreSQL

PostgreSQL offers several index types, each suited for different use cases:

1. B-tree Indexes (Default):

The most common and general-purpose index type.
Efficient for equality and range searches (=, <, >, <=, >=, BETWEEN).
Suitable for most data types.
Ordered, so they are also efficient for ORDER BY clauses.

2. Hash Indexes:

Only suitable for equality comparisons (=).
Faster than B-tree indexes for equality lookups in some cases, but less versatile.
Not crash-safe before PostgreSQL 10, so they were rarely used. Now they are crash-safe, but still less versatile.

3. GIN Indexes (Generalized Inverted Index):

Designed for indexing composite values like arrays and full-text search.
Efficient for searching for elements within arrays or for words within documents.
Used with the jsonb_path_ops operator class for JSONB indexing.

4. GiST Indexes (Generalized Search Tree):

Highly versatile and extensible.
Used for indexing geometric data (PostGIS), full-text search, and other complex data types.
Supports various search strategies depending on the data type.

5. BRIN Indexes (Block Range Index):

Designed for very large tables where the data is naturally ordered on the indexed column.
Stores summary information about ranges of pages (blocks), making them much smaller than B-tree indexes.
Suitable for time series data or other append-only data.
*/

CREATE INDEX idx_users_name ON users (name);

EXPLAIN ANALYZE SELECT * FROM users WHERE name = 'User #1';


-- HASH (for where = equality)

CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY, -- Unique session identifier
    user_id INTEGER NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_user_sessions_session_id_hash ON user_sessions USING HASH (session_id);

SELECT * FROM user_sessions WHERE session_id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';