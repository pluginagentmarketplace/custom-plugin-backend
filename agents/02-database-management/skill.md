# Agent 2: Database Management

## Overview
This agent provides comprehensive training on database systems, covering both relational and NoSQL databases, query optimization, data modeling, and production operations. Database mastery is critical for backend developers as it directly impacts application performance, scalability, and data integrity.

## Agent Purpose
- Guide developers through database selection and design
- Establish proficiency in both SQL and NoSQL databases
- Master query optimization and performance tuning
- Implement production-ready backup and replication strategies
- Apply best practices for security and compliance

## Key Responsibilities

### 1. Relational Database Systems
- Master PostgreSQL, MySQL, MariaDB, and T-SQL
- Design normalized and denormalized schemas
- Implement ACID transactions and isolation levels
- Create and maintain optimal indexing strategies
- Configure replication and high availability

### 2. NoSQL Database Systems
- Understand different NoSQL paradigms (Document, Key-Value, Column-Family, Search)
- Master MongoDB for document storage
- Use Redis for caching and real-time operations
- Implement Cassandra for distributed data
- Leverage DynamoDB for serverless applications
- Apply Elasticsearch for full-text search

### 3. Query Optimization
- Analyze execution plans with EXPLAIN
- Design composite and partial indexes
- Optimize JOIN operations and subqueries
- Implement query caching strategies
- Monitor slow queries and bottlenecks

### 4. Data Modeling
- Design entity-relationship diagrams
- Apply normalization techniques (1NF through 5NF)
- Make strategic denormalization decisions
- Model for different NoSQL paradigms
- Handle schema migrations and versioning

### 5. Backup & Replication
- Implement comprehensive backup strategies
- Configure master-slave and multi-master replication
- Perform point-in-time recovery (PITR)
- Design disaster recovery plans
- Monitor replication lag and health

## Learning Progression

### Phase 1: Relational Database Foundations (3-4 weeks)
1. **Week 1**: PostgreSQL basics and SQL fundamentals
   - Installation and setup
   - Basic DDL and DML operations
   - Data types and constraints
   - Simple queries and joins

2. **Week 2**: Advanced SQL and transactions
   - Complex joins and subqueries
   - Common Table Expressions (CTEs)
   - Window functions
   - Transaction management and isolation levels

3. **Week 3**: MySQL/MariaDB and T-SQL
   - MySQL storage engines (InnoDB vs MyISAM)
   - MariaDB enhancements and Galera Cluster
   - T-SQL procedural programming
   - Stored procedures and triggers

4. **Week 4**: Indexing and performance
   - B-tree, hash, and specialized indexes
   - Composite and partial indexes
   - Query execution plans
   - Performance monitoring tools

### Phase 2: NoSQL Databases (2-3 weeks)
1. **Week 5**: Document databases (MongoDB)
   - Document-oriented data modeling
   - CRUD operations and aggregation pipeline
   - Indexing strategies for documents
   - Replica sets and sharding

2. **Week 6**: Key-value and wide-column stores
   - Redis data structures and use cases
   - Cassandra data modeling
   - Consistency levels and tuning
   - Time-series data patterns

3. **Week 7**: Search engines and cloud databases
   - Elasticsearch indexing and search
   - DynamoDB for serverless
   - Choosing the right database for use case
   - Polyglot persistence patterns

### Phase 3: Optimization & Operations (2-3 weeks)
1. **Week 8**: Query optimization deep-dive
   - EXPLAIN and ANALYZE commands
   - Index optimization strategies
   - N+1 query problems
   - Caching strategies

2. **Week 9**: Backup and replication
   - Full, incremental, and continuous backups
   - Streaming and logical replication
   - Failover and automatic recovery
   - Point-in-time recovery

3. **Week 10**: Production operations
   - Security and compliance (GDPR, HIPAA)
   - Monitoring and alerting
   - Capacity planning
   - Database migrations in production

## Database Selection Guide

### When to Use Relational Databases (PostgreSQL, MySQL)
✓ Complex queries with multiple JOINs
✓ ACID compliance required
✓ Structured data with well-defined schema
✓ Financial transactions and e-commerce
✓ Traditional CRUD applications
✓ Strong consistency requirements

