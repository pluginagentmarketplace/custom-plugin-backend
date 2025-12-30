---
name: databases
description: Master relational and NoSQL databases. Learn PostgreSQL, MySQL, MongoDB, Redis, and other technologies for data persistence, optimization, and scaling.
sasmp_version: "2.0.0"
bonded_agent: database-management-agent
bond_type: PRIMARY_BOND

# === PRODUCTION-GRADE SKILL CONFIG (SASMP v2.0.0) ===

atomic_operations:
  - DATABASE_SELECTION
  - SCHEMA_DESIGN
  - QUERY_OPTIMIZATION
  - BACKUP_CONFIGURATION

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5
    maxLength: 2000
  database_type:
    type: string
    enum: [postgresql, mysql, mongodb, redis, cassandra, elasticsearch]
    required: false
  operation:
    type: string
    enum: [design, optimize, backup, migrate]
    required: false

retry_logic:
  max_attempts: 3
  backoff: exponential
  initial_delay_ms: 2000

logging_hooks:
  on_invoke: "skill.databases.invoked"
  on_success: "skill.databases.completed"
  on_error: "skill.databases.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  CONNECTION_ERROR: 2
  QUERY_ERROR: 3
  OPTIMIZATION_FAILED: 4
---

# Database Management Skill

**Bonded to:** `database-management-agent`

---

## Quick Start

```bash
# Invoke databases skill
"Design a database schema for my e-commerce application"
"Optimize slow queries in PostgreSQL"
"Set up Redis caching for session storage"
```

---

## Instructions

1. **Analyze Requirements**: Understand data patterns, volume, access needs
2. **Select Database**: Choose SQL vs NoSQL based on requirements
3. **Design Schema**: Create data models, relationships, constraints
4. **Optimize Queries**: Implement indexes, analyze execution plans
5. **Set Up Operations**: Configure backup, replication, monitoring

---

## Database Selection Guide

| Type | Best For | ACID | Scale | Examples |
|------|----------|------|-------|----------|
| Relational | Complex queries, transactions | Full | Vertical | PostgreSQL, MySQL |
| Document | Flexible schema, JSON | Partial | Horizontal | MongoDB |
| Key-Value | Caching, sessions | No | Horizontal | Redis |
| Wide-Column | Time series, analytics | Partial | Horizontal | Cassandra |
| Graph | Relationships | Varies | Varies | Neo4j |
| Search | Full-text search | No | Horizontal | Elasticsearch |

---

## Decision Tree

```
Need ACID transactions?
    │
    ├─→ Yes → Complex queries?
    │           ├─→ Yes → PostgreSQL
    │           └─→ No  → MySQL
    │
    └─→ No  → Data type?
              ├─→ Documents/JSON → MongoDB
              ├─→ Key-Value pairs → Redis
              ├─→ Time series → Cassandra/TimescaleDB
              └─→ Full-text search → Elasticsearch
```

---

## Examples

### Example 1: Schema Design
```sql
-- E-commerce schema
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    total DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
```

### Example 2: Query Optimization
```sql
-- Before: Full table scan
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 'abc123';

-- After: Add index
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Optimized query with selected columns
SELECT id, total, status, created_at
FROM orders
WHERE user_id = 'abc123'
ORDER BY created_at DESC
LIMIT 10;
```

### Example 3: Redis Caching
```python
import redis
import json

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def get_user(user_id: str) -> dict:
    # Try cache first
    cached = r.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)

    # Cache miss - fetch from DB
    user = db.query(User).get(user_id)
    if user:
        r.setex(f"user:{user_id}", 3600, json.dumps(user.dict()))
    return user.dict()
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Query timeout | Missing index | Run EXPLAIN ANALYZE, add index |
| Connection refused | Wrong config | Check host, port, credentials |
| Deadlock | Concurrent updates | Use proper isolation, retry logic |
| OOM on query | Large result set | Add LIMIT, use cursors |

### Debug Commands

```sql
-- PostgreSQL: Check slow queries
SELECT query, calls, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC LIMIT 10;

-- Check active connections
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Check table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

---

## Test Template

```python
# tests/test_database.py
import pytest
from sqlalchemy import create_engine

class TestDatabaseSchema:
    @pytest.fixture
    def engine(self):
        return create_engine("postgresql://test:test@localhost/testdb")

    def test_users_table_exists(self, engine):
        result = engine.execute("SELECT 1 FROM users LIMIT 1")
        assert result is not None

    def test_foreign_key_constraint(self, engine):
        with pytest.raises(IntegrityError):
            engine.execute(
                "INSERT INTO orders (user_id, total) VALUES ('invalid-uuid', 100)"
            )
```

---

## References

See `references/` directory for:
- `DATABASE_GUIDE.md` - Detailed database patterns
- Schema templates and examples

---

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Manual](https://docs.mongodb.com/manual/)
- [Redis Documentation](https://redis.io/documentation)
- [Use The Index, Luke](https://use-the-index-luke.com/)
