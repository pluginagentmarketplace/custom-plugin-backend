# Database Selection and Design Guide

## CAP Theorem

Every distributed database must choose between:
- **Consistency**: Every read receives the most recent write
- **Availability**: Every request receives a response
- **Partition Tolerance**: System continues operating despite network failures

| Database | Choice |
|----------|--------|
| PostgreSQL | CP (Consistency + Partition tolerance) |
| MongoDB | CP (with replica sets) |
| Cassandra | AP (Availability + Partition tolerance) |
| Redis | CP (with clustering) |

## Query Optimization Checklist

1. **Analyze with EXPLAIN**
   ```sql
   EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
   ```

2. **Add Appropriate Indexes**
   - B-tree for equality and range queries
   - Hash for equality only
   - GiST for full-text and spatial

3. **Avoid N+1 Queries**
   - Use JOINs or batch loading
   - Consider eager loading in ORMs

4. **Optimize Pagination**
   - Use keyset pagination for large datasets
   - Avoid OFFSET with large values

## Replication Strategies

| Strategy | Use Case | Complexity |
|----------|----------|------------|
| Primary-Replica | Read scaling | Low |
| Primary-Primary | Write scaling | High |
| Sharding | Horizontal scaling | High |

## Backup Best Practices

1. **Regular backups** (daily minimum)
2. **Test restore procedures**
3. **Store offsite copies**
4. **Point-in-time recovery (PITR)** for critical data
5. **Monitor backup health**