**Best for**: Banking systems, ERP, CMS, E-commerce platforms

### When to Use Document Databases (MongoDB)
✓ Flexible schema requirements
✓ Nested and hierarchical data
✓ Rapid development and prototyping
✓ Content management systems
✓ User profiles and catalogs
✓ Real-time analytics

**Best for**: Mobile apps, IoT data, Product catalogs, CMS

### When to Use Key-Value Stores (Redis)
✓ Session management
✓ Caching layer
✓ Real-time leaderboards
✓ Rate limiting
✓ Pub/Sub messaging
✓ Temporary data with TTL

**Best for**: Caching, Session storage, Real-time analytics

### When to Use Wide-Column Stores (Cassandra)
✓ Massive write throughput
✓ Time-series data
✓ No single point of failure
✓ Linear scalability
✓ Multi-datacenter replication
✓ Distributed data

**Best for**: IoT platforms, Time-series data, Event logging

### When to Use Search Engines (Elasticsearch)
✓ Full-text search requirements
✓ Log aggregation and analysis
✓ Real-time analytics
✓ Geospatial search
✓ Auto-completion
✓ Complex aggregations

**Best for**: Search features, Log analysis (ELK stack), APM

### When to Use Cloud-Native Databases (DynamoDB)
✓ Serverless architecture
✓ Variable workloads
✓ Global distribution
✓ Single-digit millisecond latency
✓ Managed service benefits
✓ Auto-scaling requirements

**Best for**: Serverless apps, Gaming, Mobile backends, IoT

## Core Competencies

### SQL Mastery
- Write complex queries with CTEs and window functions
- Optimize queries using execution plans
- Design efficient schemas
- Implement transactions correctly
- Use prepared statements for security

### NoSQL Data Modeling
- Choose appropriate database type for use case
- Design schemas based on access patterns
- Balance consistency vs availability (CAP theorem)
- Implement proper indexing
- Handle eventual consistency

### Performance Optimization
- Identify and fix slow queries
- Design optimal indexing strategies
- Implement caching layers
- Configure connection pooling
- Monitor database metrics

### Production Operations
- Implement automated backups
- Configure replication and failover
- Perform zero-downtime migrations
- Monitor and alert on issues
- Plan for disaster recovery

## Tools & Technologies Covered

### Relational Databases
- **PostgreSQL 16+** - Advanced open-source RDBMS
- **MySQL 8.0+** - Popular web-scale database
- **MariaDB 11+** - MySQL fork with enhancements
- **Microsoft SQL Server** - Enterprise T-SQL database

### NoSQL Databases
- **MongoDB 7.0+** - Document database
- **Redis 7.x** - In-memory key-value store
- **Apache Cassandra 4.x** - Wide-column store
- **DynamoDB** - AWS managed NoSQL
- **Elasticsearch 8.x** - Search and analytics engine

### Database Tools
- **DBeaver** - Universal database client
- **pgAdmin** - PostgreSQL administration
- **MySQL Workbench** - MySQL visual tool
- **MongoDB Compass** - MongoDB GUI
- **Redis Insight** - Redis management
- **DataGrip** - JetBrains database IDE

### Migration Tools
- **Flyway** - Database migration tool
- **Liquibase** - Database schema change management
- **Alembic** - Python migrations
- **Sequelize** - Node.js ORM with migrations
- **Rails Migrations** - Ruby on Rails

### Monitoring Tools
- **pg_stat_statements** - PostgreSQL query monitoring
- **Percona Monitoring** - MySQL monitoring
- **MongoDB Atlas** - Cloud database monitoring
- **Prometheus + Grafana** - Metrics visualization
- **DataDog / New Relic** - Application monitoring

### Backup Tools
- **pg_dump / pg_basebackup** - PostgreSQL backups
- **mysqldump / Percona XtraBackup** - MySQL backups
- **mongodump** - MongoDB backups
- **WAL-E / WAL-G** - Continuous archiving
- **Cloud provider snapshots** - EBS, managed services

## Hands-On Projects

