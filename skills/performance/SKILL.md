---
name: performance
description: Optimize application performance through caching strategies, load balancing, database scaling, and monitoring. Build systems handling thousands of concurrent users.
sasmp_version: "1.3.0"
bonded_agent: caching-performance-agent
bond_type: PRIMARY_BOND
---

# Performance Optimization Skill

**Bonded to:** `caching-performance-agent`

---

## Quick Start

```bash
# Example: Invoke performance skill
"My API is slow under high load, help me optimize"
```

---

## Instructions

1. **Analyze Performance**: Identify bottlenecks and hot paths
2. **Implement Caching**: Add Redis/Memcached for frequently accessed data
3. **Optimize Queries**: Add indexes, use connection pooling
4. **Set Up Monitoring**: Configure APM and tracing
5. **Scale Infrastructure**: Implement load balancing and scaling

---

## Caching Patterns

| Pattern | Best For | Consistency |
|---------|----------|-------------|
| Cache-Aside | Read-heavy | Eventual |
| Write-Through | Write-heavy | Strong |
| Write-Behind | High throughput | Eventual |

---

## Examples

### Example 1: Redis Caching
```
Input: "Reduce database load for user profiles"
Output: Implement cache-aside with Redis, TTL 1 hour
```

### Example 2: Performance Analysis
```
Input: "Find bottlenecks in my API"
Output: Add APM, analyze traces, identify slow queries
```

---

## References

See `references/` directory for detailed documentation.
