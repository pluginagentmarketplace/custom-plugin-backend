# Query Optimization

## Overview

Query optimization is the process of improving database query performance to reduce execution time, resource consumption, and cost. It involves analyzing query execution plans, creating appropriate indexes, rewriting queries, and tuning database configurations. Optimized queries can make the difference between a responsive application and one that times out.

## Table of Contents
1. [Understanding EXPLAIN](#understanding-explain)
2. [Indexing Strategies](#indexing-strategies)
3. [Query Optimization Techniques](#query-optimization-techniques)
4. [Common Anti-Patterns](#common-anti-patterns)
5. [N+1 Query Problem](#n1-query-problem)
6. [Caching Strategies](#caching-strategies)
7. [Database-Specific Optimizations](#database-specific-optimizations)
8. [Monitoring & Profiling](#monitoring--profiling)
9. [Best Practices](#best-practices)

---

## Understanding EXPLAIN

### PostgreSQL EXPLAIN

```sql
-- Basic EXPLAIN
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- EXPLAIN ANALYZE (actually executes query)
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'john@example.com';

-- Detailed output
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT u.username, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.id, u.username
ORDER BY order_count DESC
LIMIT 10;

-- Understanding the output
/*
Limit  (cost=1234.56..1234.57 rows=10 width=36) (actual time=10.234..10.235 rows=10 loops=1)
  ->  Sort  (cost=1234.56..1345.67 rows=1000 width=36) (actual time=10.230..10.231 rows=10 loops=1)
        Sort Key: (count(o.id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        ->  HashAggregate  (cost=1000.00..1100.00 rows=1000 width=36)
              Group Key: u.id
              ->  Hash Left Join  (cost=500.00..900.00 rows=5000 width=8)
                    Hash Cond: (u.id = o.user_id)
                    ->  Seq Scan on users u  (cost=0.00..100.00 rows=1000 width=8)
                          Filter: (created_at >= '2024-01-01'::date)
                    ->  Hash  (cost=300.00..300.00 rows=10000 width=8)
                          ->  Seq Scan on orders o  (cost=0.00..300.00 rows=10000 width=8)
Planning Time: 0.234 ms
Execution Time: 10.567 ms
*/
```

**Key Metrics to Analyze**:
- **cost**: Estimated cost (lower is better)
- **rows**: Estimated number of rows
- **actual time**: Actual execution time
- **loops**: Number of times operation executed
- **Seq Scan**: Full table scan (bad for large tables)
- **Index Scan**: Using index (good)
- **Bitmap Index Scan**: Multiple indexes combined
- **Hash Join**: Join using hash table
- **Nested Loop**: Join using nested loops

### MySQL EXPLAIN

```sql
-- Basic EXPLAIN
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- Extended information
EXPLAIN FORMAT=JSON
SELECT u.username, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.id
ORDER BY order_count DESC
LIMIT 10;

-- Analyze (MySQL 8.0+)
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'john@example.com';

-- Understanding the output
/*
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| 1  | SIMPLE      | users | ALL  | NULL          | NULL | NULL    | NULL | 1000 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
*/
```

**Key Columns**:
- **type**: Join type (system > const > eq_ref > ref > range > index > ALL)
  - `const`: Single row match
  - `eq_ref`: One row per combination (foreign key)
  - `ref`: Multiple rows with index
  - `range`: Index range scan
  - `index`: Full index scan
  - `ALL`: Full table scan (worst)
- **possible_keys**: Indexes that could be used
- **key**: Index actually used
- **rows**: Estimated rows examined
- **Extra**: Additional information
  - `Using index`: Covering index
  - `Using where`: WHERE clause applied
  - `Using temporary`: Temporary table created
  - `Using filesort`: Sorting required

### SQL Server Execution Plans

```sql
-- Show actual execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT u.username, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2024-01-01'
GROUP BY u.id, u.username
ORDER BY order_count DESC;

-- Estimated execution plan
SET SHOWPLAN_ALL ON;
GO
SELECT * FROM users WHERE email = 'john@example.com';
GO
SET SHOWPLAN_ALL OFF;

-- XML execution plan
SET SHOWPLAN_XML ON;
GO
SELECT * FROM users WHERE email = 'john@example.com';
GO
SET SHOWPLAN_XML OFF;
```

---

## Indexing Strategies

### Index Types and When to Use

#### 1. B-Tree Indexes (Default)

**Best for**:
- Equality comparisons (`WHERE column = value`)
- Range queries (`WHERE column > value`)
- Sorting (`ORDER BY column`)
- Pattern matching (`WHERE column LIKE 'prefix%'`)

```sql
-- Single column index
CREATE INDEX idx_users_email ON users(email);

-- Composite index (order matters!)
CREATE INDEX idx_orders_user_date ON orders(user_id, order_date);

-- Covering index (includes all needed columns)
CREATE INDEX idx_users_cover ON users(email) INCLUDE (username, created_at);

-- Partial index (index subset of rows)
CREATE INDEX idx_active_users ON users(email) WHERE is_active = TRUE;

-- Expression index
CREATE INDEX idx_lower_email ON users(LOWER(email));
```

**Composite Index Rules**:
```sql
-- Index: (user_id, order_date, status)

-- ✅ Uses index (leftmost prefix)
WHERE user_id = 1
WHERE user_id = 1 AND order_date > '2024-01-01'
WHERE user_id = 1 AND order_date > '2024-01-01' AND status = 'completed'

-- ❌ Doesn't use index (skips leftmost column)
WHERE order_date > '2024-01-01'
WHERE status = 'completed'
WHERE order_date > '2024-01-01' AND status = 'completed'
```

#### 2. Hash Indexes

**Best for**:
- Exact equality lookups only
- No range queries or sorting

```sql
-- PostgreSQL
CREATE INDEX idx_users_hash ON users USING HASH (email);

-- MySQL (MEMORY engine only)
CREATE TABLE cache (
    key VARCHAR(100),
    value TEXT,
    INDEX USING HASH (key)
) ENGINE=MEMORY;
```

#### 3. GIN Indexes (PostgreSQL)

**Best for**:
- Full-text search
- JSONB queries
- Array columns

```sql
-- Full-text search
CREATE INDEX idx_articles_search ON articles USING GIN(to_tsvector('english', content));

-- JSONB
CREATE INDEX idx_products_attrs ON products USING GIN(attributes);
SELECT * FROM products WHERE attributes @> '{"brand": "Dell"}';

-- Arrays
CREATE INDEX idx_articles_tags ON articles USING GIN(tags);
SELECT * FROM articles WHERE tags @> ARRAY['postgresql', 'database'];
```

#### 4. GiST Indexes (PostgreSQL)

**Best for**:
- Geospatial data
- Full-text search
- Range types

```sql
-- Geospatial
CREATE INDEX idx_locations_coords ON locations USING GIST(coordinates);
SELECT * FROM locations WHERE ST_DWithin(coordinates, ST_MakePoint(-73.97, 40.78), 5000);

-- Range types
CREATE INDEX idx_reservations_time ON reservations USING GIST(time_range);
```

#### 5. Full-Text Indexes

**MySQL**:
```sql
-- Create full-text index
CREATE FULLTEXT INDEX idx_articles_fulltext ON articles(title, content);

-- Search
SELECT * FROM articles WHERE MATCH(title, content) AGAINST('database optimization');

-- Boolean mode
SELECT * FROM articles WHERE MATCH(title, content) AGAINST('+database -sql' IN BOOLEAN MODE);
```

**PostgreSQL**:
```sql
-- Add tsvector column
ALTER TABLE articles ADD COLUMN search_vector tsvector;

UPDATE articles SET search_vector =
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(content, ''));

CREATE INDEX idx_articles_search ON articles USING GIN(search_vector);

-- Search
SELECT * FROM articles WHERE search_vector @@ to_tsquery('english', 'database & optimization');
```

### Index Maintenance

```sql
-- PostgreSQL: Rebuild index
REINDEX INDEX idx_users_email;
REINDEX TABLE users;

-- MySQL: Optimize table (rebuilds indexes)
OPTIMIZE TABLE users;

-- SQL Server: Rebuild index
ALTER INDEX idx_users_email ON users REBUILD;

-- Update statistics
ANALYZE users;  -- PostgreSQL
ANALYZE TABLE users;  -- MySQL
UPDATE STATISTICS users;  -- SQL Server

-- Check index usage (PostgreSQL)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC;

-- Find unused indexes (PostgreSQL)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
    AND idx_scan = 0
    AND indexname NOT LIKE '%_pkey';

-- Index size (PostgreSQL)
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexname::regclass) DESC;
```

---

## Query Optimization Techniques

### 1. SELECT Only Needed Columns

```sql
-- ❌ Bad: Fetches all columns
SELECT * FROM users WHERE id = 1;

-- ✅ Good: Fetch only needed columns
SELECT id, username, email FROM users WHERE id = 1;

-- Benefit: Reduced I/O, network transfer, memory usage
```

### 2. Use WHERE Clauses Effectively

```sql
-- ❌ Bad: Function on indexed column prevents index usage
SELECT * FROM users WHERE YEAR(created_at) = 2024;

-- ✅ Good: Range query uses index
SELECT * FROM users WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01';

-- ❌ Bad: Implicit type conversion
SELECT * FROM users WHERE user_id = '123';  -- user_id is INT

-- ✅ Good: Correct type
SELECT * FROM users WHERE user_id = 123;
```

### 3. Optimize JOINs

```sql
-- ❌ Bad: Multiple separate queries
SELECT * FROM users WHERE id = 1;
SELECT * FROM orders WHERE user_id = 1;
SELECT * FROM order_items WHERE order_id IN (1, 2, 3);

-- ✅ Good: Single JOIN query
SELECT
    u.username,
    o.order_id,
    o.total,
    oi.product_id,
    oi.quantity
FROM users u
INNER JOIN orders o ON u.id = o.user_id
INNER JOIN order_items oi ON o.id = oi.order_id
WHERE u.id = 1;

-- Optimize JOIN order (smaller tables first)
-- EXPLAIN will help database optimizer choose best order

-- ❌ Bad: Cartesian product (CROSS JOIN)
SELECT * FROM users, orders WHERE users.id = 1;

-- ✅ Good: Explicit JOIN
SELECT * FROM users INNER JOIN orders ON users.id = orders.user_id WHERE users.id = 1;
```

### 4. Use EXISTS Instead of IN

```sql
-- ❌ Slower for large subqueries
SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE total > 100);

-- ✅ Faster (stops at first match)
SELECT * FROM users u WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.total > 100
);

-- ❌ Bad: NOT IN with NULLs
SELECT * FROM users WHERE id NOT IN (SELECT user_id FROM orders WHERE user_id IS NOT NULL);

-- ✅ Good: NOT EXISTS
SELECT * FROM users u WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);
```

### 5. Avoid SELECT DISTINCT When Possible

```sql
-- ❌ Bad: DISTINCT adds sorting overhead
SELECT DISTINCT user_id FROM orders;

-- ✅ Good: GROUP BY is often faster
SELECT user_id FROM orders GROUP BY user_id;

-- ✅ Better: If you need unique users who placed orders
SELECT u.id FROM users u
INNER JOIN orders o ON u.id = o.user_id;
```

### 6. Limit Results

```sql
-- ❌ Bad: Fetches all rows
SELECT * FROM orders ORDER BY created_at DESC;

-- ✅ Good: LIMIT results
SELECT * FROM orders ORDER BY created_at DESC LIMIT 100;

-- Pagination with OFFSET (works but can be slow)
SELECT * FROM orders ORDER BY created_at DESC LIMIT 100 OFFSET 500;

-- ✅ Better: Keyset pagination (cursor-based)
SELECT * FROM orders
WHERE created_at < '2024-01-15 10:00:00'
ORDER BY created_at DESC
LIMIT 100;
```

### 7. Use UNION ALL Instead of UNION

```sql
-- ❌ Slower: UNION removes duplicates (requires sorting)
SELECT user_id FROM orders
UNION
SELECT user_id FROM refunds;

-- ✅ Faster: UNION ALL keeps duplicates
SELECT user_id FROM orders
UNION ALL
SELECT user_id FROM refunds;
```

### 8. Optimize Subqueries

```sql
-- ❌ Bad: Correlated subquery (executes for each row)
SELECT
    u.username,
    (SELECT COUNT(*) FROM orders WHERE user_id = u.id) AS order_count
FROM users u;

-- ✅ Good: JOIN with aggregation
SELECT
    u.username,
    COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username;

-- ✅ Alternative: CTE
WITH order_counts AS (
    SELECT user_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY user_id
)
SELECT u.username, COALESCE(oc.order_count, 0) AS order_count
FROM users u
LEFT JOIN order_counts oc ON u.id = oc.user_id;
```

### 9. Use CTEs for Readability and Performance

```sql
-- Common Table Expressions
WITH active_users AS (
    SELECT id, username, email
    FROM users
    WHERE is_active = TRUE
),
recent_orders AS (
    SELECT user_id, order_id, total
    FROM orders
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    au.username,
    COUNT(ro.order_id) AS order_count,
    SUM(ro.total) AS total_spent
FROM active_users au
LEFT JOIN recent_orders ro ON au.id = ro.user_id
GROUP BY au.id, au.username
HAVING SUM(ro.total) > 1000
ORDER BY total_spent DESC;

-- Recursive CTE for hierarchical data
WITH RECURSIVE category_tree AS (
    -- Base case
    SELECT id, name, parent_id, 1 AS level
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive case
    SELECT c.id, c.name, c.parent_id, ct.level + 1
    FROM categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree ORDER BY level, name;
```

### 10. Batch Operations

```sql
-- ❌ Bad: Multiple individual INSERTs
INSERT INTO logs (message) VALUES ('log1');
INSERT INTO logs (message) VALUES ('log2');
INSERT INTO logs (message) VALUES ('log3');

-- ✅ Good: Batch INSERT
INSERT INTO logs (message) VALUES ('log1'), ('log2'), ('log3');

-- ❌ Bad: Loop with individual UPDATEs
-- UPDATE users SET last_login = NOW() WHERE id = 1;
-- UPDATE users SET last_login = NOW() WHERE id = 2;
-- ...

-- ✅ Good: Single UPDATE
UPDATE users SET last_login = NOW() WHERE id IN (1, 2, 3, 4, 5);

-- ✅ Better: Batch with transaction
BEGIN;
INSERT INTO logs (message) VALUES ('log1'), ('log2'), ('log3');
UPDATE users SET last_login = NOW() WHERE id IN (1, 2, 3);
COMMIT;
```

---

## Common Anti-Patterns

### 1. N+1 Query Problem

See [dedicated section below](#n1-query-problem)

### 2. SELECT *

```sql
-- ❌ Anti-pattern
SELECT * FROM users;

-- Problems:
-- - Fetches unnecessary columns
-- - Breaks when schema changes
-- - Prevents covering indexes
-- - Increases network transfer

-- ✅ Solution
SELECT id, username, email FROM users;
```

### 3. NOT IN with NULLs

```sql
-- ❌ Anti-pattern: Returns no rows if subquery has NULL
SELECT * FROM users WHERE id NOT IN (SELECT user_id FROM orders);

-- ✅ Solution: Use NOT EXISTS or IS NOT NULL
SELECT * FROM users u WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);
```

### 4. LIKE with Leading Wildcard

```sql
-- ❌ Anti-pattern: Can't use index
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- ✅ Solution: If possible, use trailing wildcard
SELECT * FROM users WHERE email LIKE 'john%';

-- ✅ Alternative: Full-text search for this use case
CREATE FULLTEXT INDEX idx_emails ON users(email);
SELECT * FROM users WHERE MATCH(email) AGAINST('gmail');
```

### 5. OR in WHERE Clause

```sql
-- ❌ Anti-pattern: May not use indexes efficiently
SELECT * FROM products WHERE category = 'Electronics' OR category = 'Computers';

-- ✅ Solution: Use IN
SELECT * FROM products WHERE category IN ('Electronics', 'Computers');

-- ❌ Anti-pattern: Different columns with OR
SELECT * FROM products WHERE category = 'Electronics' OR price < 100;

-- ✅ Solution: UNION ALL
SELECT * FROM products WHERE category = 'Electronics'
UNION ALL
SELECT * FROM products WHERE price < 100 AND category != 'Electronics';
```

### 6. Implicit Type Conversions

```sql
-- ❌ Anti-pattern: String compared to INT
SELECT * FROM users WHERE user_id = '123';  -- user_id is INT

-- ✅ Solution: Use correct type
SELECT * FROM users WHERE user_id = 123;

-- ❌ Anti-pattern: Function on indexed column
SELECT * FROM orders WHERE DATE(created_at) = '2024-01-15';

-- ✅ Solution: Range query
SELECT * FROM orders WHERE created_at >= '2024-01-15' AND created_at < '2024-01-16';
```

### 7. Overusing DISTINCT

```sql
-- ❌ Anti-pattern: DISTINCT to hide data quality issues
SELECT DISTINCT user_id, username FROM users;

-- ✅ Solution: Fix data quality or use appropriate query
-- If username should be unique per user_id:
SELECT user_id, MAX(username) FROM users GROUP BY user_id;
```

### 8. Selecting from Large Table Without Filtering

```sql
-- ❌ Anti-pattern: Full table scan
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;

-- ✅ Solution: Add index on sort column
CREATE INDEX idx_orders_created ON orders(created_at DESC);
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;
```

---

## N+1 Query Problem

### Understanding the Problem

The N+1 query problem occurs when you fetch N records and then execute 1 additional query for each record.

**Example**:
```javascript
// ❌ N+1 Problem: 1 query + N queries
// Query 1: Get all users
const users = await db.query('SELECT * FROM users LIMIT 10');

// Query 2-11: Get orders for each user (10 additional queries)
for (const user of users) {
    const orders = await db.query('SELECT * FROM orders WHERE user_id = ?', [user.id]);
    user.orders = orders;
}
// Total: 1 + 10 = 11 queries
```

### Solutions

#### 1. Use JOINs

```sql
-- ✅ Solution: Single query with JOIN
SELECT
    u.id AS user_id,
    u.username,
    o.id AS order_id,
    o.total,
    o.created_at
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

-- Application groups results
```

#### 2. Eager Loading with IN Clause

```javascript
// ✅ Solution: 2 queries instead of N+1
// Query 1: Get all users
const users = await db.query('SELECT * FROM users LIMIT 10');
const userIds = users.map(u => u.id);

// Query 2: Get all orders for these users
const orders = await db.query(
    'SELECT * FROM orders WHERE user_id IN (?)',
    [userIds]
);

// Group orders by user_id in application
const ordersByUserId = orders.reduce((acc, order) => {
    if (!acc[order.user_id]) acc[order.user_id] = [];
    acc[order.user_id].push(order);
    return acc;
}, {});

users.forEach(user => {
    user.orders = ordersByUserId[user.id] || [];
});
```

#### 3. ORM Eager Loading

**Sequelize (Node.js)**:
```javascript
// ❌ N+1 Problem
const users = await User.findAll();
for (const user of users) {
    user.orders = await user.getOrders();
}

// ✅ Solution: Eager loading
const users = await User.findAll({
    include: [{ model: Order }]
});
```

**TypeORM (Node.js)**:
```javascript
// ✅ Eager loading
const users = await userRepository.find({
    relations: ['orders']
});
```

**Django ORM (Python)**:
```python
# ❌ N+1 Problem
users = User.objects.all()
for user in users:
    orders = user.orders.all()  # Additional query per user

# ✅ Solution: select_related (for ForeignKey)
users = User.objects.select_related('profile').all()

# ✅ Solution: prefetch_related (for reverse ForeignKey, ManyToMany)
users = User.objects.prefetch_related('orders').all()
```

**Rails (Ruby)**:
```ruby
# ❌ N+1 Problem
users = User.all
users.each do |user|
  puts user.orders.count
end

# ✅ Solution: includes
users = User.includes(:orders).all
```

#### 4. DataLoader Pattern

```javascript
// DataLoader batches and caches requests
import DataLoader from 'dataloader';

const orderLoader = new DataLoader(async (userIds) => {
    const orders = await db.query(
        'SELECT * FROM orders WHERE user_id IN (?)',
        [userIds]
    );

    // Group by user_id
    const ordersByUserId = userIds.map(id =>
        orders.filter(order => order.user_id === id)
    );

    return ordersByUserId;
});

// Usage
const users = await getUsers();
const usersWithOrders = await Promise.all(
    users.map(async user => ({
        ...user,
        orders: await orderLoader.load(user.id)
    }))
);
```

---

## Caching Strategies

### 1. Query Result Caching

```javascript
// Cache-aside pattern
async function getUser(userId) {
    const cacheKey = `user:${userId}`;

    // Try cache first
    let user = await redis.get(cacheKey);
    if (user) {
        return JSON.parse(user);
    }

    // Cache miss - query database
    user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

    // Store in cache (with TTL)
    await redis.setex(cacheKey, 3600, JSON.stringify(user));

    return user;
}

// Invalidate on update
async function updateUser(userId, data) {
    await db.query('UPDATE users SET ? WHERE id = ?', [data, userId]);

    // Invalidate cache
    await redis.del(`user:${userId}`);
}
```

### 2. Application-Level Caching

```javascript
// Memory cache with LRU
const LRU = require('lru-cache');

const cache = new LRU({
    max: 500,  // Max items
    maxAge: 1000 * 60 * 60  // 1 hour
});

async function getProduct(productId) {
    const cacheKey = `product:${productId}`;

    if (cache.has(cacheKey)) {
        return cache.get(cacheKey);
    }

    const product = await db.query('SELECT * FROM products WHERE id = ?', [productId]);
    cache.set(cacheKey, product);

    return product;
}
```

### 3. Materialized Views

```sql
-- Create materialized view
CREATE MATERIALIZED VIEW daily_sales_summary AS
SELECT
    DATE(order_date) AS sale_date,
    COUNT(*) AS order_count,
    SUM(total) AS total_revenue,
    AVG(total) AS avg_order_value
FROM orders
GROUP BY DATE(order_date);

-- Create index on materialized view
CREATE INDEX idx_daily_sales_date ON daily_sales_summary(sale_date);

-- Query materialized view (fast!)
SELECT * FROM daily_sales_summary WHERE sale_date >= '2024-01-01';

-- Refresh materialized view
REFRESH MATERIALIZED VIEW daily_sales_summary;

-- Concurrent refresh (doesn't lock readers)
REFRESH MATERIALIZED VIEW CONCURRENTLY daily_sales_summary;

-- Automatic refresh (PostgreSQL with pg_cron)
CREATE EXTENSION pg_cron;
SELECT cron.schedule('refresh-daily-sales', '0 1 * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY daily_sales_summary$$
);
```

### 4. Database Query Cache

**MySQL Query Cache** (deprecated in 8.0):
```sql
-- Enable query cache (MySQL 5.7 and earlier)
SET GLOBAL query_cache_size = 67108864;  -- 64MB
SET GLOBAL query_cache_type = 1;

-- Check query cache status
SHOW STATUS LIKE 'Qcache%';
```

**PostgreSQL Shared Buffers**:
```ini
# postgresql.conf
shared_buffers = 256MB  # Cached data pages
effective_cache_size = 4GB  # OS cache estimate
```

### 5. Connection Pooling

```javascript
// Node.js with pg (PostgreSQL)
const { Pool } = require('pg');

const pool = new Pool({
    host: 'localhost',
    database: 'mydb',
    user: 'user',
    password: 'password',
    max: 20,  // Max clients
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// Use connection from pool
const result = await pool.query('SELECT * FROM users WHERE id = $1', [1]);

// Python with psycopg2
import psycopg2.pool

connection_pool = psycopg2.pool.SimpleConnectionPool(
    minconn=1,
    maxconn=10,
    host='localhost',
    database='mydb',
    user='user',
    password='password'
)
```

---

## Database-Specific Optimizations

### PostgreSQL

```sql
-- Analyze table statistics
ANALYZE users;

-- Vacuum to reclaim space
VACUUM users;
VACUUM FULL users;  -- More aggressive (locks table)

-- Auto-vacuum configuration
ALTER TABLE large_table SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02
);

-- Parallel query execution
SET max_parallel_workers_per_gather = 4;

-- Monitor query performance
CREATE EXTENSION pg_stat_statements;
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;

-- Find slow queries
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 1000  -- > 1 second
ORDER BY mean_exec_time DESC;

-- Connection statistics
SELECT * FROM pg_stat_activity;

-- Table bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_dead_tup,
    n_live_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### MySQL

```sql
-- Analyze table
ANALYZE TABLE users;

-- Optimize table (defragment)
OPTIMIZE TABLE users;

-- Check table for errors
CHECK TABLE users;

-- Slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;  -- Log queries > 2 seconds
SET GLOBAL log_queries_not_using_indexes = 'ON';

-- Query profiling
SET profiling = 1;
SELECT * FROM users WHERE email = 'john@example.com';
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;

-- InnoDB buffer pool statistics
SHOW STATUS LIKE 'Innodb_buffer_pool%';

-- Table status
SHOW TABLE STATUS LIKE 'users';

-- Process list (running queries)
SHOW FULL PROCESSLIST;

-- Kill slow query
KILL QUERY 12345;
```

### SQL Server

```sql
-- Update statistics
UPDATE STATISTICS users WITH FULLSCAN;

-- Rebuild indexes
ALTER INDEX ALL ON users REBUILD;

-- Reorganize indexes
ALTER INDEX idx_users_email ON users REORGANIZE;

-- Query Store
ALTER DATABASE MyDatabase SET QUERY_STORE = ON;

-- Top queries by duration
SELECT TOP 10
    qt.query_sql_text,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.count_executions
FROM sys.query_store_query_text qt
INNER JOIN sys.query_store_query q ON qt.query_text_id = q.query_text_id
INNER JOIN sys.query_store_plan p ON q.query_id = p.query_id
INNER JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.avg_duration DESC;

-- Dynamic Management Views
-- Active requests
SELECT * FROM sys.dm_exec_requests WHERE status = 'running';

-- Wait statistics
SELECT * FROM sys.dm_os_wait_stats ORDER BY wait_time_ms DESC;

-- Index usage
SELECT
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_updates
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id;
```

---

## Monitoring & Profiling

### Application-Level Monitoring

```javascript
// Query timing middleware (Express.js)
const queryLogger = (req, res, next) => {
    const originalQuery = db.query;

    db.query = function(...args) {
        const start = Date.now();
        const result = originalQuery.apply(db, args);

        result.then(() => {
            const duration = Date.now() - start;
            if (duration > 1000) {  // Log slow queries
                console.warn(`Slow query (${duration}ms):`, args[0]);
            }
        });

        return result;
    };

    next();
};

// Database metrics
const metrics = {
    queryCount: 0,
    slowQueryCount: 0,
    totalQueryTime: 0,
    queryTimes: []
};

function trackQuery(duration, sql) {
    metrics.queryCount++;
    metrics.totalQueryTime += duration;
    metrics.queryTimes.push(duration);

    if (duration > 1000) {
        metrics.slowQueryCount++;
        logger.warn('Slow query', { duration, sql });
    }
}

// Report metrics
setInterval(() => {
    const avgQueryTime = metrics.totalQueryTime / metrics.queryCount;
    console.log('Database Metrics:', {
        queryCount: metrics.queryCount,
        slowQueryCount: metrics.slowQueryCount,
        avgQueryTime: avgQueryTime.toFixed(2)
    });

    // Reset metrics
    Object.keys(metrics).forEach(key => {
        if (Array.isArray(metrics[key])) {
            metrics[key] = [];
        } else {
            metrics[key] = 0;
        }
    });
}, 60000);  // Every minute
```

### Database Monitoring Tools

**PostgreSQL**:
- pg_stat_statements (built-in)
- pgAdmin
- pgBadger (log analyzer)
- Prometheus + Grafana
- DataDog, New Relic, AppDynamics

**MySQL**:
- Performance Schema
- MySQL Workbench
- Percona Monitoring and Management (PMM)
- MySQL Enterprise Monitor
- Prometheus MySQL Exporter

**SQL Server**:
- SQL Server Management Studio (SSMS)
- Query Store
- Dynamic Management Views (DMVs)
- SQL Server Profiler
- Azure SQL Analytics

**Cross-Database**:
- DataDog
- New Relic
- AppDynamics
- Dynatrace
- Elastic APM

---

## Best Practices

### 1. Indexing
- ✅ Create indexes for frequently queried columns
- ✅ Use composite indexes for multi-column queries
- ✅ Index foreign keys
- ✅ Monitor index usage and remove unused indexes
- ✅ Keep indexes small (only necessary columns)
- ❌ Don't over-index (slows writes)
- ❌ Avoid indexing low-cardinality columns
- ❌ Don't index frequently updated columns

### 2. Query Writing
- ✅ Select only needed columns
- ✅ Use WHERE clauses to filter early
- ✅ Use appropriate JOINs
- ✅ Avoid SELECT DISTINCT when possible
- ✅ Use LIMIT for pagination
- ✅ Use prepared statements
- ❌ Avoid SELECT *
- ❌ Avoid functions on indexed columns in WHERE
- ❌ Avoid LIKE with leading wildcard

### 3. Performance
- ✅ Use EXPLAIN to analyze queries
- ✅ Implement connection pooling
- ✅ Cache frequently accessed data
- ✅ Use batch operations
- ✅ Monitor slow query logs
- ✅ Regular VACUUM/ANALYZE (PostgreSQL)
- ✅ Regular OPTIMIZE (MySQL)
- ❌ Don't ignore execution plans
- ❌ Don't premature optimize

### 4. Development
- ✅ Test queries with production-like data volume
- ✅ Use ORMs wisely (watch for N+1)
- ✅ Implement query timeouts
- ✅ Log and monitor slow queries
- ✅ Version control schema changes
- ❌ Don't trust estimated costs alone
- ❌ Don't skip testing with large datasets

### 5. Maintenance
- ✅ Regular backups
- ✅ Monitor database health
- ✅ Update statistics regularly
- ✅ Rebuild fragmented indexes
- ✅ Archive old data
- ❌ Don't ignore warnings and alerts
- ❌ Don't skip maintenance windows

---

## Performance Checklist

Before deploying to production:

- [ ] All queries analyzed with EXPLAIN
- [ ] Indexes created for all WHERE, JOIN, ORDER BY columns
- [ ] No N+1 query problems
- [ ] Connection pooling configured
- [ ] Slow query logging enabled
- [ ] Query timeouts set
- [ ] Caching strategy implemented
- [ ] Pagination implemented for large result sets
- [ ] No SELECT * in production code
- [ ] Prepared statements used for all dynamic queries
- [ ] Database monitoring set up
- [ ] Load testing completed
- [ ] Regular maintenance scheduled
- [ ] Backup and recovery tested

---

## Additional Resources

### Books
- "SQL Performance Explained" by Markus Winand
- "High Performance MySQL" by Baron Schwartz
- "PostgreSQL Query Optimization" by Henrietta Dombrovskaya

### Online Resources
- Use The Index, Luke: https://use-the-index-luke.com/
- PostgreSQL EXPLAIN: https://www.postgresql.org/docs/current/using-explain.html
- MySQL EXPLAIN: https://dev.mysql.com/doc/refman/8.0/en/explain.html

### Tools
- pgAdmin (PostgreSQL)
- MySQL Workbench
- SQL Server Management Studio
- DataGrip (JetBrains)
- DBeaver (Universal)

---

**Next**: [Backup & Replication →](backup-replication.md)
