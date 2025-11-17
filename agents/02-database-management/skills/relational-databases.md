# Relational Databases

## Overview

Relational databases organize data into tables (relations) with rows and columns, using SQL (Structured Query Language) for querying and maintaining ACID properties to ensure data integrity and consistency. They are the backbone of most transactional systems and remain the most widely used database type for backend applications.

## Table of Contents
1. [PostgreSQL](#postgresql)
2. [MySQL](#mysql)
3. [MariaDB](#mariadb)
4. [Microsoft SQL Server (T-SQL)](#microsoft-sql-server-t-sql)
5. [SQL Fundamentals](#sql-fundamentals)
6. [ACID Properties](#acid-properties)
7. [Transactions & Concurrency](#transactions--concurrency)
8. [Normalization](#normalization)
9. [Constraints](#constraints)
10. [Best Practices](#best-practices)

---

## PostgreSQL

### Overview
PostgreSQL is an advanced, open-source relational database known for its strong standards compliance, extensibility, and powerful features. It's often called "Postgres" and is favored for complex applications requiring robust data integrity.

**Current Version**: PostgreSQL 16
**License**: PostgreSQL License (permissive)
**Support**: 5 years per major version

### Key Features

#### 1. ACID Compliance
PostgreSQL provides full ACID (Atomicity, Consistency, Isolation, Durability) compliance with strong transaction support.

#### 2. Advanced Data Types
```sql
-- JSON and JSONB (binary JSON for faster operations)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    attributes JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, attributes) VALUES
('Laptop', '{"brand": "Dell", "ram": 16, "storage": "512GB"}');

-- Query JSONB efficiently
SELECT * FROM products
WHERE attributes->>'brand' = 'Dell';

-- Arrays
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT,
    tags TEXT[],
    ratings INTEGER[]
);

INSERT INTO articles (title, tags, ratings) VALUES
('PostgreSQL Guide', ARRAY['database', 'sql', 'postgres'], ARRAY[5, 4, 5]);

SELECT * FROM articles WHERE 'database' = ANY(tags);

-- Range types
CREATE TABLE room_reservations (
    room_id INTEGER,
    occupancy TSRANGE,
    EXCLUDE USING GIST (room_id WITH =, occupancy WITH &&)
);

-- UUID type
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100)
);

-- Geographic data with PostGIS extension
CREATE EXTENSION postgis;

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    coordinates GEOGRAPHY(POINT)
);

INSERT INTO locations (name, coordinates) VALUES
('Central Park', ST_MakePoint(-73.968285, 40.785091));
```

#### 3. Multi-Version Concurrency Control (MVCC)
PostgreSQL uses MVCC to handle concurrent transactions without locking reads.

```sql
-- Transaction Isolation Levels
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Your queries here
COMMIT;

-- Available isolation levels:
-- READ UNCOMMITTED (treated as READ COMMITTED in PostgreSQL)
-- READ COMMITTED (default)
-- REPEATABLE READ
-- SERIALIZABLE
```

#### 4. Full-Text Search
```sql
-- Create full-text search column
ALTER TABLE articles
ADD COLUMN search_vector tsvector;

-- Update search vector
UPDATE articles
SET search_vector = to_tsvector('english', title || ' ' || content);

-- Create GIN index for fast searching
CREATE INDEX articles_search_idx ON articles USING GIN(search_vector);

-- Perform full-text search
SELECT title, ts_rank(search_vector, query) AS rank
FROM articles, to_tsquery('english', 'postgresql & database') query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Alternative: Use generated column (PostgreSQL 12+)
ALTER TABLE articles
ADD COLUMN search_vector tsvector
GENERATED ALWAYS AS (to_tsvector('english', title || ' ' || content)) STORED;
```

#### 5. Common Table Expressions (CTEs) and Recursive Queries
```sql
-- Recursive CTE for hierarchical data
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level managers
    SELECT id, name, manager_id, 1 AS level, name::TEXT AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: employees reporting to managers
    SELECT e.id, e.name, e.manager_id, eh.level + 1,
           eh.path || ' -> ' || e.name
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT * FROM employee_hierarchy
ORDER BY level, name;

-- Materialized CTE for performance
WITH regional_sales AS MATERIALIZED (
    SELECT region, SUM(amount) AS total_sales
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY region
)
SELECT region, total_sales
FROM regional_sales
WHERE total_sales > (SELECT AVG(total_sales) FROM regional_sales);
```

#### 6. Window Functions
```sql
-- Ranking and analytical functions
SELECT
    employee_name,
    department,
    salary,
    -- Rank within department
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank,
    -- Running total
    SUM(salary) OVER (PARTITION BY department ORDER BY salary) as running_total,
    -- Moving average
    AVG(salary) OVER (PARTITION BY department
                      ORDER BY salary
                      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg,
    -- Percentile
    PERCENT_RANK() OVER (ORDER BY salary) as percentile
FROM employees;

-- LAG and LEAD for time-series analysis
SELECT
    date,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY date) as previous_day,
    revenue - LAG(revenue, 1) OVER (ORDER BY date) as daily_change,
    LEAD(revenue, 1) OVER (ORDER BY date) as next_day
FROM daily_revenues
ORDER BY date;
```

### Advanced Features

#### 1. Partitioning
```sql
-- Range partitioning by date
CREATE TABLE orders (
    order_id BIGSERIAL,
    order_date DATE NOT NULL,
    customer_id INTEGER,
    total_amount DECIMAL(10,2),
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

-- Create partitions
CREATE TABLE orders_2024_q1 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2 PARTITION OF orders
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Hash partitioning for even distribution
CREATE TABLE user_data (
    user_id BIGSERIAL,
    username VARCHAR(50),
    data JSONB,
    PRIMARY KEY (user_id)
) PARTITION BY HASH (user_id);

CREATE TABLE user_data_0 PARTITION OF user_data
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE user_data_1 PARTITION OF user_data
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);

-- List partitioning
CREATE TABLE sales (
    sale_id BIGSERIAL,
    region VARCHAR(50),
    amount DECIMAL(10,2),
    sale_date DATE
) PARTITION BY LIST (region);

CREATE TABLE sales_north PARTITION OF sales
    FOR VALUES IN ('North', 'Northeast', 'Northwest');
```

#### 2. Replication

**Streaming Replication (Physical)**
```sql
-- On primary server (postgresql.conf)
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB

-- Create replication role
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'secure_password';

-- pg_hba.conf
host replication replicator replica_ip/32 md5

-- On replica server
-- Create recovery configuration
standby_mode = 'on'
primary_conninfo = 'host=primary_ip port=5432 user=replicator password=secure_password'
```

**Logical Replication**
```sql
-- On publisher
CREATE PUBLICATION my_publication FOR TABLE users, orders;

-- Or for all tables
CREATE PUBLICATION all_tables FOR ALL TABLES;

-- On subscriber
CREATE SUBSCRIPTION my_subscription
    CONNECTION 'host=publisher_ip port=5432 dbname=mydb user=replicator password=pass'
    PUBLICATION my_publication;

-- Monitor replication
SELECT * FROM pg_stat_replication;
SELECT * FROM pg_stat_subscription;
```

#### 3. Extensions
```sql
-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
SELECT uuid_generate_v4();

-- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
SELECT crypt('password', gen_salt('bf'));

-- Geographic data
CREATE EXTENSION IF NOT EXISTS postgis;

-- Statistics for query optimization
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Time-series data
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- List installed extensions
\dx
```

### Performance Tuning

#### Configuration Parameters
```ini
# postgresql.conf

# Memory Settings
shared_buffers = 4GB              # 25% of RAM
effective_cache_size = 12GB       # 50-75% of RAM
work_mem = 64MB                   # Per operation
maintenance_work_mem = 1GB        # For VACUUM, CREATE INDEX

# Checkpoint Settings
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9
max_wal_size = 4GB
min_wal_size = 1GB

# Connection Settings
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'

# Query Planner
random_page_cost = 1.1            # Lower for SSD
effective_io_concurrency = 200    # Higher for SSD

# Logging
log_min_duration_statement = 1000  # Log queries > 1s
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
```

#### Maintenance Operations
```sql
-- VACUUM: Reclaim storage and update statistics
VACUUM VERBOSE ANALYZE users;

-- VACUUM FULL: Reclaim space more aggressively (locks table)
VACUUM FULL users;

-- REINDEX: Rebuild indexes
REINDEX TABLE users;
REINDEX INDEX users_email_idx;

-- ANALYZE: Update statistics for query planner
ANALYZE users;

-- Auto-vacuum configuration (per table)
ALTER TABLE large_table SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02
);

-- Monitor table bloat
SELECT
    schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_dead_tup
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;
```

### Best Practices

1. **Use connection pooling**: PgBouncer or pgpool-II
2. **Regular maintenance**: Schedule VACUUM and ANALYZE
3. **Monitor performance**: pg_stat_statements, pg_stat_activity
4. **Use schemas**: Logical separation of tables
5. **Prepared statements**: Prevent SQL injection
6. **Appropriate data types**: Use INTEGER instead of TEXT for numbers
7. **Leverage JSONB**: For semi-structured data
8. **Index foreign keys**: Always index foreign key columns

---

## MySQL

### Overview
MySQL is the world's most popular open-source relational database, known for speed, reliability, and ease of use. It's widely used in web applications and is part of the LAMP/LEMP stack.

**Current Version**: MySQL 8.0+
**License**: GPL (Community) / Commercial
**Owner**: Oracle Corporation

### Key Features

#### 1. Storage Engines

**InnoDB (Default and Recommended)**
```sql
-- Create table with InnoDB
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- InnoDB features:
-- - ACID compliant
-- - Row-level locking
-- - Foreign key constraints
-- - Crash recovery
-- - MVCC (Multi-Version Concurrency Control)

-- Check storage engine
SHOW TABLE STATUS WHERE Name = 'users';

-- Convert table to InnoDB
ALTER TABLE old_table ENGINE=InnoDB;
```

**MyISAM (Legacy)**
```sql
-- MyISAM: Fast reads, table-level locking, no transactions
CREATE TABLE logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP
) ENGINE=MyISAM;

-- Use cases for MyISAM:
-- - Read-heavy workloads with no updates
-- - Full-text search (before MySQL 5.6)
-- - Tables that are frequently backed up
```

#### 2. Replication

**Binary Log-Based Replication**
```sql
-- Master configuration (my.cnf)
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-format=ROW  # or MIXED, STATEMENT

-- Create replication user
CREATE USER 'replicator'@'%' IDENTIFIED BY 'secure_password';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';

-- Get master status
SHOW MASTER STATUS;

-- Slave configuration
[mysqld]
server-id=2
relay-log=relay-bin
read-only=1

-- Configure slave
CHANGE MASTER TO
    MASTER_HOST='master_ip',
    MASTER_USER='replicator',
    MASTER_PASSWORD='secure_password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=154;

START SLAVE;

-- Check slave status
SHOW SLAVE STATUS\G
```

**GTID-Based Replication (Recommended)**
```sql
-- Master configuration
[mysqld]
gtid-mode=ON
enforce-gtid-consistency=ON
log-bin=mysql-bin
server-id=1

-- Slave configuration
[mysqld]
gtid-mode=ON
enforce-gtid-consistency=ON
server-id=2
read-only=1

-- Configure slave with GTID
CHANGE MASTER TO
    MASTER_HOST='master_ip',
    MASTER_USER='replicator',
    MASTER_PASSWORD='secure_password',
    MASTER_AUTO_POSITION=1;

START SLAVE;
```

**Group Replication (Multi-Master)**
```sql
-- Enable group replication
[mysqld]
plugin-load-add=group_replication.so
group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
group_replication_start_on_boot=off
group_replication_local_address="node1:33061"
group_replication_group_seeds="node1:33061,node2:33061,node3:33061"
group_replication_bootstrap_group=off

-- Bootstrap the group on first node
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group=OFF;

-- Join group on other nodes
START GROUP_REPLICATION;

-- Monitor group replication
SELECT * FROM performance_schema.replication_group_members;
```

#### 3. JSON Support
```sql
-- JSON data type (MySQL 5.7.8+)
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    specifications JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert JSON data
INSERT INTO products (name, specifications) VALUES
('Laptop', JSON_OBJECT('brand', 'HP', 'ram', 16, 'ssd', 512));

-- Query JSON
SELECT name, specifications->>'$.brand' AS brand
FROM products
WHERE specifications->>'$.ram' >= 16;

-- JSON array operations
INSERT INTO products (name, specifications) VALUES
('Phone', '{"features": ["5G", "Wireless Charging", "Face ID"]}');

SELECT name
FROM products
WHERE JSON_CONTAINS(specifications->'$.features', '"5G"');

-- JSON functions
SELECT
    JSON_EXTRACT(specifications, '$.brand') AS brand,
    JSON_UNQUOTE(JSON_EXTRACT(specifications, '$.ram')) AS ram,
    JSON_LENGTH(specifications) AS num_keys
FROM products;
```

#### 4. Partitioning
```sql
-- Range partitioning
CREATE TABLE sales (
    id INT AUTO_INCREMENT,
    sale_date DATE,
    amount DECIMAL(10,2),
    PRIMARY KEY (id, sale_date)
)
PARTITION BY RANGE (YEAR(sale_date)) (
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Hash partitioning
CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT,
    user_id INT,
    session_data TEXT,
    PRIMARY KEY (id, user_id)
)
PARTITION BY HASH(user_id)
PARTITIONS 8;

-- List partitioning
CREATE TABLE regional_data (
    id INT AUTO_INCREMENT,
    region VARCHAR(50),
    data TEXT,
    PRIMARY KEY (id, region)
)
PARTITION BY LIST COLUMNS(region) (
    PARTITION p_north VALUES IN ('North', 'Northeast'),
    PARTITION p_south VALUES IN ('South', 'Southeast'),
    PARTITION p_west VALUES IN ('West', 'Southwest')
);

-- Manage partitions
ALTER TABLE sales ADD PARTITION (
    PARTITION p2025 VALUES LESS THAN (2026)
);

ALTER TABLE sales DROP PARTITION p2022;

-- View partition information
SELECT
    TABLE_NAME,
    PARTITION_NAME,
    PARTITION_METHOD,
    TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'sales';
```

### Performance Optimization

#### Configuration Parameters
```ini
# my.cnf

[mysqld]
# Memory Settings
innodb_buffer_pool_size = 4G      # 50-70% of RAM
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Connection Settings
max_connections = 151
max_allowed_packet = 64M

# Query Cache (deprecated in 8.0+)
# query_cache_type = 1
# query_cache_size = 64M

# Temp Tables
tmp_table_size = 64M
max_heap_table_size = 64M

# InnoDB Settings
innodb_file_per_table = 1
innodb_flush_neighbors = 0        # For SSD
innodb_read_io_threads = 4
innodb_write_io_threads = 4

# Binary Logging
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M

# Slow Query Log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2
log_queries_not_using_indexes = 1
```

#### Optimization Techniques
```sql
-- Analyze table
ANALYZE TABLE users;

-- Optimize table (defragment and update statistics)
OPTIMIZE TABLE users;

-- Check table for errors
CHECK TABLE users;

-- Repair table (MyISAM only)
REPAIR TABLE logs;

-- Show table statistics
SHOW TABLE STATUS LIKE 'users';

-- Show index statistics
SHOW INDEX FROM users;

-- Monitor queries
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- Kill slow query
KILL QUERY 123;

-- InnoDB status
SHOW ENGINE INNODB STATUS;
```

### Best Practices

1. **Always use InnoDB**: For transactional data
2. **Enable binary logging**: For replication and PITR
3. **Use connection pooling**: Reduce connection overhead
4. **Regular optimization**: Run OPTIMIZE TABLE periodically
5. **Monitor slow queries**: Enable slow query log
6. **Prepared statements**: Prevent SQL injection
7. **Appropriate buffer pool**: Set innodb_buffer_pool_size to 50-70% RAM
8. **Backup strategy**: Regular mysqldump or Percona XtraBackup

---

## MariaDB

### Overview
MariaDB is a fork of MySQL created by MySQL's original developers. It's designed to be a drop-in replacement with enhanced features, better performance, and a more open development model.

**Current Version**: MariaDB 11.x
**License**: GPL v2
**Compatibility**: Binary compatible with MySQL

### Key Features Beyond MySQL

#### 1. Additional Storage Engines

**Aria (Crash-Safe MyISAM)**
```sql
-- Aria: Transactional MyISAM alternative
CREATE TABLE cache_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data TEXT,
    created_at TIMESTAMP
) ENGINE=Aria TRANSACTIONAL=1;
```

**ColumnStore (Analytical Workloads)**
```sql
-- ColumnStore: Columnar storage for analytics
CREATE TABLE analytics_data (
    date DATE,
    user_id INT,
    page_views INT,
    revenue DECIMAL(10,2)
) ENGINE=ColumnStore;

-- Optimized for analytical queries
SELECT
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(page_views) AS total_views,
    SUM(revenue) AS total_revenue
FROM analytics_data
WHERE date >= '2024-01-01'
GROUP BY month;
```

**Spider (Sharding)**
```sql
-- Spider: Distributed storage engine for sharding
CREATE SERVER backend1
    FOREIGN DATA WRAPPER mysql
    OPTIONS (
        HOST '10.0.0.1',
        DATABASE 'sharddb',
        USER 'spider',
        PASSWORD 'pass',
        PORT 3306
    );

CREATE TABLE distributed_users (
    id INT AUTO_INCREMENT,
    username VARCHAR(50),
    email VARCHAR(100),
    PRIMARY KEY (id)
) ENGINE=Spider
COMMENT='wrapper "mysql", srv "backend1 backend2",table "users"'
PARTITION BY HASH(id) (
    PARTITION pt1 COMMENT = 'srv "backend1"',
    PARTITION pt2 COMMENT = 'srv "backend2"'
);
```

#### 2. Galera Cluster (Synchronous Multi-Master)
```sql
-- Galera configuration (my.cnf)
[galera]
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://node1,node2,node3"
wsrep_cluster_name="production_cluster"
wsrep_node_address="192.168.1.1"
wsrep_node_name="node1"
wsrep_sst_method=rsync
binlog_format=ROW
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2

-- Bootstrap first node
galera_new_cluster

-- Check cluster status
SHOW STATUS LIKE 'wsrep%';

-- Cluster size
SHOW STATUS LIKE 'wsrep_cluster_size';

-- Check if node is synced
SHOW STATUS LIKE 'wsrep_local_state_comment';
```

#### 3. Temporal Tables (System-Versioned)
```sql
-- Create system-versioned table
CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    salary DECIMAL(10,2),
    department VARCHAR(50)
) WITH SYSTEM VERSIONING;

-- Updates create history
UPDATE employees SET salary = 75000 WHERE id = 1;

-- Query current data
SELECT * FROM employees;

-- Query historical data
SELECT * FROM employees FOR SYSTEM_TIME AS OF '2024-01-01 00:00:00';

-- Query all versions
SELECT * FROM employees FOR SYSTEM_TIME ALL WHERE id = 1;

-- Query between dates
SELECT * FROM employees
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE department = 'Engineering';

-- View history table
SHOW CREATE TABLE employees;
```

#### 4. Virtual (Computed) Columns
```sql
-- Persistent computed columns
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2),
    tax_rate DECIMAL(5,2),
    price_with_tax DECIMAL(10,2) AS (price * (1 + tax_rate)) PERSISTENT,
    INDEX (price_with_tax)
);

-- Virtual columns (computed on read)
ALTER TABLE users
ADD COLUMN full_name VARCHAR(150) AS (CONCAT(first_name, ' ', last_name)) VIRTUAL;

-- Can create indexes on persistent columns
CREATE INDEX idx_total_price ON products(price_with_tax);
```

#### 5. Enhanced JSON Support
```sql
-- JSON_TABLE: Convert JSON to table
SELECT jt.*
FROM products,
JSON_TABLE(specifications, '$' COLUMNS(
    brand VARCHAR(50) PATH '$.brand',
    ram INT PATH '$.ram',
    storage INT PATH '$.storage'
)) AS jt;

-- JSON aggregation
SELECT
    category,
    JSON_ARRAYAGG(JSON_OBJECT('name', name, 'price', price)) AS products
FROM products
GROUP BY category;
```

### MariaDB-Specific Optimizations

```sql
-- Thread pool (better connection handling)
[mysqld]
thread_handling=pool-of-threads
thread_pool_size=16

-- Segmented key cache
[mysqld]
key_cache_segments=8

-- Optimizer enhancements
[mysqld]
optimizer_switch='extended_keys=on,exists_to_in=on,orderby_uses_equalities=on'

-- Progress reporting for long operations
ALTER TABLE large_table ENGINE=InnoDB;
-- Shows progress in SHOW PROCESSLIST
```

### Best Practices

1. **Leverage Galera**: For multi-master high availability
2. **Use ColumnStore**: For analytical workloads
3. **Temporal tables**: For audit trails and history
4. **Virtual columns**: For computed values with indexes
5. **Thread pool**: Better than one-thread-per-connection
6. **Monitor with Performance Schema**: Enhanced metrics
7. **Regular upgrades**: MariaDB releases more frequently than MySQL

---

## Microsoft SQL Server (T-SQL)

### Overview
Microsoft SQL Server is an enterprise-grade relational database with T-SQL (Transact-SQL) as its query language. It offers powerful features, tight Windows integration, and comprehensive business intelligence tools.

**Current Version**: SQL Server 2022
**Editions**: Express (free), Standard, Enterprise
**License**: Commercial

### Key Features

#### 1. T-SQL Capabilities

**Variables and Control Flow**
```sql
-- Declare variables
DECLARE @userId INT = 1;
DECLARE @userName NVARCHAR(50);
DECLARE @orderCount INT;

-- Set values
SET @userName = 'John Doe';
SELECT @orderCount = COUNT(*) FROM orders WHERE user_id = @userId;

-- IF-ELSE
IF @orderCount > 10
BEGIN
    PRINT 'Loyal customer';
    UPDATE users SET loyalty_tier = 'Gold' WHERE id = @userId;
END
ELSE
BEGIN
    PRINT 'Regular customer';
END

-- WHILE loop
DECLARE @counter INT = 1;
WHILE @counter <= 10
BEGIN
    PRINT 'Iteration: ' + CAST(@counter AS VARCHAR);
    SET @counter = @counter + 1;
END

-- TRY-CATCH error handling
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO orders (user_id, total) VALUES (@userId, 100.00);
    UPDATE users SET order_count = order_count + 1 WHERE id = @userId;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH
```

**Stored Procedures**
```sql
-- Create stored procedure
CREATE PROCEDURE sp_GetUserOrders
    @userId INT,
    @startDate DATE = NULL,
    @endDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.id,
        o.order_date,
        o.total,
        o.status
    FROM orders o
    WHERE o.user_id = @userId
        AND (@startDate IS NULL OR o.order_date >= @startDate)
        AND (@endDate IS NULL OR o.order_date <= @endDate)
    ORDER BY o.order_date DESC;
END
GO

-- Execute stored procedure
EXEC sp_GetUserOrders @userId = 1, @startDate = '2024-01-01';

-- Stored procedure with output parameter
CREATE PROCEDURE sp_CreateOrder
    @userId INT,
    @total DECIMAL(10,2),
    @orderId INT OUTPUT
AS
BEGIN
    INSERT INTO orders (user_id, total, order_date)
    VALUES (@userId, @total, GETDATE());

    SET @orderId = SCOPE_IDENTITY();
END
GO

-- Use output parameter
DECLARE @newOrderId INT;
EXEC sp_CreateOrder @userId = 1, @total = 99.99, @orderId = @newOrderId OUTPUT;
PRINT 'New order ID: ' + CAST(@newOrderId AS VARCHAR);
```

**User-Defined Functions**
```sql
-- Scalar function
CREATE FUNCTION fn_CalculateTax
(
    @amount DECIMAL(10,2),
    @taxRate DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @amount * @taxRate;
END
GO

-- Use function
SELECT
    product_name,
    price,
    dbo.fn_CalculateTax(price, 0.08) AS tax,
    price + dbo.fn_CalculateTax(price, 0.08) AS total
FROM products;

-- Table-valued function
CREATE FUNCTION fn_GetTopCustomers
(
    @minOrders INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        u.id,
        u.name,
        COUNT(o.id) AS order_count,
        SUM(o.total) AS total_spent
    FROM users u
    INNER JOIN orders o ON u.id = o.user_id
    GROUP BY u.id, u.name
    HAVING COUNT(o.id) >= @minOrders
);
GO

-- Use table-valued function
SELECT * FROM dbo.fn_GetTopCustomers(5);
```

**Triggers**
```sql
-- AFTER trigger for audit logging
CREATE TRIGGER trg_audit_orders
ON orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Log inserts
    INSERT INTO order_audit (order_id, action, timestamp, user_name)
    SELECT id, 'INSERT', GETDATE(), SYSTEM_USER
    FROM inserted;

    -- Log updates
    INSERT INTO order_audit (order_id, action, timestamp, user_name)
    SELECT id, 'UPDATE', GETDATE(), SYSTEM_USER
    FROM inserted
    WHERE EXISTS (SELECT 1 FROM deleted WHERE id = inserted.id);

    -- Log deletes
    INSERT INTO order_audit (order_id, action, timestamp, user_name)
    SELECT id, 'DELETE', GETDATE(), SYSTEM_USER
    FROM deleted
    WHERE NOT EXISTS (SELECT 1 FROM inserted WHERE id = deleted.id);
END
GO

-- INSTEAD OF trigger
CREATE TRIGGER trg_soft_delete_users
ON users
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE users
    SET is_deleted = 1, deleted_at = GETDATE()
    WHERE id IN (SELECT id FROM deleted);
END
GO
```

#### 2. Advanced Features

**Columnstore Indexes**
```sql
-- Clustered columnstore index (analytical workloads)
CREATE CLUSTERED COLUMNSTORE INDEX cci_sales
ON sales_fact;

-- Nonclustered columnstore index
CREATE NONCLUSTERED COLUMNSTORE INDEX ncci_orders
ON orders (order_date, product_id, quantity, total);

-- Query with columnstore
SELECT
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(total) AS revenue
FROM orders
WHERE order_date >= '2023-01-01'
GROUP BY YEAR(order_date), MONTH(order_date);
```

**Always On Availability Groups**
```sql
-- Create availability group
CREATE AVAILABILITY GROUP [AG1]
WITH (
    AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
    FAILURE_CONDITION_LEVEL = 3,
    HEALTH_CHECK_TIMEOUT = 30000
)
FOR DATABASE [ProductionDB]
REPLICA ON
    'ServerA' WITH (
        ENDPOINT_URL = 'TCP://ServerA.domain.com:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC
    ),
    'ServerB' WITH (
        ENDPOINT_URL = 'TCP://ServerB.domain.com:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC
    ),
    'ServerC' WITH (
        ENDPOINT_URL = 'TCP://ServerC.domain.com:5022',
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
        FAILOVER_MODE = MANUAL
    );

-- Monitor availability groups
SELECT
    ag.name AS ag_name,
    ar.replica_server_name,
    ar.availability_mode_desc,
    ar.failover_mode_desc,
    ars.role_desc,
    ars.connected_state_desc,
    ars.synchronization_health_desc
FROM sys.availability_groups ag
INNER JOIN sys.availability_replicas ar ON ag.group_id = ar.group_id
INNER JOIN sys.dm_hadr_availability_replica_states ars ON ar.replica_id = ars.replica_id;
```

**Temporal Tables**
```sql
-- Create temporal table
CREATE TABLE dbo.Employees
(
    EmployeeId INT PRIMARY KEY,
    Name NVARCHAR(100),
    Position NVARCHAR(100),
    Department NVARCHAR(50),
    Salary DECIMAL(10,2),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.EmployeeHistory));

-- Query as of specific time
SELECT * FROM Employees
FOR SYSTEM_TIME AS OF '2024-01-01';

-- Query all versions
SELECT * FROM Employees
FOR SYSTEM_TIME ALL
WHERE EmployeeId = 1;

-- Query between dates
SELECT * FROM Employees
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE Department = 'Engineering';
```

**Row-Level Security**
```sql
-- Create security policy
CREATE SCHEMA Security;
GO

CREATE FUNCTION Security.fn_securitypredicate(@UserId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_securitypredicate_result
WHERE @UserId = CAST(SESSION_CONTEXT(N'UserId') AS INT);
GO

CREATE SECURITY POLICY Security.UserAccessPolicy
ADD FILTER PREDICATE Security.fn_securitypredicate(UserId)
ON dbo.Orders,
ADD BLOCK PREDICATE Security.fn_securitypredicate(UserId)
ON dbo.Orders AFTER INSERT
WITH (STATE = ON);
GO

-- Set session context
EXEC sp_set_session_context @key = N'UserId', @value = 123;

-- Now queries automatically filter by UserId
SELECT * FROM Orders; -- Only returns orders for UserId 123
```

**Dynamic Data Masking**
```sql
-- Add data masking
ALTER TABLE users
ALTER COLUMN email ADD MASKED WITH (FUNCTION = 'email()');

ALTER TABLE users
ALTER COLUMN phone ADD MASKED WITH (FUNCTION = 'partial(1,"XXX-XXX-",4)');

ALTER TABLE users
ALTER COLUMN ssn ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE users
ALTER COLUMN salary ADD MASKED WITH (FUNCTION = 'random(1000, 100000)');

-- Grant unmask permission
GRANT UNMASK TO ManagerRole;

-- Regular users see masked data
SELECT * FROM users; -- Shows j***@example.com

-- Users with UNMASK permission see real data
```

### Performance Tuning

**Query Store**
```sql
-- Enable Query Store
ALTER DATABASE ProductionDB
SET QUERY_STORE = ON (
    OPERATION_MODE = READ_WRITE,
    MAX_STORAGE_SIZE_MB = 1024,
    INTERVAL_LENGTH_MINUTES = 60,
    QUERY_CAPTURE_MODE = AUTO
);

-- Query top queries by execution time
SELECT TOP 10
    qt.query_sql_text,
    q.query_id,
    rs.count_executions,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.last_execution_time
FROM sys.query_store_query q
INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
INNER JOIN sys.query_store_plan p ON q.query_id = p.query_id
INNER JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.avg_duration DESC;

-- Force query plan
EXEC sp_query_store_force_plan @query_id = 123, @plan_id = 456;
```

**Index Optimization**
```sql
-- Missing index suggestions
SELECT
    dm_mid.database_id AS DatabaseID,
    dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) AS Impact,
    dm_mid.statement AS TableName,
    dm_mid.equality_columns AS EqualityColumns,
    dm_mid.inequality_columns AS InequalityColumns,
    dm_mid.included_columns AS IncludeColumns
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs ON dm_mig.index_group_handle = dm_migs.group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid ON dm_mig.index_handle = dm_mid.index_handle
ORDER BY Impact DESC;

-- Index usage statistics
SELECT
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    s.last_user_seek,
    s.last_user_scan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
ORDER BY s.user_updates DESC;

-- Rebuild fragmented indexes
ALTER INDEX ALL ON dbo.Orders REBUILD WITH (ONLINE = ON);

-- Update statistics
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
```

### Best Practices

1. **Use Query Store**: Monitor query performance
2. **Implement Always On**: For high availability
3. **Leverage columnstore**: For analytical queries
4. **Row-level security**: Fine-grained access control
5. **Temporal tables**: Built-in history tracking
6. **Regular index maintenance**: Rebuild/reorganize
7. **Enable compression**: Reduce storage and I/O
8. **Monitor DMVs**: Dynamic management views

---

## SQL Fundamentals

### Data Definition Language (DDL)

```sql
-- CREATE TABLE
CREATE TABLE users (
    id SERIAL PRIMARY KEY,  -- PostgreSQL auto-increment
    -- id INT AUTO_INCREMENT PRIMARY KEY,  -- MySQL
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ALTER TABLE
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
ALTER TABLE users DROP COLUMN phone;
ALTER TABLE users MODIFY COLUMN email VARCHAR(150);  -- MySQL
ALTER TABLE users ALTER COLUMN email TYPE VARCHAR(150);  -- PostgreSQL
ALTER TABLE users RENAME COLUMN email TO email_address;

-- CREATE INDEX
CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_name ON users(last_name, first_name);

-- DROP
DROP TABLE IF EXISTS users CASCADE;
DROP INDEX IF EXISTS idx_users_email;

-- TRUNCATE (fast delete all rows)
TRUNCATE TABLE users;
```

### Data Manipulation Language (DML)

```sql
-- INSERT
INSERT INTO users (username, email, password_hash)
VALUES ('john_doe', 'john@example.com', 'hashed_password');

-- Multiple rows
INSERT INTO users (username, email, password_hash) VALUES
('user1', 'user1@example.com', 'hash1'),
('user2', 'user2@example.com', 'hash2'),
('user3', 'user3@example.com', 'hash3');

-- INSERT from SELECT
INSERT INTO archived_users (id, username, email)
SELECT id, username, email FROM users WHERE is_active = FALSE;

-- UPDATE
UPDATE users
SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP
WHERE last_login < CURRENT_DATE - INTERVAL '1 year';

-- DELETE
DELETE FROM users WHERE is_active = FALSE AND created_at < '2020-01-01';

-- SELECT
SELECT id, username, email FROM users WHERE is_active = TRUE;

-- UPSERT (INSERT ... ON CONFLICT) - PostgreSQL
INSERT INTO users (id, username, email, password_hash)
VALUES (1, 'john_doe', 'john@example.com', 'hash')
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = CURRENT_TIMESTAMP;

-- REPLACE (MySQL)
REPLACE INTO users (id, username, email, password_hash)
VALUES (1, 'john_doe', 'john@example.com', 'hash');

-- MERGE (SQL Server)
MERGE INTO target_users AS target
USING source_users AS source
ON target.id = source.id
WHEN MATCHED THEN
    UPDATE SET target.email = source.email
WHEN NOT MATCHED THEN
    INSERT (id, username, email) VALUES (source.id, source.username, source.email)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;
```

### Joins

```sql
-- INNER JOIN
SELECT
    u.id,
    u.username,
    o.order_id,
    o.total
FROM users u
INNER JOIN orders o ON u.id = o.user_id;

-- LEFT JOIN (all users, with or without orders)
SELECT
    u.id,
    u.username,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username;

-- RIGHT JOIN
SELECT
    u.username,
    o.order_id,
    o.total
FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;

-- FULL OUTER JOIN (PostgreSQL, SQL Server)
SELECT
    u.username,
    o.order_id
FROM users u
FULL OUTER JOIN orders o ON u.id = o.user_id;

-- CROSS JOIN (Cartesian product)
SELECT
    c.color,
    s.size
FROM colors c
CROSS JOIN sizes s;

-- SELF JOIN
SELECT
    e.name AS employee,
    m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- Multiple joins
SELECT
    u.username,
    o.order_id,
    p.product_name,
    oi.quantity,
    oi.price
FROM users u
INNER JOIN orders o ON u.id = o.user_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.id;
```

---

## ACID Properties

### Atomicity
**Definition**: All operations in a transaction complete successfully or none do.

```sql
-- Example: Bank transfer
BEGIN TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

-- If any error occurs, ROLLBACK undoes all changes
-- If successful, COMMIT makes changes permanent
COMMIT;
```

### Consistency
**Definition**: Database moves from one valid state to another, maintaining all constraints.

```sql
-- Constraints ensure consistency
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    total DECIMAL(10,2) CHECK (total > 0),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- This insert will fail if user_id doesn't exist
INSERT INTO orders (user_id, total) VALUES (999, 100.00);
```

### Isolation
**Definition**: Concurrent transactions don't interfere with each other.

```sql
-- Set isolation level
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Your queries here
SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;

COMMIT;
```

**Isolation Levels**:
1. **READ UNCOMMITTED**: Dirty reads possible
2. **READ COMMITTED**: Default in PostgreSQL, prevents dirty reads
3. **REPEATABLE READ**: Default in MySQL InnoDB, prevents dirty and non-repeatable reads
4. **SERIALIZABLE**: Strictest, prevents all phenomena

### Durability
**Definition**: Committed transactions survive system failures.

```sql
-- Once committed, data persists even after crash
BEGIN TRANSACTION;
INSERT INTO critical_data (data) VALUES ('important');
COMMIT;  -- Data is now durable

-- Implemented through:
-- - Write-Ahead Logging (WAL)
-- - Transaction logs
-- - Checkpoint processes
```

---

## Transactions & Concurrency

### Transaction Management

```sql
-- Explicit transaction
BEGIN TRANSACTION;

INSERT INTO orders (user_id, total) VALUES (1, 100.00);

DECLARE @order_id INT = LAST_INSERT_ID();  -- MySQL
-- DECLARE @order_id INT = SCOPE_IDENTITY();  -- SQL Server

INSERT INTO order_items (order_id, product_id, quantity)
VALUES (@order_id, 10, 2);

COMMIT;

-- Rollback on error
BEGIN TRANSACTION;

UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 10;

IF (SELECT quantity FROM inventory WHERE product_id = 10) < 0
BEGIN
    ROLLBACK;
    -- RAISE ERROR
END
ELSE
BEGIN
    COMMIT;
END
```

### Savepoints

```sql
BEGIN TRANSACTION;

INSERT INTO orders (user_id, total) VALUES (1, 100.00);
SAVEPOINT sp1;

INSERT INTO order_items (order_id, product_id) VALUES (1, 10);
SAVEPOINT sp2;

INSERT INTO order_items (order_id, product_id) VALUES (1, 11);

-- Oops, product 11 was wrong
ROLLBACK TO sp2;

-- Continue with transaction
INSERT INTO order_items (order_id, product_id) VALUES (1, 12);

COMMIT;
```

### Locking

```sql
-- Pessimistic locking (lock before reading)
BEGIN TRANSACTION;

SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;  -- Locks row

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;

COMMIT;

-- Optimistic locking (check version before update)
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY,
    balance DECIMAL(10,2),
    version INTEGER DEFAULT 0
);

-- Read with version
SELECT balance, version FROM accounts WHERE id = 1;

-- Update only if version matches
UPDATE accounts
SET balance = 900.00, version = version + 1
WHERE id = 1 AND version = 5;

-- Check if update succeeded
IF ROW_COUNT() = 0 THEN
    -- Version mismatch, retry or fail
END IF;
```

### Deadlock Handling

```sql
-- Deadlock scenario:
-- Transaction 1: UPDATE users WHERE id = 1; UPDATE orders WHERE id = 1;
-- Transaction 2: UPDATE orders WHERE id = 1; UPDATE users WHERE id = 1;

-- Prevention: Always acquire locks in same order
BEGIN TRANSACTION;

-- Lock in consistent order: users first, then orders
SELECT * FROM users WHERE id = 1 FOR UPDATE;
SELECT * FROM orders WHERE user_id = 1 FOR UPDATE;

-- Perform updates
UPDATE users SET last_order = CURRENT_TIMESTAMP WHERE id = 1;
UPDATE orders SET status = 'processed' WHERE user_id = 1;

COMMIT;

-- Detection and retry
DECLARE @retry_count INT = 0;
DECLARE @max_retries INT = 3;

WHILE @retry_count < @max_retries
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Your transaction logic here

        COMMIT;
        BREAK;  -- Success, exit loop
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 1205  -- Deadlock
        BEGIN
            ROLLBACK;
            SET @retry_count = @retry_count + 1;
            WAITFOR DELAY '00:00:01';  -- Wait before retry
        END
        ELSE
        BEGIN
            ROLLBACK;
            THROW;  -- Re-raise other errors
        END
    END CATCH
END
```

---

## Normalization

### Normal Forms

**1NF (First Normal Form)**
- Atomic values (no arrays or lists)
- Each column has unique name
- No repeating groups

```sql
-- Violates 1NF
CREATE TABLE users_bad (
    id INT,
    name VARCHAR(100),
    phones VARCHAR(255)  -- Multiple phones as CSV
);

-- Complies with 1NF
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE user_phones (
    id INT PRIMARY KEY,
    user_id INT,
    phone VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**2NF (Second Normal Form)**
- Must be in 1NF
- No partial dependencies (non-key attributes depend on entire primary key)

```sql
-- Violates 2NF (product_name depends only on product_id, not the full key)
CREATE TABLE order_items_bad (
    order_id INT,
    product_id INT,
    product_name VARCHAR(100),  -- Partial dependency
    quantity INT,
    PRIMARY KEY (order_id, product_id)
);

-- Complies with 2NF
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE products (
    id INT PRIMARY KEY,
    name VARCHAR(100)
);
```

**3NF (Third Normal Form)**
- Must be in 2NF
- No transitive dependencies (non-key attributes depend only on primary key)

```sql
-- Violates 3NF (city depends on zip_code, not on user_id)
CREATE TABLE users_bad (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    zip_code VARCHAR(10),
    city VARCHAR(100)  -- Transitive dependency
);

-- Complies with 3NF
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    zip_code VARCHAR(10),
    FOREIGN KEY (zip_code) REFERENCES zip_codes(code)
);

CREATE TABLE zip_codes (
    code VARCHAR(10) PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(2)
);
```

### Denormalization for Performance

```sql
-- Normalized (3NF) - requires JOIN
SELECT
    o.id,
    o.total,
    u.username,
    u.email
FROM orders o
INNER JOIN users u ON o.user_id = u.id;

-- Denormalized - faster reads, redundant data
CREATE TABLE orders_denormalized (
    id INT PRIMARY KEY,
    user_id INT,
    username VARCHAR(50),  -- Redundant
    user_email VARCHAR(100),  -- Redundant
    total DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Query without JOIN
SELECT id, total, username, user_email
FROM orders_denormalized;

-- Trade-off: Faster reads, slower writes, data consistency challenges
```

---

## Constraints

### Primary Key
```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL
);

-- Composite primary key
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_id, product_id)
);
```

### Foreign Key
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    total DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Options:
-- ON DELETE CASCADE: Delete child rows
-- ON DELETE SET NULL: Set to NULL
-- ON DELETE RESTRICT: Prevent deletion (default)
-- ON UPDATE CASCADE: Update child rows
```

### Unique Constraint
```sql
CREATE TABLE users (
    id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    username VARCHAR(50) UNIQUE
);

-- Composite unique constraint
ALTER TABLE user_settings
ADD CONSTRAINT uq_user_setting UNIQUE (user_id, setting_key);
```

### Check Constraint
```sql
CREATE TABLE products (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2) CHECK (price > 0),
    stock INT CHECK (stock >= 0),
    category VARCHAR(50) CHECK (category IN ('Electronics', 'Clothing', 'Food'))
);

-- Complex check constraint
ALTER TABLE orders
ADD CONSTRAINT chk_total CHECK (total >= 0 AND total <= 1000000);
```

### Not Null Constraint
```sql
CREATE TABLE users (
    id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20)  -- Nullable
);
```

### Default Constraint
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10,2) DEFAULT 0.00
);
```

---

## Best Practices

### 1. Schema Design
- ✅ Normalize to 3NF for OLTP systems
- ✅ Use appropriate data types (INT vs BIGINT, VARCHAR vs TEXT)
- ✅ Add NOT NULL where applicable
- ✅ Use foreign keys for referential integrity
- ✅ Create indexes on foreign keys
- ✅ Use UUID for distributed systems
- ✅ Document schema with comments

### 2. Query Writing
- ✅ Use prepared statements (prevent SQL injection)
- ✅ Select only needed columns (not SELECT *)
- ✅ Use JOINs instead of subqueries when possible
- ✅ Implement pagination (LIMIT/OFFSET)
- ✅ Avoid N+1 queries
- ✅ Use EXPLAIN to analyze queries
- ✅ Add indexes based on query patterns

### 3. Performance
- ✅ Create composite indexes for multi-column queries
- ✅ Use connection pooling
- ✅ Implement query result caching
- ✅ Partition large tables
- ✅ Monitor slow query logs
- ✅ Regular VACUUM/ANALYZE (PostgreSQL)
- ✅ Regular OPTIMIZE TABLE (MySQL)

### 4. Operations
- ✅ Automated backups (test restore)
- ✅ Configure replication
- ✅ Monitor key metrics
- ✅ Use transactions for multi-step operations
- ✅ Handle deadlocks with retry logic
- ✅ Zero-downtime migrations
- ✅ Version control schema changes

### 5. Security
- ✅ Use strong passwords
- ✅ Principle of least privilege
- ✅ Enable SSL/TLS
- ✅ Encrypt sensitive data
- ✅ Audit logs
- ✅ Regular security updates
- ✅ SQL injection prevention

---

## Additional Resources

### Official Documentation
- PostgreSQL: https://www.postgresql.org/docs/
- MySQL: https://dev.mysql.com/doc/
- MariaDB: https://mariadb.com/kb/
- SQL Server: https://docs.microsoft.com/sql/

### Learning Platforms
- PostgreSQL Tutorial: https://www.postgresqltutorial.com/
- MySQL Tutorial: https://www.mysqltutorial.org/
- SQLBolt: https://sqlbolt.com/
- Mode SQL Tutorial: https://mode.com/sql-tutorial/

### Books
- "PostgreSQL: Up and Running" by Regina Obe
- "High Performance MySQL" by Baron Schwartz
- "SQL Performance Explained" by Markus Winand

---

**Next**: [NoSQL Databases →](nosql-databases.md)
