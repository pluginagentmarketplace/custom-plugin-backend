---
name: databases
description: Master relational and NoSQL databases. Learn PostgreSQL, MySQL, MongoDB, Redis, and other technologies for data persistence, optimization, and scaling.
sasmp_version: "1.3.0"
bonded_agent: database-management-agent
bond_type: PRIMARY_BOND
---

# Database Management Skill

**Bonded to:** `database-management-agent`

---

## Quick Start

```bash
# Example: Invoke databases skill
"Design a database schema for my e-commerce application"
```

---

## Instructions

1. **Analyze Requirements**: Understand data patterns and access needs
2. **Select Database**: Choose SQL vs NoSQL based on requirements
3. **Design Schema**: Create data models and relationships
4. **Optimize Queries**: Implement indexes and query optimization
5. **Set Up Operations**: Configure backup, replication, monitoring

---

## Database Selection Guide

| Type | Best For | Examples |
|------|----------|----------|
| Relational | ACID, Complex queries | PostgreSQL, MySQL |
| Document | Flexible schema | MongoDB |
| Key-Value | Caching, Sessions | Redis |
| Wide-Column | Time series | Cassandra |
| Search | Full-text search | Elasticsearch |

---

## Examples

### Example 1: Schema Design
```
Input: "Design schema for user authentication system"
Output: Users table with proper indexes, password hashing, session management
```

### Example 2: Query Optimization
```
Input: "My queries are slow on large table"
Output: Add appropriate indexes, use EXPLAIN ANALYZE, consider partitioning
```

---

## References

See `references/` directory for detailed documentation.
