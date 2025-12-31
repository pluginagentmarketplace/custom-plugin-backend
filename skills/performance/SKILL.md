---
name: performance
description: Optimize application performance through caching strategies, load balancing, database scaling, and monitoring. Build systems handling thousands of concurrent users.
sasmp_version: "2.0.0"
bonded_agent: 05-caching-performance
bond_type: PRIMARY_BOND

# === PRODUCTION-GRADE SKILL CONFIG (SASMP v2.0.0) ===

atomic_operations:
  - BOTTLENECK_ANALYSIS
  - CACHE_IMPLEMENTATION
  - LOAD_BALANCING_CONFIG
  - SCALING_STRATEGY

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5
    maxLength: 2000
  current_rps:
    type: integer
    required: false
    description: "Current requests per second"
  target_latency_ms:
    type: integer
    required: false
    description: "Target P99 latency in milliseconds"

retry_logic:
  max_attempts: 3
  backoff: exponential
  initial_delay_ms: 1000

logging_hooks:
  on_invoke: "skill.performance.invoked"
  on_success: "skill.performance.completed"
  on_error: "skill.performance.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  METRICS_UNAVAILABLE: 2
  OPTIMIZATION_FAILED: 3
---

# Performance Optimization Skill

**Bonded to:** `caching-performance-agent`

---

## Quick Start

```bash
# Invoke performance skill
"My API is slow, help me optimize it"
"Set up Redis caching for my application"
"Configure load balancing for high availability"
```

---

## Instructions

1. **Identify Bottlenecks**: Profile application, analyze metrics
2. **Choose Strategy**: Select caching, scaling, or optimization approach
3. **Implement Cache**: Set up Redis/Memcached with appropriate pattern
4. **Configure Scaling**: Horizontal or vertical based on needs
5. **Monitor Results**: Set up APM and track improvements

---

## Caching Patterns

| Pattern | Use Case | Consistency | Complexity |
|---------|----------|-------------|------------|
| Cache-Aside | Read-heavy, tolerates stale | Eventual | Low |
| Write-Through | Write-heavy, needs consistency | Strong | Medium |
| Write-Behind | High throughput writes | Eventual | High |
| Refresh-Ahead | Predictable access | Strong | Medium |

---

## Decision Tree

```
Performance Issue?
    │
    ├─→ High latency → Check database queries
    │     ├─→ Slow queries → Add indexes, optimize SQL
    │     └─→ Network → Add caching, reduce round-trips
    │
    ├─→ High CPU → Profile code
    │     ├─→ Algorithmic → Optimize algorithms
    │     └─→ Too much load → Scale horizontally
    │
    └─→ Memory issues → Analyze memory usage
          ├─→ Leaks → Find and fix leaks
          └─→ Large data → Implement pagination, streaming
```

---

## Examples

### Example 1: Redis Cache-Aside
```python
import redis
import json
from functools import wraps

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def cache(ttl_seconds=3600):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = f"{func.__name__}:{args}:{kwargs}"
            cached = r.get(cache_key)
            if cached:
                return json.loads(cached)

            result = func(*args, **kwargs)
            r.setex(cache_key, ttl_seconds, json.dumps(result))
            return result
        return wrapper
    return decorator

@cache(ttl_seconds=300)
def get_expensive_data(user_id: str) -> dict:
    # Expensive database query or computation
    return {"user_id": user_id, "data": "..."}
```

### Example 2: Connection Pooling
```python
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=1800,
    pool_pre_ping=True
)
```

### Example 3: Load Balancing (nginx)
```nginx
upstream backend {
    least_conn;  # Least connections algorithm
    server backend1:8000 weight=3;
    server backend2:8000 weight=2;
    server backend3:8000 weight=1;

    keepalive 32;  # Connection pooling
}

server {
    location /api {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

---

## Performance Metrics

```
Latency Targets:
├── P50: < 50ms   (typical request)
├── P95: < 200ms  (most requests)
├── P99: < 500ms  (almost all)
└── P99.9: < 1s   (worst case)

Cache Metrics:
├── Hit Ratio: > 90% (ideal)
├── Eviction Rate: Low (stable)
└── Memory Usage: < 80% (headroom)

Database Metrics:
├── Connection Pool: < 80% utilized
├── Query Time: P95 < 100ms
└── Slow Queries: < 1% of total
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| High cache miss | Poor key design | Review key patterns |
| Cache stampede | Many misses at once | Use locks or jitter |
| Memory pressure | Over-caching | Set TTL, eviction policy |
| Connection timeout | Pool exhausted | Increase pool size |

### Debug Commands

```bash
# Redis stats
redis-cli INFO stats | grep -E 'keyspace|hits|misses'

# Memory usage
redis-cli INFO memory | grep used_memory_human

# Slow queries
redis-cli SLOWLOG GET 10

# Load test
wrk -t12 -c400 -d30s http://localhost/api
```

---

## Test Template

```python
# tests/test_performance.py
import pytest
import time

class TestCachePerformance:
    def test_cache_hit_is_fast(self, redis_client):
        # First call - cache miss
        start = time.time()
        result1 = get_cached_data("key1")
        cold_time = time.time() - start

        # Second call - cache hit
        start = time.time()
        result2 = get_cached_data("key1")
        warm_time = time.time() - start

        assert warm_time < cold_time * 0.1  # 10x faster
        assert result1 == result2

    def test_cache_ttl_expires(self, redis_client):
        set_cached_data("key", "value", ttl=1)
        time.sleep(2)
        assert get_cached_data("key") is None
```

---

## Resources

- [Redis Documentation](https://redis.io/documentation)
- [High Performance Browser Networking](https://hpbn.co/)
- [Systems Performance (Brendan Gregg)](https://www.brendangregg.com/)
