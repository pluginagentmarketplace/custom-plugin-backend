# NoSQL Databases

## Overview

NoSQL databases are non-relational databases designed for specific data models and access patterns. They provide flexible schemas, horizontal scalability, and high performance for large-scale distributed systems. The term "NoSQL" initially meant "non-SQL" but now commonly means "Not Only SQL."

## Table of Contents
1. [NoSQL Overview & Types](#nosql-overview--types)
2. [MongoDB (Document Database)](#mongodb-document-database)
3. [Redis (Key-Value Store)](#redis-key-value-store)
4. [Cassandra (Wide-Column Store)](#cassandra-wide-column-store)
5. [DynamoDB (AWS NoSQL)](#dynamodb-aws-nosql)
6. [Elasticsearch (Search Engine)](#elasticsearch-search-engine)
7. [Database Comparison](#database-comparison)
8. [CAP Theorem](#cap-theorem)
9. [Best Practices](#best-practices)

---

## NoSQL Overview & Types

### NoSQL Database Categories

#### 1. Document Databases
Store data in flexible, JSON-like documents
- **Examples**: MongoDB, CouchDB, RavenDB
- **Use Cases**: Content management, user profiles, catalogs
- **Pros**: Flexible schema, nested data, intuitive
- **Cons**: Complex queries can be challenging

#### 2. Key-Value Stores
Simple key-value pairs with fast lookups
- **Examples**: Redis, Memcached, DynamoDB
- **Use Cases**: Caching, session management, real-time
- **Pros**: Extremely fast, simple, scalable
- **Cons**: Limited querying, simple data model

#### 3. Wide-Column Stores
Store data in column families
- **Examples**: Cassandra, HBase, ScyllaDB
- **Use Cases**: Time-series, IoT, high write throughput
- **Pros**: Scalable, distributed, high availability
- **Cons**: Complex data modeling, eventual consistency

#### 4. Graph Databases
Optimize for relationships and connections
- **Examples**: Neo4j, Amazon Neptune, ArangoDB
- **Use Cases**: Social networks, recommendation engines, fraud detection
- **Pros**: Efficient relationship queries, intuitive modeling
- **Cons**: Harder to scale, specialized use cases

#### 5. Search Engines
Full-text search and analytics
- **Examples**: Elasticsearch, Solr, Algolia
- **Use Cases**: Search features, log analysis, real-time analytics
- **Pros**: Fast search, powerful analytics, scalable
- **Cons**: Not a primary database, eventual consistency

### When to Use NoSQL

✅ **Use NoSQL when you need**:
- Flexible or evolving schema
- Horizontal scalability
- High write/read throughput
- Distributed data across regions
- Real-time applications
- Specific data models (documents, graphs, time-series)

❌ **Avoid NoSQL when you need**:
- Complex transactions across multiple records
- Strong consistency guarantees
- Complex JOINs and relationships
- ACID compliance across distributed data
- Well-defined, stable schema

---

## MongoDB (Document Database)

### Overview
MongoDB is the most popular NoSQL database, storing data in flexible JSON-like BSON (Binary JSON) documents. It's ideal for applications requiring flexible schemas and hierarchical data.

**Current Version**: MongoDB 7.0+
**License**: Server Side Public License (SSPL)

### Data Model

```javascript
// Document structure (BSON format)
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "username": "john_doe",
  "email": "john@example.com",
  "profile": {
    "firstName": "John",
    "lastName": "Doe",
    "age": 30,
    "address": {
      "street": "123 Main St",
      "city": "New York",
      "state": "NY",
      "zip": "10001"
    }
  },
  "interests": ["coding", "music", "travel"],
  "orders": [
    {
      "orderId": 12345,
      "date": ISODate("2024-01-15"),
      "total": 99.99
    }
  ],
  "createdAt": ISODate("2023-06-01"),
  "updatedAt": ISODate("2024-01-15")
}
```

### CRUD Operations

```javascript
// INSERT - Create documents
db.users.insertOne({
  username: "john_doe",
  email: "john@example.com",
  createdAt: new Date()
});

// Insert multiple documents
db.users.insertMany([
  { username: "user1", email: "user1@example.com" },
  { username: "user2", email: "user2@example.com" },
  { username: "user3", email: "user3@example.com" }
]);

// READ - Find documents
// Find all
db.users.find();

// Find with filter
db.users.find({ age: { $gte: 18 } });

// Find one
db.users.findOne({ username: "john_doe" });

// Find with projection (select specific fields)
db.users.find(
  { age: { $gte: 18 } },
  { username: 1, email: 1, _id: 0 }
);

// Find with sorting and limiting
db.users.find({ age: { $gte: 18 } })
  .sort({ createdAt: -1 })
  .limit(10)
  .skip(20);  // Pagination

// UPDATE - Modify documents
// Update one document
db.users.updateOne(
  { username: "john_doe" },
  {
    $set: { email: "newemail@example.com" },
    $inc: { loginCount: 1 },
    $currentDate: { lastModified: true }
  }
);

// Update multiple documents
db.users.updateMany(
  { isActive: false },
  { $set: { status: "archived" } }
);

// Replace entire document
db.users.replaceOne(
  { _id: ObjectId("...") },
  { username: "new_user", email: "new@example.com" }
);

// Upsert (update or insert)
db.users.updateOne(
  { username: "john_doe" },
  { $set: { email: "john@example.com", age: 30 } },
  { upsert: true }
);

// DELETE - Remove documents
// Delete one
db.users.deleteOne({ username: "john_doe" });

// Delete many
db.users.deleteMany({ isActive: false });
```

### Query Operators

```javascript
// Comparison operators
db.products.find({ price: { $gt: 100 } });  // Greater than
db.products.find({ price: { $gte: 100 } });  // Greater than or equal
db.products.find({ price: { $lt: 100 } });  // Less than
db.products.find({ price: { $lte: 100 } });  // Less than or equal
db.products.find({ price: { $ne: 100 } });  // Not equal
db.products.find({ category: { $in: ["Electronics", "Computers"] } });
db.products.find({ category: { $nin: ["Clothing"] } });

// Logical operators
db.products.find({
  $and: [
    { price: { $gte: 100 } },
    { category: "Electronics" }
  ]
});

db.products.find({
  $or: [
    { price: { $lt: 50 } },
    { onSale: true }
  ]
});

db.products.find({
  price: { $not: { $gt: 100 } }
});

// Element operators
db.users.find({ phone: { $exists: true } });
db.users.find({ age: { $type: "number" } });

// Array operators
db.articles.find({ tags: { $all: ["mongodb", "database"] } });
db.articles.find({ tags: "mongodb" });  // Array contains
db.articles.find({ ratings: { $size: 3 } });
db.articles.find({
  comments: {
    $elemMatch: { author: "John", rating: { $gte: 4 } }
  }
});

// Regular expressions
db.users.find({ email: /gmail\.com$/ });
db.users.find({ username: { $regex: "^john", $options: "i" } });

// Text search
db.articles.createIndex({ title: "text", content: "text" });
db.articles.find({ $text: { $search: "mongodb tutorial" } });
```

### Aggregation Pipeline

```javascript
// Aggregation framework for complex queries
db.orders.aggregate([
  // Stage 1: Match documents
  {
    $match: {
      orderDate: {
        $gte: ISODate("2024-01-01"),
        $lt: ISODate("2025-01-01")
      }
    }
  },

  // Stage 2: Unwind array
  { $unwind: "$items" },

  // Stage 3: Lookup (join)
  {
    $lookup: {
      from: "products",
      localField: "items.productId",
      foreignField: "_id",
      as: "productDetails"
    }
  },

  // Stage 4: Unwind lookup result
  { $unwind: "$productDetails" },

  // Stage 5: Group and aggregate
  {
    $group: {
      _id: "$productDetails.category",
      totalRevenue: { $sum: { $multiply: ["$items.quantity", "$items.price"] } },
      orderCount: { $sum: 1 },
      avgOrderValue: { $avg: "$total" },
      products: { $addToSet: "$productDetails.name" }
    }
  },

  // Stage 6: Sort
  { $sort: { totalRevenue: -1 } },

  // Stage 7: Limit results
  { $limit: 10 },

  // Stage 8: Project (shape output)
  {
    $project: {
      category: "$_id",
      totalRevenue: { $round: ["$totalRevenue", 2] },
      orderCount: 1,
      avgOrderValue: { $round: ["$avgOrderValue", 2] },
      productCount: { $size: "$products" },
      _id: 0
    }
  }
]);

// Common aggregation operators
db.sales.aggregate([
  {
    $group: {
      _id: "$region",
      total: { $sum: "$amount" },
      average: { $avg: "$amount" },
      min: { $min: "$amount" },
      max: { $max: "$amount" },
      count: { $count: {} },
      first: { $first: "$date" },
      last: { $last: "$date" }
    }
  }
]);

// Date aggregation
db.orders.aggregate([
  {
    $group: {
      _id: {
        year: { $year: "$orderDate" },
        month: { $month: "$orderDate" },
        day: { $dayOfMonth: "$orderDate" }
      },
      dailyRevenue: { $sum: "$total" }
    }
  }
]);

// Faceted search (multiple aggregations)
db.products.aggregate([
  {
    $facet: {
      "categoryCounts": [
        { $group: { _id: "$category", count: { $sum: 1 } } }
      ],
      "priceRanges": [
        {
          $bucket: {
            groupBy: "$price",
            boundaries: [0, 50, 100, 200, 500, 1000],
            default: "Other",
            output: { count: { $sum: 1 } }
          }
        }
      ],
      "avgPriceByCategory": [
        {
          $group: {
            _id: "$category",
            avgPrice: { $avg: "$price" }
          }
        }
      ]
    }
  }
]);
```

### Indexing

```javascript
// Create indexes
db.users.createIndex({ username: 1 });  // Ascending
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ createdAt: -1 });  // Descending

// Compound index
db.users.createIndex({ lastName: 1, firstName: 1 });

// Multikey index (for arrays)
db.articles.createIndex({ tags: 1 });

// Text index
db.articles.createIndex({ title: "text", content: "text" });

// Geospatial index
db.locations.createIndex({ coordinates: "2dsphere" });

// Hashed index (for sharding)
db.users.createIndex({ userId: "hashed" });

// TTL index (auto-delete documents)
db.sessions.createIndex(
  { createdAt: 1 },
  { expireAfterSeconds: 3600 }  // Delete after 1 hour
);

// Partial index (index subset)
db.users.createIndex(
  { email: 1 },
  { partialFilterExpression: { isActive: true } }
);

// Sparse index (only documents with field)
db.users.createIndex({ phone: 1 }, { sparse: true });

// List indexes
db.users.getIndexes();

// Drop index
db.users.dropIndex("username_1");

// Analyze index usage
db.users.aggregate([
  { $indexStats: {} }
]);
```

### Replica Sets

```javascript
// Initialize replica set
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongodb0:27017" },
    { _id: 1, host: "mongodb1:27017" },
    { _id: 2, host: "mongodb2:27017" }
  ]
});

// Check replica set status
rs.status();

// Check replication lag
rs.printSecondaryReplicationInfo();

// Add member
rs.add("mongodb3:27017");

// Remove member
rs.remove("mongodb3:27017");

// Set priority (higher = more likely to be primary)
cfg = rs.conf();
cfg.members[1].priority = 2;
rs.reconfig(cfg);

// Read preference in application
// - primary (default)
// - primaryPreferred
// - secondary
// - secondaryPreferred
// - nearest

// Write concern
db.users.insertOne(
  { username: "john" },
  { writeConcern: { w: "majority", wtimeout: 5000 } }
);

// Read concern
db.users.find().readConcern("majority");
```

### Sharding

```javascript
// Enable sharding on database
sh.enableSharding("mydb");

// Shard collection with hashed shard key
sh.shardCollection("mydb.users", { userId: "hashed" });

// Shard collection with range-based shard key
sh.shardCollection("mydb.orders", { customerId: 1, orderDate: 1 });

// Check sharding status
sh.status();

// Add shard
sh.addShard("rs0/mongodb0:27017,mongodb1:27017,mongodb2:27017");

// Move chunk manually
sh.moveChunk("mydb.users", { userId: 12345 }, "shard0001");

// Zone sharding (geographic distribution)
sh.addShardToZone("shard0000", "US");
sh.addShardToZone("shard0001", "EU");

sh.updateZoneKeyRange(
  "mydb.users",
  { country: "US" },
  { country: "US\uffff" },
  "US"
);
```

### Best Practices

1. **Data Modeling**:
   - Design for access patterns, not relationships
   - Embed for 1-to-few, reference for 1-to-many
   - Denormalize for read performance
   - Avoid large documents (>16MB limit)

2. **Indexing**:
   - Create indexes for all query patterns
   - Use compound indexes for multiple fields
   - Monitor index usage with explain()
   - Remove unused indexes

3. **Performance**:
   - Use aggregation pipeline for complex queries
   - Implement connection pooling
   - Use projection to limit returned fields
   - Enable query profiling for slow queries

4. **Operations**:
   - Always use replica sets (minimum 3 nodes)
   - Regular backups with mongodump or Atlas
   - Monitor with MongoDB Atlas or Ops Manager
   - Use authentication and authorization

---

## Redis (Key-Value Store)

### Overview
Redis is an in-memory data structure store used as a database, cache, message broker, and queue. Known for exceptional performance (sub-millisecond latency) and rich data structures.

**Current Version**: Redis 7.x
**License**: BSD 3-Clause (Open Source), Redis Stack (commercial features)

### Data Structures

#### 1. Strings (Basic Key-Value)
```bash
# Set and get
SET user:1000:name "John Doe"
GET user:1000:name

# Set with expiration (TTL in seconds)
SETEX session:abc123 3600 "user_data"
SET cache:product:100 "product_data" EX 300

# Atomic operations
INCR page:views
INCRBY user:1000:points 10
DECR inventory:product:100

# Append
APPEND log:2024-01-15 "New log entry\n"

# Multiple keys
MSET user:1:name "John" user:2:name "Jane"
MGET user:1:name user:2:name

# Get and set (atomic swap)
GETSET config:maintenance "true"

# Check existence
EXISTS user:1000:name

# Delete
DEL user:1000:name

# Get TTL
TTL session:abc123

# Set expiration
EXPIRE user:1000:session 3600
EXPIREAT user:1000:session 1735689600  # Unix timestamp
```

#### 2. Hashes (Objects)
```bash
# Set hash fields
HSET user:1000 name "John Doe" email "john@example.com" age 30

# Get hash field
HGET user:1000 name

# Get all fields
HGETALL user:1000

# Get multiple fields
HMGET user:1000 name email

# Check if field exists
HEXISTS user:1000 name

# Delete field
HDEL user:1000 age

# Increment hash field
HINCRBY user:1000 loginCount 1
HINCRBYFLOAT user:1000 balance 10.50

# Get all keys or values
HKEYS user:1000
HVALS user:1000

# Get field count
HLEN user:1000
```

#### 3. Lists (Ordered Collections)
```bash
# Push to list
LPUSH queue:tasks "task1"  # Left push (prepend)
RPUSH queue:tasks "task2"  # Right push (append)

# Pop from list
LPOP queue:tasks  # Remove and return first
RPOP queue:tasks  # Remove and return last

# Blocking pop (wait for element)
BLPOP queue:tasks 30  # Block for 30 seconds

# Get range
LRANGE queue:tasks 0 -1  # All elements
LRANGE queue:tasks 0 9   # First 10 elements

# Get by index
LINDEX queue:tasks 0

# Set by index
LSET queue:tasks 0 "updated_task"

# Get length
LLEN queue:tasks

# Trim list
LTRIM queue:tasks 0 99  # Keep only first 100

# Insert before/after
LINSERT queue:tasks BEFORE "task2" "new_task"

# Remove elements
LREM queue:tasks 1 "task1"  # Remove first occurrence
```

#### 4. Sets (Unordered Unique Collections)
```bash
# Add members
SADD tags:article:100 "redis" "database" "nosql"

# Remove members
SREM tags:article:100 "nosql"

# Check membership
SISMEMBER tags:article:100 "redis"

# Get all members
SMEMBERS tags:article:100

# Get random member
SRANDMEMBER tags:article:100

# Pop random member
SPOP tags:article:100

# Get cardinality (count)
SCARD tags:article:100

# Set operations
SINTER tags:article:100 tags:article:200  # Intersection
SUNION tags:article:100 tags:article:200  # Union
SDIFF tags:article:100 tags:article:200   # Difference

# Store result
SINTERSTORE common:tags tags:article:100 tags:article:200
```

#### 5. Sorted Sets (Ordered by Score)
```bash
# Add members with scores
ZADD leaderboard 100 "player1" 200 "player2" 150 "player3"

# Get rank (0-indexed)
ZRANK leaderboard "player1"
ZREVRANK leaderboard "player1"  # Reverse rank

# Get score
ZSCORE leaderboard "player1"

# Increment score
ZINCRBY leaderboard 10 "player1"

# Get range
ZRANGE leaderboard 0 9              # By rank, ascending
ZREVRANGE leaderboard 0 9           # By rank, descending
ZRANGEBYSCORE leaderboard 100 200   # By score range

# With scores
ZRANGE leaderboard 0 9 WITHSCORES

# Get count
ZCARD leaderboard
ZCOUNT leaderboard 100 200  # Count in score range

# Remove members
ZREM leaderboard "player1"
ZREMRANGEBYRANK leaderboard 0 9     # Remove by rank
ZREMRANGEBYSCORE leaderboard 0 100  # Remove by score
```

#### 6. Streams (Log/Event Data)
```bash
# Add to stream
XADD events:user:1000 * action "login" timestamp "2024-01-15T10:00:00"

# Read from stream
XREAD COUNT 10 STREAMS events:user:1000 0

# Read new messages (blocking)
XREAD BLOCK 5000 STREAMS events:user:1000 $

# Consumer groups
XGROUP CREATE events:user:1000 processors 0
XREADGROUP GROUP processors consumer1 COUNT 10 STREAMS events:user:1000 >

# Acknowledge message
XACK events:user:1000 processors "1234567890-0"

# Get stream info
XINFO STREAM events:user:1000

# Trim stream
XTRIM events:user:1000 MAXLEN 1000
```

### Caching Patterns

#### 1. Cache-Aside (Lazy Loading)
```python
def get_user(user_id):
    # Try cache first
    cache_key = f"user:{user_id}"
    cached = redis.get(cache_key)

    if cached:
        return json.loads(cached)

    # Cache miss - fetch from database
    user = db.users.find_one({"_id": user_id})

    # Store in cache
    redis.setex(cache_key, 3600, json.dumps(user))

    return user
```

#### 2. Write-Through
```python
def update_user(user_id, data):
    # Update database
    db.users.update_one({"_id": user_id}, {"$set": data})

    # Update cache
    user = db.users.find_one({"_id": user_id})
    redis.setex(f"user:{user_id}", 3600, json.dumps(user))
```

#### 3. Write-Behind (Write-Back)
```python
def update_user(user_id, data):
    # Update cache immediately
    redis.hset(f"user:{user_id}", mapping=data)

    # Queue for async database update
    redis.lpush("write_queue", json.dumps({
        "type": "user_update",
        "user_id": user_id,
        "data": data
    }))

# Background worker
def process_write_queue():
    while True:
        item = redis.brpop("write_queue", timeout=5)
        if item:
            data = json.loads(item[1])
            db.users.update_one(
                {"_id": data["user_id"]},
                {"$set": data["data"]}
            )
```

### Advanced Features

#### Pub/Sub
```bash
# Subscribe to channel
SUBSCRIBE notifications:user:1000

# Publish message
PUBLISH notifications:user:1000 "New message"

# Pattern subscription
PSUBSCRIBE notifications:*

# List channels
PUBSUB CHANNELS
PUBSUB NUMSUB notifications:user:1000
```

#### Transactions
```bash
# Transaction with MULTI/EXEC
MULTI
SET account:1 "100"
SET account:2 "200"
EXEC

# Watch for optimistic locking
WATCH account:1
balance = GET account:1
MULTI
SET account:1 (balance - 100)
EXEC

# Discard transaction
DISCARD
```

#### Lua Scripts (Atomic Operations)
```bash
# Load script
SCRIPT LOAD "return redis.call('GET', KEYS[1])"

# Execute script
EVAL "return redis.call('SET', KEYS[1], ARGV[1])" 1 mykey myvalue

# Rate limiting script
EVAL "
  local current = redis.call('INCR', KEYS[1])
  if current == 1 then
    redis.call('EXPIRE', KEYS[1], ARGV[1])
  end
  return current
" 1 rate:user:1000 60

# Execute stored script
EVALSHA <sha1> 1 mykey myvalue
```

#### Geospatial
```bash
# Add locations
GEOADD locations 13.361389 38.115556 "Palermo" 15.087269 37.502669 "Catania"

# Get position
GEOPOS locations "Palermo"

# Distance between points
GEODIST locations "Palermo" "Catania" km

# Radius query
GEORADIUS locations 15 37 200 km WITHDIST WITHCOORD

# By member
GEORADIUSBYMEMBER locations "Palermo" 100 km
```

### Persistence

#### RDB (Point-in-Time Snapshots)
```bash
# redis.conf
save 900 1      # Save after 900s if 1 key changed
save 300 10     # Save after 300s if 10 keys changed
save 60 10000   # Save after 60s if 10000 keys changed

# Manual save
SAVE       # Blocking
BGSAVE     # Background

# Get last save time
LASTSAVE
```

#### AOF (Append-Only File)
```bash
# redis.conf
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec  # always, everysec, no

# Rewrite AOF
BGREWRITEAOF

# AOF persistence guarantees better durability but slower
```

### Replication
```bash
# redis.conf (replica)
replicaof <master-ip> <master-port>
masterauth <password>

# Check replication info
INFO replication

# Make replica writable (not recommended)
# replica-read-only no

# Promote replica to master
REPLICAOF NO ONE
```

### Redis Cluster
```bash
# Create cluster (minimum 3 master nodes)
redis-cli --cluster create \
  127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 \
  127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 \
  --cluster-replicas 1

# Check cluster info
CLUSTER INFO
CLUSTER NODES

# Get slot range
CLUSTER SLOTS

# Move slot
CLUSTER SETSLOT <slot> MIGRATING <node-id>
```

### Best Practices

1. **Use Cases**:
   - Caching (primary use)
   - Session storage
   - Real-time analytics
   - Leaderboards
   - Rate limiting
   - Message queues (with streams)

2. **Performance**:
   - Use pipelining for bulk operations
   - Use connection pooling
   - Set appropriate maxmemory and eviction policy
   - Monitor memory usage
   - Use Redis Sentinel for HA

3. **Security**:
   - Enable AUTH password
   - Use ACLs for fine-grained access
   - Bind to localhost or private network
   - Disable dangerous commands (CONFIG, FLUSHDB)
   - Use SSL/TLS for connections

4. **Operations**:
   - Monitor with INFO command
   - Use SLOWLOG for slow queries
   - Regular backups (RDB + AOF)
   - Test failover procedures
   - Don't use SELECT (multiple databases) in production

---

## Cassandra (Wide-Column Store)

### Overview
Apache Cassandra is a distributed NoSQL database designed for high availability and scalability with no single point of failure. It excels at handling massive write throughput.

**Current Version**: Apache Cassandra 4.x+
**License**: Apache License 2.0

### Data Model

```sql
-- Keyspace (like database)
CREATE KEYSPACE my_app
WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3,
  'datacenter2': 2
};

USE my_app;

-- Table with partition key and clustering key
CREATE TABLE users_by_email (
    email TEXT,
    user_id UUID,
    username TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY (email)
);

-- Composite partition key
CREATE TABLE users_by_region (
    country TEXT,
    state TEXT,
    user_id UUID,
    username TEXT,
    PRIMARY KEY ((country, state), user_id)
);

-- With clustering key (determines sort order)
CREATE TABLE user_events (
    user_id UUID,
    event_time TIMESTAMP,
    event_type TEXT,
    data TEXT,
    PRIMARY KEY (user_id, event_time)
) WITH CLUSTERING ORDER BY (event_time DESC);

-- Time-series data pattern
CREATE TABLE sensor_data (
    sensor_id UUID,
    year INT,
    month INT,
    timestamp TIMESTAMP,
    temperature DECIMAL,
    humidity DECIMAL,
    PRIMARY KEY ((sensor_id, year, month), timestamp)
) WITH CLUSTERING ORDER BY (timestamp DESC);
```

### CRUD Operations

```sql
-- INSERT
INSERT INTO users_by_email (email, user_id, username, created_at)
VALUES ('john@example.com', uuid(), 'john_doe', toTimestamp(now()));

-- INSERT with TTL (time-to-live)
INSERT INTO sessions (session_id, user_id, data)
VALUES (uuid(), uuid(), '{"token": "abc"}')
USING TTL 3600;

-- UPDATE
UPDATE users_by_email
SET username = 'john_doe_updated'
WHERE email = 'john@example.com';

-- UPDATE with timestamp
UPDATE users_by_email USING TIMESTAMP 1234567890
SET username = 'john_doe'
WHERE email = 'john@example.com';

-- Conditional update (lightweight transaction)
UPDATE users_by_email
SET username = 'new_name'
WHERE email = 'john@example.com'
IF username = 'old_name';

-- SELECT
SELECT * FROM users_by_email WHERE email = 'john@example.com';

-- SELECT with clustering key range
SELECT * FROM user_events
WHERE user_id = 123e4567-e89b-12d3-a456-426614174000
  AND event_time > '2024-01-01'
  AND event_time < '2024-02-01';

-- SELECT with LIMIT
SELECT * FROM user_events
WHERE user_id = 123e4567-e89b-12d3-a456-426614174000
LIMIT 100;

-- DELETE
DELETE FROM users_by_email WHERE email = 'john@example.com';

-- DELETE specific columns
DELETE username FROM users_by_email WHERE email = 'john@example.com';

-- Batch operations
BEGIN BATCH
  INSERT INTO users (user_id, name) VALUES (uuid(), 'John');
  UPDATE user_stats SET login_count = login_count + 1 WHERE user_id = uuid();
APPLY BATCH;
```

### Data Types

```sql
-- Collections
CREATE TABLE products (
    product_id UUID PRIMARY KEY,
    name TEXT,
    tags SET<TEXT>,                    -- Unique values
    features LIST<TEXT>,               -- Ordered values
    attributes MAP<TEXT, TEXT>         -- Key-value pairs
);

INSERT INTO products (product_id, name, tags, features, attributes)
VALUES (
    uuid(),
    'Laptop',
    {'electronics', 'computers'},
    ['16GB RAM', '512GB SSD', 'Intel i7'],
    {'brand': 'Dell', 'model': 'XPS 13'}
);

-- Update collections
UPDATE products
SET tags = tags + {'sale'}
WHERE product_id = uuid();

-- User-defined types (UDT)
CREATE TYPE address (
    street TEXT,
    city TEXT,
    state TEXT,
    zip TEXT
);

CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    name TEXT,
    addresses MAP<TEXT, FROZEN<address>>
);

-- Counters
CREATE TABLE page_views (
    page_id UUID PRIMARY KEY,
    view_count COUNTER
);

UPDATE page_views
SET view_count = view_count + 1
WHERE page_id = uuid();
```

### Consistency Levels

```sql
-- Set consistency level for query
CONSISTENCY QUORUM;
SELECT * FROM users WHERE email = 'john@example.com';

-- Available consistency levels:
-- ONE - Any single node (lowest latency, lowest consistency)
-- TWO - Two nodes
-- THREE - Three nodes
-- QUORUM - Majority of nodes (replication_factor / 2 + 1)
-- ALL - All nodes (highest consistency, lowest availability)
-- LOCAL_ONE - One node in local datacenter
-- LOCAL_QUORUM - Quorum in local datacenter
-- EACH_QUORUM - Quorum in each datacenter

-- Write consistency
CONSISTENCY LOCAL_QUORUM;
INSERT INTO users (user_id, name) VALUES (uuid(), 'John');

-- Read consistency
CONSISTENCY ONE;
SELECT * FROM users WHERE user_id = uuid();
```

### Secondary Indexes

```sql
-- Create secondary index
CREATE INDEX ON users_by_email (username);

-- Query using secondary index
SELECT * FROM users_by_email WHERE username = 'john_doe';

-- Materialized view (alternative to secondary index)
CREATE MATERIALIZED VIEW users_by_username AS
    SELECT * FROM users_by_email
    WHERE username IS NOT NULL AND email IS NOT NULL
    PRIMARY KEY (username, email);

-- Query materialized view
SELECT * FROM users_by_username WHERE username = 'john_doe';
```

### Best Practices

1. **Data Modeling**:
   - Design tables based on query patterns
   - One query per table (denormalize heavily)
   - Partition key distributes data evenly
   - Clustering key determines sort order
   - Avoid large partitions (keep under 100MB)
   - Avoid unbounded partitions (use bucketing)

2. **Querying**:
   - Always include partition key in WHERE clause
   - Use prepared statements
   - Avoid ALLOW FILTERING (requires full table scan)
   - Use batches carefully (only for same partition)
   - Implement pagination with paging state

3. **Operations**:
   - Run nodetool repair regularly
   - Monitor with nodetool status
   - Choose appropriate consistency level
   - Use compaction strategies wisely
   - Regular backups with snapshots

4. **Performance**:
   - Use SSTables (immutable sorted string tables)
   - Tune JVM heap size
   - Monitor GC pauses
   - Use appropriate read/write timeout values

---

## DynamoDB (AWS NoSQL)

### Overview
Amazon DynamoDB is a fully managed, serverless NoSQL database service providing single-digit millisecond performance at any scale. It automatically scales and handles replication and failover.

**Provider**: Amazon Web Services (AWS)
**Pricing**: Pay-per-request or provisioned capacity

### Data Model

```javascript
// Table structure
{
  TableName: "Users",
  KeySchema: [
    { AttributeName: "userId", KeyType: "HASH" },        // Partition key
    { AttributeName: "createdAt", KeyType: "RANGE" }     // Sort key (optional)
  ],
  AttributeDefinitions: [
    { AttributeName: "userId", AttributeType: "S" },
    { AttributeName: "createdAt", AttributeType: "N" },
    { AttributeName: "email", AttributeType: "S" }
  ],
  BillingMode: "PAY_PER_REQUEST",  // or "PROVISIONED"
  // If PROVISIONED:
  // ProvisionedThroughput: {
  //   ReadCapacityUnits: 5,
  //   WriteCapacityUnits: 5
  // }
}

// Item structure (max 400KB)
{
  "userId": "user123",           // String
  "createdAt": 1704067200,       // Number (Unix timestamp)
  "username": "john_doe",
  "email": "john@example.com",
  "profile": {                   // Map (nested object)
    "firstName": "John",
    "lastName": "Doe",
    "age": 30
  },
  "interests": ["coding", "music"],  // List
  "tags": new Set(["premium", "verified"]),  // Set
  "isActive": true,              // Boolean
  "metadata": null               // Null
}
```

### Operations (AWS SDK v3 - JavaScript)

```javascript
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
  UpdateCommand,
  DeleteCommand,
  QueryCommand,
  ScanCommand,
  BatchGetCommand,
  BatchWriteCommand
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({ region: "us-east-1" });
const docClient = DynamoDBDocumentClient.from(client);

// PUT - Create or replace item
await docClient.send(new PutCommand({
  TableName: "Users",
  Item: {
    userId: "user123",
    username: "john_doe",
    email: "john@example.com",
    createdAt: Date.now()
  }
}));

// PUT with condition (only if not exists)
await docClient.send(new PutCommand({
  TableName: "Users",
  Item: { userId: "user123", username: "john_doe" },
  ConditionExpression: "attribute_not_exists(userId)"
}));

// GET - Retrieve single item
const result = await docClient.send(new GetCommand({
  TableName: "Users",
  Key: { userId: "user123" },
  ProjectionExpression: "userId, username, email"  // Select specific attributes
}));

// GET with strong consistency
const strongResult = await docClient.send(new GetCommand({
  TableName: "Users",
  Key: { userId: "user123" },
  ConsistentRead: true
}));

// UPDATE - Modify item
await docClient.send(new UpdateCommand({
  TableName: "Users",
  Key: { userId: "user123" },
  UpdateExpression: "SET #email = :email, loginCount = loginCount + :inc",
  ExpressionAttributeNames: {
    "#email": "email"  // Use when attribute name is reserved word
  },
  ExpressionAttributeValues: {
    ":email": "newemail@example.com",
    ":inc": 1
  },
  ReturnValues: "ALL_NEW"  // Return updated item
}));

// UPDATE with condition
await docClient.send(new UpdateCommand({
  TableName: "Users",
  Key: { userId: "user123" },
  UpdateExpression: "SET isActive = :active",
  ConditionExpression: "attribute_exists(userId) AND version = :version",
  ExpressionAttributeValues: {
    ":active": false,
    ":version": 5
  }
}));

// DELETE
await docClient.send(new DeleteCommand({
  TableName: "Users",
  Key: { userId: "user123" }
}));

// QUERY - Query by partition key
const queryResult = await docClient.send(new QueryCommand({
  TableName: "Orders",
  KeyConditionExpression: "userId = :userId AND createdAt > :date",
  ExpressionAttributeValues: {
    ":userId": "user123",
    ":date": 1704067200
  },
  ScanIndexForward: false,  // Sort descending
  Limit: 10
}));

// SCAN - Read entire table (expensive!)
const scanResult = await docClient.send(new ScanCommand({
  TableName: "Users",
  FilterExpression: "isActive = :active",
  ExpressionAttributeValues: {
    ":active": true
  }
}));

// Batch operations
// Batch get (up to 100 items)
await docClient.send(new BatchGetCommand({
  RequestItems: {
    "Users": {
      Keys: [
        { userId: "user1" },
        { userId: "user2" },
        { userId: "user3" }
      ]
    }
  }
}));

// Batch write (up to 25 items)
await docClient.send(new BatchWriteCommand({
  RequestItems: {
    "Users": [
      {
        PutRequest: {
          Item: { userId: "user1", username: "user1" }
        }
      },
      {
        DeleteRequest: {
          Key: { userId: "user2" }
        }
      }
    ]
  }
}));

// Pagination
let lastEvaluatedKey = null;
do {
  const result = await docClient.send(new QueryCommand({
    TableName: "Orders",
    KeyConditionExpression: "userId = :userId",
    ExpressionAttributeValues: { ":userId": "user123" },
    Limit: 100,
    ExclusiveStartKey: lastEvaluatedKey
  }));

  // Process items
  console.log(result.Items);

  lastEvaluatedKey = result.LastEvaluatedKey;
} while (lastEvaluatedKey);
```

### Global Secondary Indexes (GSI)

```javascript
// Create GSI
{
  TableName: "Users",
  AttributeDefinitions: [
    { AttributeName: "userId", AttributeType: "S" },
    { AttributeName: "email", AttributeType: "S" }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: "EmailIndex",
      KeySchema: [
        { AttributeName: "email", KeyType: "HASH" }
      ],
      Projection: {
        ProjectionType: "ALL"  // or "KEYS_ONLY" or "INCLUDE"
      },
      ProvisionedThroughput: {  // If table is provisioned
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5
      }
    }
  ]
}

// Query GSI
await docClient.send(new QueryCommand({
  TableName: "Users",
  IndexName: "EmailIndex",
  KeyConditionExpression: "email = :email",
  ExpressionAttributeValues: {
    ":email": "john@example.com"
  }
}));
```

### Local Secondary Indexes (LSI)

```javascript
// LSI must be created with table
{
  TableName: "Orders",
  KeySchema: [
    { AttributeName: "userId", KeyType: "HASH" },
    { AttributeName: "orderId", KeyType: "RANGE" }
  ],
  LocalSecondaryIndexes: [
    {
      IndexName: "UserStatusIndex",
      KeySchema: [
        { AttributeName: "userId", KeyType: "HASH" },
        { AttributeName: "status", KeyType: "RANGE" }
      ],
      Projection: { ProjectionType: "ALL" }
    }
  ]
}

// Query LSI
await docClient.send(new QueryCommand({
  TableName: "Orders",
  IndexName: "UserStatusIndex",
  KeyConditionExpression: "userId = :userId AND #status = :status",
  ExpressionAttributeNames: {
    "#status": "status"
  },
  ExpressionAttributeValues: {
    ":userId": "user123",
    ":status": "completed"
  }
}));
```

### DynamoDB Streams

```javascript
// Enable streams on table
{
  StreamSpecification: {
    StreamEnabled: true,
    StreamViewType: "NEW_AND_OLD_IMAGES"  // or NEW_IMAGE, OLD_IMAGE, KEYS_ONLY
  }
}

// Process streams with Lambda
export const handler = async (event) => {
  for (const record of event.Records) {
    console.log('Event:', record.eventName);  // INSERT, MODIFY, REMOVE
    console.log('New Image:', record.dynamodb.NewImage);
    console.log('Old Image:', record.dynamodb.OldImage);

    // React to changes
    if (record.eventName === 'INSERT') {
      // Send welcome email
    }
  }
};
```

### Transactions

```javascript
import { TransactWriteCommand, TransactGetCommand } from "@aws-sdk/lib-dynamodb";

// Transactional write (up to 25 items)
await docClient.send(new TransactWriteCommand({
  TransactItems: [
    {
      Put: {
        TableName: "Orders",
        Item: { orderId: "order123", userId: "user123", total: 100 }
      }
    },
    {
      Update: {
        TableName: "Users",
        Key: { userId: "user123" },
        UpdateExpression: "SET orderCount = orderCount + :inc",
        ExpressionAttributeValues: { ":inc": 1 }
      }
    },
    {
      ConditionCheck: {
        TableName: "Inventory",
        Key: { productId: "prod123" },
        ConditionExpression: "stock >= :qty",
        ExpressionAttributeValues: { ":qty": 1 }
      }
    }
  ]
}));

// Transactional read
await docClient.send(new TransactGetCommand({
  TransactItems: [
    {
      Get: {
        TableName: "Users",
        Key: { userId: "user123" }
      }
    },
    {
      Get: {
        TableName: "Orders",
        Key: { orderId: "order123" }
      }
    }
  ]
}));
```

### Best Practices

1. **Data Modeling**:
   - Design for uniform data distribution
   - Use composite keys effectively
   - Avoid hot partitions
   - Denormalize for read efficiency
   - Use GSI for alternative query patterns

2. **Performance**:
   - Use DAX (DynamoDB Accelerator) for caching
   - Implement exponential backoff for throttling
   - Use batch operations for bulk reads/writes
   - Enable auto-scaling for provisioned capacity
   - Monitor with CloudWatch metrics

3. **Cost Optimization**:
   - Choose appropriate capacity mode (on-demand vs provisioned)
   - Use sparse indexes
   - Implement TTL for automatic data expiration
   - Compress large attributes
   - Archive old data to S3

4. **Operations**:
   - Enable point-in-time recovery (PITR)
   - Use global tables for multi-region
   - Monitor consumed capacity
   - Set up CloudWatch alarms
   - Use DynamoDB Streams for event-driven architectures

---

## Elasticsearch (Search Engine)

### Overview
Elasticsearch is a distributed search and analytics engine built on Apache Lucene. It's designed for horizontal scalability, real-time search, and complex analytics.

**Current Version**: Elasticsearch 8.x
**License**: Elastic License 2.0 / SSPL
**Stack**: ELK (Elasticsearch, Logstash, Kibana)

### Index and Document Structure

```json
// Index mapping (schema)
PUT /products
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 2,
    "analysis": {
      "analyzer": {
        "custom_analyzer": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "stop", "snowball"]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "name": {
        "type": "text",
        "analyzer": "custom_analyzer",
        "fields": {
          "keyword": { "type": "keyword" }
        }
      },
      "description": { "type": "text" },
      "price": { "type": "float" },
      "category": { "type": "keyword" },
      "tags": { "type": "keyword" },
      "in_stock": { "type": "boolean" },
      "created_at": { "type": "date" },
      "location": { "type": "geo_point" },
      "specifications": { "type": "object" },
      "reviews": {
        "type": "nested",
        "properties": {
          "author": { "type": "text" },
          "rating": { "type": "integer" },
          "comment": { "type": "text" }
        }
      }
    }
  }
}
```

### CRUD Operations

```json
// Index document (create or replace)
POST /products/_doc/1
{
  "name": "Laptop",
  "description": "High performance laptop",
  "price": 1299.99,
  "category": "Electronics",
  "tags": ["computers", "laptops"],
  "in_stock": true,
  "created_at": "2024-01-15"
}

// Auto-generate ID
POST /products/_doc
{
  "name": "Mouse",
  "price": 29.99
}

// Update document
POST /products/_update/1
{
  "doc": {
    "price": 1199.99,
    "in_stock": false
  }
}

// Update with script
POST /products/_update/1
{
  "script": {
    "source": "ctx._source.price *= params.discount",
    "params": {
      "discount": 0.9
    }
  }
}

// Get document
GET /products/_doc/1

// Delete document
DELETE /products/_doc/1

// Bulk operations
POST /_bulk
{ "index": { "_index": "products", "_id": "1" } }
{ "name": "Product 1", "price": 10.00 }
{ "index": { "_index": "products", "_id": "2" } }
{ "name": "Product 2", "price": 20.00 }
{ "update": { "_index": "products", "_id": "1" } }
{ "doc": { "price": 12.00 } }
{ "delete": { "_index": "products", "_id": "3" } }
```

### Search Queries

```json
// Match query (full-text search)
GET /products/_search
{
  "query": {
    "match": {
      "description": "laptop computer"
    }
  }
}

// Multi-match query
GET /products/_search
{
  "query": {
    "multi_match": {
      "query": "laptop",
      "fields": ["name^2", "description"]  // Boost name field
    }
  }
}

// Term query (exact match)
GET /products/_search
{
  "query": {
    "term": {
      "category.keyword": "Electronics"
    }
  }
}

// Range query
GET /products/_search
{
  "query": {
    "range": {
      "price": {
        "gte": 100,
        "lte": 500
      }
    }
  }
}

// Boolean query (combine queries)
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "description": "laptop" } }
      ],
      "filter": [
        { "term": { "category.keyword": "Electronics" } },
        { "range": { "price": { "lte": 1000 } } }
      ],
      "should": [
        { "term": { "tags": "premium" } }
      ],
      "must_not": [
        { "term": { "in_stock": false } }
      ]
    }
  }
}

// Fuzzy query (typo tolerance)
GET /products/_search
{
  "query": {
    "fuzzy": {
      "name": {
        "value": "laptap",
        "fuzziness": "AUTO"
      }
    }
  }
}

// Wildcard query
GET /products/_search
{
  "query": {
    "wildcard": {
      "name": "lap*"
    }
  }
}

// Nested query
GET /products/_search
{
  "query": {
    "nested": {
      "path": "reviews",
      "query": {
        "bool": {
          "must": [
            { "match": { "reviews.author": "John" } },
            { "range": { "reviews.rating": { "gte": 4 } } }
          ]
        }
      }
    }
  }
}

// Geospatial query
GET /stores/_search
{
  "query": {
    "geo_distance": {
      "distance": "10km",
      "location": {
        "lat": 40.7128,
        "lon": -74.0060
      }
    }
  }
}
```

### Aggregations

```json
// Metric aggregations
GET /products/_search
{
  "size": 0,
  "aggs": {
    "avg_price": { "avg": { "field": "price" } },
    "max_price": { "max": { "field": "price" } },
    "min_price": { "min": { "field": "price" } },
    "total_revenue": { "sum": { "field": "price" } },
    "price_stats": { "stats": { "field": "price" } }
  }
}

// Bucket aggregations
GET /products/_search
{
  "size": 0,
  "aggs": {
    "categories": {
      "terms": {
        "field": "category.keyword",
        "size": 10
      },
      "aggs": {
        "avg_price": { "avg": { "field": "price" } }
      }
    }
  }
}

// Histogram aggregation
GET /products/_search
{
  "size": 0,
  "aggs": {
    "price_ranges": {
      "histogram": {
        "field": "price",
        "interval": 100
      }
    }
  }
}

// Date histogram
GET /orders/_search
{
  "size": 0,
  "aggs": {
    "sales_over_time": {
      "date_histogram": {
        "field": "created_at",
        "calendar_interval": "month"
      },
      "aggs": {
        "total_revenue": { "sum": { "field": "total" } }
      }
    }
  }
}

// Range aggregation
GET /products/_search
{
  "size": 0,
  "aggs": {
    "price_tiers": {
      "range": {
        "field": "price",
        "ranges": [
          { "to": 50 },
          { "from": 50, "to": 100 },
          { "from": 100, "to": 500 },
          { "from": 500 }
        ]
      }
    }
  }
}

// Pipeline aggregations
GET /products/_search
{
  "size": 0,
  "aggs": {
    "sales_per_month": {
      "date_histogram": {
        "field": "created_at",
        "calendar_interval": "month"
      },
      "aggs": {
        "total_sales": { "sum": { "field": "price" } }
      }
    },
    "avg_monthly_sales": {
      "avg_bucket": {
        "buckets_path": "sales_per_month>total_sales"
      }
    }
  }
}
```

### Advanced Features

**Analyzers and Tokenizers**
```json
// Custom analyzer
PUT /my_index
{
  "settings": {
    "analysis": {
      "char_filter": {
        "my_char_filter": {
          "type": "mapping",
          "mappings": ["& => and"]
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "pattern",
          "pattern": "\\W+"
        }
      },
      "filter": {
        "my_stop_filter": {
          "type": "stop",
          "stopwords": ["the", "a", "an"]
        }
      },
      "analyzer": {
        "my_analyzer": {
          "type": "custom",
          "char_filter": ["my_char_filter"],
          "tokenizer": "my_tokenizer",
          "filter": ["lowercase", "my_stop_filter", "snowball"]
        }
      }
    }
  }
}

// Test analyzer
GET /my_index/_analyze
{
  "analyzer": "my_analyzer",
  "text": "The quick brown fox & dog"
}
```

**Suggesters (Auto-completion)**
```json
// Completion suggester
PUT /products
{
  "mappings": {
    "properties": {
      "name_suggest": {
        "type": "completion"
      }
    }
  }
}

POST /products/_doc/1
{
  "name_suggest": {
    "input": ["Laptop", "Laptop Computer", "Dell Laptop"]
  }
}

GET /products/_search
{
  "suggest": {
    "product_suggest": {
      "prefix": "lap",
      "completion": {
        "field": "name_suggest",
        "size": 5,
        "fuzzy": { "fuzziness": "AUTO" }
      }
    }
  }
}
```

### Best Practices

1. **Indexing**:
   - Choose appropriate field types (text vs keyword)
   - Use mapping templates for dynamic indices
   - Design proper shard sizing (20-50GB per shard)
   - Disable _source for space savings (if not needed)
   - Use bulk API for batch indexing

2. **Querying**:
   - Use filters instead of queries when possible (cached)
   - Implement proper pagination (search_after, not from/size)
   - Use query context for relevance, filter context for yes/no
   - Avoid deep pagination
   - Use index patterns for time-series data

3. **Performance**:
   - Monitor cluster health and performance
   - Use proper number of shards and replicas
   - Implement index lifecycle management (ILM)
   - Use frozen indices for cold data
   - Regular force merge for read-only indices

4. **Operations**:
   - Monitor with Kibana or Elasticsearch APIs
   - Regular snapshots for backups
   - Use aliases for zero-downtime reindexing
   - Implement proper security (authentication, authorization)
   - Monitor JVM heap usage

---

## Database Comparison

| Feature | MongoDB | Redis | Cassandra | DynamoDB | Elasticsearch |
|---------|---------|-------|-----------|----------|---------------|
| **Type** | Document | Key-Value | Wide-Column | Key-Value/Document | Search Engine |
| **Data Model** | Flexible Documents | Data Structures | Column Families | Items with Attributes | JSON Documents |
| **Query Language** | MQL | Commands | CQL | API calls | Query DSL |
| **ACID** | Multi-doc (4.0+) | Single operation | Tunable | Limited | No |
| **Consistency** | Strong (default) | Strong | Tunable | Eventual/Strong | Eventual |
| **Scalability** | Horizontal (Sharding) | Horizontal (Cluster) | Horizontal (P2P) | Automatic | Horizontal |
| **Performance** | Very Fast | Extremely Fast | Very Fast | Very Fast | Fast (search) |
| **Use Cases** | Web apps, Mobile | Caching, Real-time | Time-series, IoT | Serverless, Gaming | Search, Analytics |
| **Managed Service** | Atlas | Redis Cloud | Astra DB | Native AWS | Elastic Cloud |
| **Open Source** | Yes (SSPL) | Yes (BSD) | Yes (Apache) | No | Yes (Elastic License) |
| **Best For** | Flexible schemas | High-speed cache | Write-heavy | Cloud-native | Full-text search |

---

## CAP Theorem

### Understanding CAP

**C**onsistency: All nodes see the same data at the same time
**A**vailability: Every request receives a response
**P**artition Tolerance: System continues despite network failures

**CAP Theorem**: Can only guarantee 2 of 3 properties in a distributed system.

### Database Classifications

**CP (Consistency + Partition Tolerance)**
- MongoDB (with majority read/write concern)
- HBase
- Redis Cluster (with wait command)
- Trade-off: May reject requests if can't guarantee consistency

**AP (Availability + Partition Tolerance)**
- Cassandra (with eventual consistency)
- DynamoDB (with eventual consistency)
- CouchDB
- Trade-off: May serve stale data

**CA (Consistency + Availability)**
- Traditional RDBMS (single node)
- Not viable for distributed systems

### Practical Implications

**Choose CP when**:
- Data consistency is critical (financial transactions)
- Can tolerate downtime
- Strong ACID requirements

**Choose AP when**:
- Availability is critical (social media feeds)
- Can tolerate eventual consistency
- Need high write throughput

---

## Best Practices

### General NoSQL Best Practices

1. **Choose the Right Database**:
   - Document: Flexible schemas, nested data
   - Key-Value: Caching, session management
   - Wide-Column: Time-series, high write throughput
   - Search Engine: Full-text search, analytics

2. **Data Modeling**:
   - Design for access patterns, not normalization
   - Denormalize for read performance
   - Use appropriate data types
   - Consider data size limits

3. **Scaling**:
   - Plan for horizontal scaling from the start
   - Choose appropriate sharding/partitioning keys
   - Monitor data distribution
   - Test failover scenarios

4. **Performance**:
   - Implement proper indexing
   - Use connection pooling
   - Cache frequently accessed data
   - Monitor slow queries

5. **Operations**:
   - Implement automated backups
   - Monitor cluster health
   - Plan for disaster recovery
   - Test restore procedures
   - Keep software updated

6. **Security**:
   - Enable authentication and authorization
   - Use encryption in transit and at rest
   - Implement network security
   - Audit access logs
   - Follow principle of least privilege

### Migration Strategies

**From SQL to NoSQL**:
1. Identify access patterns
2. Design NoSQL schema based on queries
3. Implement dual-write during migration
4. Gradually shift reads to NoSQL
5. Decommission SQL after validation

**Polyglot Persistence**:
- Use multiple databases for different needs
- PostgreSQL for transactions
- MongoDB for flexible data
- Redis for caching
- Elasticsearch for search
- Cassandra for time-series

---

## Additional Resources

### Official Documentation
- MongoDB: https://docs.mongodb.com/
- Redis: https://redis.io/documentation
- Cassandra: https://cassandra.apache.org/doc/
- DynamoDB: https://docs.aws.amazon.com/dynamodb/
- Elasticsearch: https://www.elastic.co/guide/

### Learning Platforms
- MongoDB University: https://university.mongodb.com/
- Redis University: https://university.redis.com/
- DataStax Academy (Cassandra): https://www.datastax.com/dev/academy

### Books
- "MongoDB: The Definitive Guide" by Shannon Bradshaw
- "Redis in Action" by Josiah Carlson
- "Cassandra: The Definitive Guide" by Jeff Carpenter
- "NoSQL Distilled" by Martin Fowler

---

**Next**: [Query Optimization →](query-optimization.md)
