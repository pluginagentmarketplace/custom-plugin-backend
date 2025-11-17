# Caching Strategies & Patterns

## Overview

Caching strategies define different patterns for managing data flow between application, cache, and database to optimize performance and consistency. Selecting the right caching strategy is crucial for balancing performance, consistency, and resource efficiency.

## Table of Contents

1. [Core Caching Strategies](#core-caching-strategies)
2. [Strategy Selection Framework](#strategy-selection-framework)
3. [Cache Invalidation Techniques](#cache-invalidation-techniques)
4. [TTL Configuration](#ttl-configuration)
5. [Eviction Policies](#eviction-policies)
6. [Implementation Patterns](#implementation-patterns)

---

## Core Caching Strategies

### 1. Cache-Aside (Lazy Loading)

**Alternative Names:** Lazy Loading, Lazy Population

#### Flow Diagram
```
┌─────────────┐
│ Application │
└──────┬──────┘
       │
       ├─── 1. Check Cache ────────┐
       │                           ▼
       │                    ┌──────────┐
       │                    │  Cache   │
       │                    └─────┬────┘
       │                          │
       │                    2a. HIT: Return Data
       │                    2b. MISS: Continue
       │                          │
       ├─── 3. Query Database ────┼────┐
       │                          │    ▼
       │                          │  ┌──────────┐
       │                          │  │ Database │
       │                          │  └────┬─────┘
       │                          │       │
       ├─── 4. Populate Cache ◄───┼───────┘
       │                          │
       └─── 5. Return Data ◄──────┘
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Loading Strategy** | Reactive/Lazy |
| **Consistency** | Eventual consistency |
| **Cache Population** | On-demand |
| **Application Involvement** | High - app manages both cache and DB |
| **Write Pattern** | Direct to database, cache updated separately |

#### Implementation Example (Node.js/Redis)

```javascript
class CacheAsideService {
  constructor(redisClient, database) {
    this.cache = redisClient;
    this.db = database;
  }

  async getUserById(userId) {
    const cacheKey = `user:${userId}`;

    // 1. Check cache first
    let user = await this.cache.get(cacheKey);

    if (user) {
      // 2a. Cache HIT - return cached data
      console.log('Cache HIT');
      return JSON.parse(user);
    }

    // 2b. Cache MISS - query database
    console.log('Cache MISS');
    user = await this.db.query('SELECT * FROM users WHERE id = ?', [userId]);

    if (user) {
      // 3. Populate cache with TTL
      await this.cache.setex(
        cacheKey,
        3600, // TTL: 1 hour
        JSON.stringify(user)
      );
    }

    // 4. Return data
    return user;
  }

  async updateUser(userId, userData) {
    // Update database first
    await this.db.query('UPDATE users SET ? WHERE id = ?', [userData, userId]);

    // Invalidate cache
    await this.cache.del(`user:${userId}`);

    // Next read will repopulate cache
  }
}
```

#### Advantages

- ✅ **Cost-Effective**: Cache contains only requested data
- ✅ **Resilient**: Can still access database if cache fails
- ✅ **Simple**: Easy to implement and understand
- ✅ **Immediate Benefits**: Performance improvement from day one
- ✅ **Flexible**: Works with any data model
- ✅ **Manageable Size**: Cache doesn't grow unbounded

#### Disadvantages

- ❌ **Initial Penalty**: Cache miss incurs database query
- ❌ **Multiple Round Trips**: Cache check + DB query + cache write
- ❌ **Potential Staleness**: Cache may not reflect latest data
- ❌ **TTL Management**: Requires careful TTL configuration
- ❌ **Three-Step Process**: More complex than simple read

#### Best Use Cases

- Read-heavy workloads
- General-purpose caching needs
- Applications requiring cost-effective caching
- Systems where cache failures must be tolerated
- Product catalogs
- User profiles
- Configuration data

#### Performance Metrics

```
Cache Hit Reduction: 50-70% reduction in backend load
Latency Improvement: 10-100x faster than database queries
Cost Savings: Significant reduction in database compute costs
```

---

### 2. Read-Through

#### Flow Diagram
```
┌─────────────┐
│ Application │
└──────┬──────┘
       │
       └─── 1. Request Data ───────┐
                                   ▼
                            ┌─────────────┐
                            │ Cache Layer │
                            └──────┬──────┘
                                   │
                            2a. HIT: Return Data
                            2b. MISS: Load from DB
                                   │
                            ┌──────▼──────┐
                            │  Database   │
                            └──────┬──────┘
                                   │
                            3. Cache populates itself
                                   │
                            4. Return Data
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Loading Strategy** | Automatic |
| **Consistency** | Cache-managed |
| **Cache Population** | Automatic on miss |
| **Application Involvement** | Low - app only talks to cache |

#### Implementation Pattern (Python)

```python
from functools import wraps
import redis
import json

class ReadThroughCache:
    def __init__(self, redis_client, default_ttl=3600):
        self.cache = redis_client
        self.default_ttl = default_ttl

    def read_through(self, key_prefix, ttl=None):
        """Decorator for read-through caching"""
        def decorator(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                # Generate cache key from function arguments
                cache_key = f"{key_prefix}:{self._serialize_args(args, kwargs)}"

                # Try to get from cache
                cached_value = self.cache.get(cache_key)
                if cached_value:
                    return json.loads(cached_value)

                # Cache miss - execute function (loads from DB)
                result = func(*args, **kwargs)

                # Populate cache
                if result is not None:
                    self.cache.setex(
                        cache_key,
                        ttl or self.default_ttl,
                        json.dumps(result)
                    )

                return result
            return wrapper
        return decorator

    def _serialize_args(self, args, kwargs):
        # Simple serialization of arguments
        return f"{args}:{sorted(kwargs.items())}"

# Usage
cache = ReadThroughCache(redis.Redis())

@cache.read_through('user', ttl=7200)
def get_user_by_id(user_id):
    # This function is only called on cache miss
    return database.query("SELECT * FROM users WHERE id = ?", user_id)

# Application code
user = get_user_by_id(123)  # Automatically caches
```

#### Advantages

- ✅ **Simplified Logic**: Application doesn't manage cache
- ✅ **Consistent Behavior**: Caching is transparent
- ✅ **Centralized Management**: Cache logic in one place
- ✅ **Abstraction**: Cache layer handles DB access

#### Disadvantages

- ❌ **Initial Read Penalty**: First access is slow
- ❌ **First-Time Misses**: Cold start performance
- ❌ **Infrastructure Requirement**: Cache must handle DB queries
- ❌ **Potential Staleness**: Without write-through

#### Best Combined With

**Write-Through** for complete consistency

---

### 3. Write-Through

#### Flow Diagram
```
┌─────────────┐
│ Application │
└──────┬──────┘
       │
       └─── 1. Write Data ─────────┐
                                   ▼
                            ┌─────────────┐
                            │    Cache    │
                            └──────┬──────┘
                                   │
                         2. Cache writes to DB
                         (Synchronously)
                                   │
                            ┌──────▼──────┐
                            │  Database   │
                            └──────┬──────┘
                                   │
                         3. DB write completes
                                   │
                         4. Cache acknowledges
                                   │
                         Data immediately available
                         for reads from cache
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Loading Strategy** | Proactive |
| **Consistency** | Strong consistency |
| **Synchronization** | Synchronous |
| **Write Latency** | Higher (waits for DB) |

#### Implementation (Go)

```go
package cache

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/go-redis/redis/v8"
)

type WriteThroughCache struct {
    redis    *redis.Client
    database Database
    ttl      time.Duration
}

func NewWriteThroughCache(r *redis.Client, db Database, ttl time.Duration) *WriteThroughCache {
    return &WriteThroughCache{
        redis:    r,
        database: db,
        ttl:      ttl,
    }
}

func (c *WriteThroughCache) Set(ctx context.Context, key string, value interface{}) error {
    // 1. Write to database first (ensure data durability)
    if err := c.database.Write(ctx, key, value); err != nil {
        return fmt.Errorf("database write failed: %w", err)
    }

    // 2. Write to cache (synchronously)
    data, err := json.Marshal(value)
    if err != nil {
        // Database has data, cache write failed - log but don't fail
        // Consider cache invalidation here
        return fmt.Errorf("cache serialization failed: %w", err)
    }

    if err := c.redis.Set(ctx, key, data, c.ttl).Err(); err != nil {
        // Database has data, cache write failed
        // Application continues, but cache won't be populated
        return fmt.Errorf("cache write failed: %w", err)
    }

    // 3. Both writes succeeded - data is consistent
    return nil
}

func (c *WriteThroughCache) Get(ctx context.Context, key string, dest interface{}) error {
    // Always try cache first
    data, err := c.redis.Get(ctx, key).Bytes()
    if err == redis.Nil {
        // Cache miss - load from database
        if err := c.database.Read(ctx, key, dest); err != nil {
            return err
        }

        // Populate cache
        cacheData, _ := json.Marshal(dest)
        c.redis.Set(ctx, key, cacheData, c.ttl)
        return nil
    }

    if err != nil {
        return err
    }

    return json.Unmarshal(data, dest)
}

// Usage Example
func main() {
    cache := NewWriteThroughCache(redisClient, db, 1*time.Hour)

    // Write operation
    user := User{ID: 123, Name: "John"}
    if err := cache.Set(ctx, "user:123", user); err != nil {
        // Handle error - database may or may not have data
    }

    // Read operation (immediately available from cache)
    var retrievedUser User
    cache.Get(ctx, "user:123", &retrievedUser)
}
```

#### Advantages

- ✅ **Strong Consistency**: Cache always matches database
- ✅ **No Invalidation Needed**: Updates go through cache
- ✅ **High Hit Rates**: Written data immediately cached
- ✅ **Read Optimization**: Faster reads after write

#### Disadvantages

- ❌ **Write Latency**: Must wait for both cache and DB writes
- ❌ **Larger Cache**: All writes cached, even infrequently read
- ❌ **Complexity**: More complex error handling
- ❌ **Cost**: Higher cache storage costs

#### Best Use Cases

- Mixed read/write workloads
- Data consistency is critical
- Frequently accessed data after writes
- Financial transactions
- User session data

#### Performance Impact

```
Write Latency: +10-50ms (cache + database)
Read Performance: 30% reduction in latency
Consistency: 100% (strong consistency)
```

---

### 4. Write-Behind (Write-Back)

#### Flow Diagram
```
┌─────────────┐
│ Application │
└──────┬──────┘
       │
       └─── 1. Write Data ─────────┐
                                   ▼
                            ┌─────────────┐
                            │    Cache    │
                            └──────┬──────┘
                                   │
                         2. Cache ACKs immediately
                                   │
                         3. Async write to DB
                         (Background process)
                                   │
                            ┌──────▼──────┐
                            │  Database   │
                            └─────────────┘

                         4. DB writes batched/delayed
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Loading Strategy** | Proactive |
| **Consistency** | Eventual consistency |
| **Synchronization** | Asynchronous |
| **Write Latency** | Very low |
| **Risk** | Potential data loss on cache failure |

#### Implementation (Java with Spring)

```java
package com.example.cache;

import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import java.util.concurrent.*;
import java.util.ArrayList;
import java.util.List;

@Service
public class WriteBehindCache {
    private final RedisTemplate<String, Object> redisTemplate;
    private final DatabaseService database;
    private final BlockingQueue<WriteOperation> writeQueue;
    private final ScheduledExecutorService executor;

    // Configuration
    private static final int QUEUE_SIZE = 10000;
    private static final int BATCH_SIZE = 100;
    private static final long FLUSH_INTERVAL_MS = 5000; // 5 seconds

    public WriteBehindCache(RedisTemplate<String, Object> redisTemplate,
                           DatabaseService database) {
        this.redisTemplate = redisTemplate;
        this.database = database;
        this.writeQueue = new LinkedBlockingQueue<>(QUEUE_SIZE);
        this.executor = Executors.newScheduledThreadPool(2);

        // Start background flush worker
        startFlushWorker();
    }

    /**
     * Write operation - returns immediately after cache write
     */
    public CompletableFuture<Void> write(String key, Object value) {
        return CompletableFuture.runAsync(() -> {
            try {
                // 1. Write to cache immediately
                redisTemplate.opsForValue().set(key, value);

                // 2. Queue database write (async)
                WriteOperation op = new WriteOperation(key, value, System.currentTimeMillis());
                if (!writeQueue.offer(op, 100, TimeUnit.MILLISECONDS)) {
                    // Queue full - flush immediately
                    flushToDatabase(new ArrayList<>(writeQueue));
                    writeQueue.clear();
                    writeQueue.offer(op);
                }

                // 3. Return immediately
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Write operation interrupted", e);
            }
        });
    }

    /**
     * Background worker to flush writes to database
     */
    private void startFlushWorker() {
        executor.scheduleAtFixedRate(() -> {
            try {
                List<WriteOperation> batch = new ArrayList<>();
                writeQueue.drainTo(batch, BATCH_SIZE);

                if (!batch.isEmpty()) {
                    flushToDatabase(batch);
                }
            } catch (Exception e) {
                // Log error, retry logic
                System.err.println("Flush error: " + e.getMessage());
            }
        }, FLUSH_INTERVAL_MS, FLUSH_INTERVAL_MS, TimeUnit.MILLISECONDS);
    }

    /**
     * Batch write to database
     */
    @Async
    protected void flushToDatabase(List<WriteOperation> operations) {
        try {
            database.batchWrite(operations);
        } catch (Exception e) {
            // Critical: Write to persistent queue for retry
            persistToRecoveryQueue(operations);
            throw new RuntimeException("Database write failed", e);
        }
    }

    /**
     * Persist failed writes for recovery
     */
    private void persistToRecoveryQueue(List<WriteOperation> operations) {
        // Write to disk-based queue or dead-letter queue
        // Ensures no data loss on failure
    }

    /**
     * Graceful shutdown - flush all pending writes
     */
    public void shutdown() {
        try {
            executor.shutdown();
            if (!executor.awaitTermination(30, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }

            // Flush remaining writes
            List<WriteOperation> remaining = new ArrayList<>(writeQueue);
            if (!remaining.isEmpty()) {
                flushToDatabase(remaining);
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }

    static class WriteOperation {
        String key;
        Object value;
        long timestamp;

        WriteOperation(String key, Object value, long timestamp) {
            this.key = key;
            this.value = value;
            this.timestamp = timestamp;
        }
    }
}
```

#### Advantages

- ✅ **Best Write Performance**: Immediate acknowledgment
- ✅ **Reduced Write Latency**: No DB wait time
- ✅ **Write Batching**: Efficient database updates
- ✅ **Burst Handling**: Can handle write spikes
- ✅ **Database Load Reduction**: Fewer, larger writes

#### Disadvantages

- ❌ **Data Loss Risk**: Cache failure before DB write
- ❌ **Complex Implementation**: Requires queue management
- ❌ **Eventual Consistency**: Temporary DB lag
- ❌ **Recovery Complexity**: Must handle failed writes

#### Best Use Cases

- Write-heavy workloads
- Applications prioritizing write performance
- Systems tolerating eventual consistency
- Bursty write patterns
- Analytics and logging systems
- Real-time leaderboards

#### Implementation Requirements

```yaml
Required Components:
  - Persistent cache (Redis with AOF/RDB)
  - Write queue (in-memory + disk backup)
  - Background flush worker
  - Retry mechanism
  - Monitoring of queue depth
  - Graceful shutdown handling

Monitoring Metrics:
  - Queue depth
  - Flush rate
  - Failed writes
  - DB lag time
```

---

### 5. Write-Around

#### Flow Diagram
```
┌─────────────┐
│ Application │
└──────┬──────┘
       │
       └─── Write ────────┐
                          │
                   ┌──────▼──────┐
                   │  Database   │
                   └─────────────┘

       Cache NOT updated during write

       Next read loads data to cache
```

#### Characteristics

| Aspect | Details |
|--------|---------|
| **Write Path** | Direct to database |
| **Cache Population** | On first read after write |
| **Cache Pollution** | Minimized |

#### Implementation (Python)

```python
class WriteAroundCache:
    def __init__(self, cache, database):
        self.cache = cache
        self.db = database

    def write(self, key, value):
        """Write directly to database, bypass cache"""
        # Write to database only
        self.db.write(key, value)

        # Optionally: Invalidate cache if exists
        self.cache.delete(key)

        # Cache will be populated on next read

    def read(self, key):
        """Read with cache-aside pattern"""
        # Check cache
        value = self.cache.get(key)
        if value:
            return value

        # Cache miss - read from database
        value = self.db.read(key)

        # Populate cache
        if value:
            self.cache.set(key, value, ttl=3600)

        return value
```

#### Advantages

- ✅ **Prevents Cache Pollution**: Write-once data not cached
- ✅ **Fast Writes**: No cache overhead
- ✅ **Smaller Cache**: Only frequently read data cached

#### Disadvantages

- ❌ **Read Miss After Write**: First read is slow
- ❌ **Potential Staleness**: Until cache refresh

#### Best Use Cases

- Write-heavy, infrequent-read scenarios
- Log data and audit trails
- Archive data
- Write-once, read-rarely data

---

### 6. Refresh-Ahead

#### Flow Diagram
```
┌─────────────┐
│ Application │
└──────┬──────┘
       │
       └─── Read ─────────┐
                          ▼
                   ┌─────────────┐
                   │    Cache    │
                   └──────┬──────┘
                          │
                   Monitor access patterns
                   Predict future needs
                   Refresh before expiry
                          │
                   ┌──────▼──────┐
                   │  Database   │
                   └─────────────┘
```

#### Implementation Pattern

```javascript
class RefreshAheadCache {
  constructor(cache, db, options = {}) {
    this.cache = cache;
    this.db = db;
    this.refreshThreshold = options.refreshThreshold || 0.8; // Refresh at 80% TTL
    this.accessLog = new Map(); // Track access patterns
  }

  async get(key, ttl = 3600) {
    // Get from cache with TTL info
    const result = await this.cache.getWithTTL(key);

    if (result.value) {
      // Track access
      this.trackAccess(key);

      // Check if refresh needed
      const remainingTTL = result.ttl;
      const refreshTime = ttl * this.refreshThreshold;

      if (remainingTTL < refreshTime) {
        // Proactively refresh in background
        this.refreshAsync(key, ttl);
      }

      return result.value;
    }

    // Cache miss - load and cache
    return await this.loadAndCache(key, ttl);
  }

  async refreshAsync(key, ttl) {
    // Background refresh (non-blocking)
    setImmediate(async () => {
      try {
        const value = await this.db.read(key);
        await this.cache.set(key, value, ttl);
      } catch (error) {
        console.error(`Refresh failed for ${key}:`, error);
      }
    });
  }

  trackAccess(key) {
    const now = Date.now();
    const access = this.accessLog.get(key) || { count: 0, lastAccess: now };

    access.count++;
    access.lastAccess = now;
    this.accessLog.set(key, access);
  }

  async loadAndCache(key, ttl) {
    const value = await this.db.read(key);
    if (value) {
      await this.cache.set(key, value, ttl);
    }
    return value;
  }
}
```

#### Advantages

- ✅ **No Cache Miss Penalty**: Always fresh data
- ✅ **Consistent Low Latency**: Predictable performance
- ✅ **Improved User Experience**: No slowdowns

#### Disadvantages

- ❌ **Complex Implementation**: Prediction logic required
- ❌ **Unnecessary Refreshes**: May refresh unused data
- ❌ **Higher Resource Usage**: More database queries

#### Best Use Cases

- Predictable access patterns
- Frequently accessed data
- Applications requiring consistent low latency
- Real-time dashboards

---

## Strategy Selection Framework

### Decision Matrix

| Scenario | Recommended Strategy | Reasoning |
|----------|---------------------|-----------|
| **Read-Heavy, Infrequent Writes** | Cache-Aside | Cost-effective, simple |
| **Write-Heavy** | Write-Behind | Best write performance |
| **Strong Consistency Required** | Write-Through | Guaranteed consistency |
| **Mixed Read/Write** | Write-Through + Cache-Aside | Balance consistency and performance |
| **Write-Once, Read-Rarely** | Write-Around | Prevents cache pollution |
| **Predictable Access** | Refresh-Ahead | Eliminates cache misses |
| **Cost Optimization** | Cache-Aside | Only cache what's needed |
| **Simple Implementation** | Cache-Aside | Easy to understand |

### Performance Comparison

```
Strategy           | Write Speed | Read Speed | Consistency | Complexity
-------------------|-------------|------------|-------------|------------
Cache-Aside        | Fast        | Fast       | Eventual    | Low
Read-Through       | N/A         | Fast       | Eventual    | Medium
Write-Through      | Slow        | Fast       | Strong      | Medium
Write-Behind       | Very Fast   | Fast       | Eventual    | High
Write-Around       | Fast        | Medium     | Eventual    | Low
Refresh-Ahead      | N/A         | Very Fast  | Eventual    | High
```

---

## Cache Invalidation Techniques

### 1. Time-Based (TTL)

```python
# Set TTL based on data change frequency
cache.setex('user:123', 3600, user_data)  # 1 hour

# Common TTL patterns
TTL_PATTERNS = {
    'static_assets': 31536000,      # 1 year
    'user_sessions': 1800,          # 30 minutes
    'api_responses': 300,           # 5 minutes
    'frequently_changing': 60,      # 1 minute
    'stable_data': 86400,           # 1 day
}
```

### 2. Event-Driven Invalidation

```javascript
// Using Redis Pub/Sub
class EventDrivenInvalidation {
  constructor(redis) {
    this.redis = redis;
    this.subscriber = redis.duplicate();

    // Subscribe to invalidation events
    this.subscriber.subscribe('cache:invalidate');
    this.subscriber.on('message', this.handleInvalidation.bind(this));
  }

  async invalidate(pattern) {
    // Delete from local cache
    await this.deletePattern(pattern);

    // Publish to other instances
    await this.redis.publish('cache:invalidate', JSON.stringify({ pattern }));
  }

  async handleInvalidation(channel, message) {
    const { pattern } = JSON.parse(message);
    await this.deletePattern(pattern);
  }

  async deletePattern(pattern) {
    const keys = await this.redis.keys(pattern);
    if (keys.length > 0) {
      await this.redis.del(...keys);
    }
  }
}
```

### 3. Version-Based Invalidation

```go
type VersionedCache struct {
    cache   *redis.Client
    version string
}

func (c *VersionedCache) Set(key string, value interface{}) error {
    versionedKey := fmt.Sprintf("%s:v%s:%s", c.version, getCurrentVersion(), key)
    return c.cache.Set(context.Background(), versionedKey, value, 0).Err()
}

// When deploying new version, old cache automatically becomes invalid
```

---

## TTL Configuration

### TTL Calculation Formula

```
TTL = Data_Change_Frequency × Safety_Multiplier

where:
  Data_Change_Frequency = How often data changes
  Safety_Multiplier = 0.5 to 0.8 (ensures refresh before stale)
```

### Dynamic TTL Strategy

```python
def calculate_dynamic_ttl(key, base_ttl=3600):
    """Calculate TTL based on access patterns"""
    access_freq = get_access_frequency(key)
    data_volatility = get_data_volatility(key)

    # High access frequency + low volatility = longer TTL
    if access_freq > 100 and data_volatility < 0.1:
        return base_ttl * 2

    # Low access frequency = shorter TTL
    if access_freq < 10:
        return base_ttl * 0.5

    # High volatility = shorter TTL
    if data_volatility > 0.5:
        return base_ttl * 0.3

    return base_ttl
```

---

## Eviction Policies

### LRU (Least Recently Used)

```
Configuration (Redis):
  maxmemory-policy allkeys-lru

When to Use:
  - Access patterns favor recent data
  - News feeds, social media
  - Time-sensitive data
```

### LFU (Least Frequently Used)

```
Configuration (Redis):
  maxmemory-policy allkeys-lfu

When to Use:
  - Consistently popular data
  - Product catalogs
  - Reference data
```

### Comparison

| Policy | Best For | Memory Efficiency | Adaptability |
|--------|----------|-------------------|--------------|
| **LRU** | Recent data | Good | High |
| **LFU** | Popular data | Better | Low |
| **TTL** | Time-sensitive | Best | Medium |
| **Random** | Uniform access | Poor | High |

---

## Implementation Patterns

### Multi-Layer Caching

```javascript
class MultiLayerCache {
  constructor() {
    this.l1 = new Map();           // In-memory (fast, small)
    this.l2 = redisClient;         // Redis (medium speed, larger)
    this.l3 = database;            // Database (slow, unlimited)
  }

  async get(key) {
    // L1: In-memory cache
    if (this.l1.has(key)) {
      return this.l1.get(key);
    }

    // L2: Redis cache
    let value = await this.l2.get(key);
    if (value) {
      this.l1.set(key, value);
      return value;
    }

    // L3: Database
    value = await this.l3.query(key);
    if (value) {
      await this.l2.set(key, value, 3600);
      this.l1.set(key, value);
    }

    return value;
  }
}
```

### Cache Stampede Prevention

```python
import asyncio
from asyncio import Lock

class StampedeProtection:
    def __init__(self, cache, db):
        self.cache = cache
        self.db = db
        self.locks = {}

    async def get(self, key):
        # Check cache
        value = await self.cache.get(key)
        if value:
            return value

        # Acquire lock for this key
        if key not in self.locks:
            self.locks[key] = Lock()

        async with self.locks[key]:
            # Double-check cache (another request may have loaded it)
            value = await self.cache.get(key)
            if value:
                return value

            # Load from database (only one request does this)
            value = await self.db.read(key)
            await self.cache.set(key, value, ttl=3600)

        return value
```

---

## Best Practices

1. **Start with Cache-Aside** - Simplest, most flexible
2. **Monitor Cache Hit Rates** - Target >80% hit rate
3. **Set Appropriate TTLs** - Balance freshness and efficiency
4. **Handle Cache Failures** - Always have database fallback
5. **Use Compression** - For large values
6. **Implement Monitoring** - Track cache metrics
7. **Test Invalidation** - Ensure data consistency
8. **Document Strategy** - Make caching patterns clear
9. **Avoid Over-Caching** - Cache what provides value
10. **Plan for Growth** - Consider scalability

---

## Performance Formulas

### Cache Hit Rate
```
Hit Rate = Cache Hits / (Cache Hits + Cache Misses) × 100%

Target: >80%
Excellent: >95%
```

### Response Time Improvement
```
Improvement = (DB_Time - Cache_Time) / DB_Time × 100%

Typical: 90-99% improvement
```

### Cost Savings
```
Cost Reduction = DB_Queries_Avoided × Cost_Per_Query

With 80% hit rate and 1M requests:
  Savings = 800,000 × $0.0001 = $80/day
```

---

## Summary

Caching strategies are foundational to backend performance optimization. Choose the right strategy based on:

- **Workload Type**: Read-heavy vs write-heavy
- **Consistency Requirements**: Strong vs eventual
- **Performance Priorities**: Read latency vs write latency
- **Complexity Tolerance**: Simple vs sophisticated
- **Cost Constraints**: Cache size and infrastructure

Start with **Cache-Aside** for most applications, evolve to more sophisticated strategies as needs grow.