### Project 1: E-Commerce Database Design (PostgreSQL)
**Duration**: 16 hours
**Objectives**:
- Design normalized schema for users, products, orders, payments
- Implement complex queries with JOINs
- Create indexes for common query patterns
- Add constraints for data integrity
- Implement audit trail with triggers

**Technologies**: PostgreSQL, SQL, psql

### Project 2: Social Media API with MongoDB
**Duration**: 12 hours
**Objectives**:
- Model users, posts, comments, and relationships
- Implement aggregation pipeline for feeds
- Design indexes for query performance
- Configure replica set
- Implement change streams for real-time updates

**Technologies**: MongoDB, Aggregation Framework, Replica Sets

### Project 3: Caching Layer with Redis
**Duration**: 8 hours
**Objectives**:
- Implement cache-aside pattern
- Use Redis data structures (strings, hashes, sets)
- Configure TTL for cache expiration
- Implement rate limiting
- Build leaderboard with sorted sets

**Technologies**: Redis, Redis CLI, Node.js/Python client

### Project 4: Query Optimization Challenge
**Duration**: 10 hours
**Objectives**:
- Analyze slow queries with EXPLAIN ANALYZE
- Design optimal indexes
- Refactor N+1 queries
- Implement query result caching
- Measure performance improvements

**Technologies**: PostgreSQL/MySQL, EXPLAIN, monitoring tools

### Project 5: High Availability Setup
**Duration**: 12 hours
**Objectives**:
- Configure PostgreSQL streaming replication
- Set up automatic failover
- Implement point-in-time recovery
- Test disaster recovery procedures
- Monitor replication lag

**Technologies**: PostgreSQL, Patroni/repmgr, pgBouncer

### Project 6: Multi-Database Microservices
**Duration**: 16 hours
**Objectives**:
- Design polyglot persistence architecture
- Use PostgreSQL for transactions
- Use MongoDB for user profiles
- Use Redis for caching
- Use Elasticsearch for search
- Implement data consistency patterns

**Technologies**: PostgreSQL, MongoDB, Redis, Elasticsearch, Docker

## Assessment Criteria

### Database Design & Modeling (25%)
- Design normalized schemas avoiding anomalies
- Make informed denormalization decisions
- Choose appropriate data types
- Implement proper constraints
- Create entity-relationship diagrams

### SQL & Query Proficiency (25%)
- Write complex queries efficiently
- Use CTEs and window functions
- Optimize query performance
- Understand execution plans
- Implement transactions correctly

### NoSQL Implementation (20%)
- Choose appropriate NoSQL database
- Model data for access patterns
- Implement proper indexing
- Configure replication
- Handle eventual consistency

### Performance Optimization (15%)
- Analyze and optimize slow queries
- Design effective indexing strategies
- Implement caching solutions
- Monitor database metrics
- Tune database configuration

### Production Operations (15%)
- Implement backup and recovery
- Configure replication and HA
- Perform zero-downtime migrations
- Implement security best practices
- Monitor and troubleshoot issues

## Success Metrics

Upon completion, you should be able to:

✓ **Design robust database schemas** for complex applications
✓ **Write optimized SQL queries** with advanced features
✓ **Choose the right database** for specific use cases
✓ **Implement and query NoSQL databases** effectively
✓ **Optimize query performance** using execution plans and indexes
✓ **Configure database replication** for high availability
✓ **Implement comprehensive backup strategies** with PITR
✓ **Perform database migrations** safely in production
✓ **Monitor database health** and troubleshoot issues
✓ **Apply security best practices** and compliance requirements
✓ **Scale databases** horizontally and vertically
✓ **Design for polyglot persistence** in microservices

## Best Practices Summary

### Schema Design
- Normalize to 3NF for OLTP, denormalize for analytics
- Use surrogate keys (auto-increment or UUID)
- Implement foreign key constraints
- Add indexes on foreign keys and frequent WHERE columns
- Use appropriate data types (smallest that works)
- Document schema decisions and relationships

### Query Writing
- Select only needed columns (avoid SELECT *)
- Use prepared statements to prevent SQL injection
- Implement pagination for large result sets
- Use EXISTS instead of COUNT when checking existence
- Avoid functions on indexed columns in WHERE clauses
- Use UNION ALL instead of UNION when duplicates are acceptable

### Performance
- Create indexes based on query patterns
- Use composite indexes for multi-column queries
- Monitor slow query logs
- Implement connection pooling
- Use caching for frequently accessed data
- Partition large tables by date or range

### Operations
- Automate backups and test recovery regularly
- Configure replication for high availability
- Monitor key metrics (connections, slow queries, replication lag)
- Use transactions for multi-step operations
- Implement proper error handling and retries
- Plan for zero-downtime deployments

### Security
- Use strong passwords and rotate regularly
- Apply principle of least privilege
- Enable SSL/TLS for connections
- Encrypt sensitive data at rest
- Audit database access logs
- Keep database software updated

## Common Pitfalls to Avoid

❌ **Over-indexing** - Too many indexes slow down writes
❌ **N+1 queries** - Loading related data in loops
❌ **Missing transactions** - Data inconsistency in multi-step operations
❌ **Ignoring EXPLAIN** - Not analyzing query performance
❌ **No backup testing** - Backups that can't be restored
❌ **Wrong database choice** - Using SQL for document data or vice versa
❌ **Premature optimization** - Optimizing before identifying bottlenecks
❌ **Ignoring replication lag** - Reading stale data from replicas
❌ **SQL injection** - Not using prepared statements
❌ **No monitoring** - Running blind in production

## Resources & References

### Official Documentation
- PostgreSQL: https://www.postgresql.org/docs/
- MySQL: https://dev.mysql.com/doc/
- MongoDB: https://docs.mongodb.com/
- Redis: https://redis.io/documentation
- Elasticsearch: https://www.elastic.co/guide/

### Essential Books
- "Designing Data-Intensive Applications" by Martin Kleppmann
- "Database Internals" by Alex Petrov
- "SQL Performance Explained" by Markus Winand
- "Seven Databases in Seven Weeks" by Eric Redmond
- "High Performance MySQL" by Baron Schwartz

### Online Learning
- PostgreSQL Tutorial: https://www.postgresqltutorial.com/
- MongoDB University: https://university.mongodb.com/
- Redis University: https://university.redis.com/
- Use The Index, Luke: https://use-the-index-luke.com/
- SQLBolt: https://sqlbolt.com/

### Practice Platforms
- LeetCode Database: https://leetcode.com/problemset/database/
- HackerRank SQL: https://www.hackerrank.com/domains/sql
- Mode Analytics SQL Tutorial: https://mode.com/sql-tutorial/
- PostgreSQL Exercises: https://pgexercises.com/

### Communities
- Stack Overflow (database tags)
- Reddit: r/database, r/PostgreSQL, r/mongodb
- PostgreSQL Slack/Discord
- MongoDB Community Forums
- Database Administrators Stack Exchange

## Next Steps

After mastering database management, proceed to:
- **Agent 3: API Development** - Build RESTful and GraphQL APIs
- **Agent 4: Architecture & Design Patterns** - Design scalable systems
- **Agent 5: Testing & Security** - Implement comprehensive testing and security

The database skills learned here will be applied throughout all subsequent agents, making this a critical foundation for backend development mastery.

## Skill Files

Detailed documentation for each skill area:

1. **[Relational Databases](skills/relational-databases.md)** - PostgreSQL, MySQL, MariaDB, T-SQL with detailed features and best practices
2. **[NoSQL Databases](skills/nosql-databases.md)** - MongoDB, Redis, Cassandra, DynamoDB, Elasticsearch with comparisons
3. **[Query Optimization](skills/query-optimization.md)** - Query optimization, indexing strategies, execution plans
4. **[Backup & Replication](skills/backup-replication.md)** - Backup strategies, replication patterns, disaster recovery

---

**Agent Status**: Core backend development skill
**Estimated Completion Time**: 8-10 weeks (full-time) or 16-20 weeks (part-time)
**Difficulty Level**: Intermediate to Advanced
**Prerequisites**: Programming fundamentals from Agent 1
