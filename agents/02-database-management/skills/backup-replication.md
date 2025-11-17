# Backup & Replication

## Overview

Backup and replication are critical for data durability, high availability, and disaster recovery. Backups protect against data loss from hardware failures, software bugs, and human errors. Replication provides redundancy, enables read scaling, and reduces downtime. Together, they form the foundation of a production-ready database system.

## Table of Contents
1. [Backup Strategies](#backup-strategies)
2. [Backup Types](#backup-types)
3. [Point-in-Time Recovery](#point-in-time-recovery)
4. [Replication Patterns](#replication-patterns)
5. [High Availability](#high-availability)
6. [Disaster Recovery](#disaster-recovery)
7. [Database-Specific Implementations](#database-specific-implementations)
8. [Best Practices](#best-practices)

---

## Backup Strategies

### The 3-2-1 Rule

**3**: Keep three copies of your data
**2**: Store copies on two different media types
**1**: Keep one copy offsite

```
Example:
- Primary database (production)
- Local backup (same datacenter, different storage)
- Remote backup (different geographic region, cloud storage)
```

### Backup Frequency Planning

**RTO (Recovery Time Objective)**: How quickly you need to recover
**RPO (Recovery Point Objective)**: How much data loss is acceptable

```
Example Requirements:
- E-commerce site: RTO = 1 hour, RPO = 5 minutes
- Analytics dashboard: RTO = 4 hours, RPO = 1 day
- Blog: RTO = 1 day, RPO = 1 day

Backup Strategy Based on RPO:
- RPO < 5 minutes: Continuous backup (WAL archiving)
- RPO < 1 hour: Incremental backups every 15-30 minutes
- RPO < 1 day: Full backup daily, incremental hourly
- RPO >= 1 day: Full backup daily or weekly
```

### Backup Verification

```bash
# Always verify backups!

# 1. Test restore in non-production environment
pg_restore -d test_db backup.dump

# 2. Verify data integrity
SELECT COUNT(*) FROM users;
SELECT MAX(created_at) FROM orders;

# 3. Automated verification script
#!/bin/bash
BACKUP_FILE="backup_$(date +%Y%m%d).sql"
TEST_DB="backup_verification"

# Restore to test database
mysql $TEST_DB < $BACKUP_FILE

# Run verification queries
mysql $TEST_DB -e "
    SELECT 'Users' AS table_name, COUNT(*) AS count FROM users
    UNION ALL
    SELECT 'Orders', COUNT(*) FROM orders
    UNION ALL
    SELECT 'Products', COUNT(*) FROM products;
" | mail -s "Backup Verification Report" admin@example.com

# Cleanup
mysql -e "DROP DATABASE $TEST_DB;"
```

---

## Backup Types

### 1. Full Backup

Complete copy of entire database.

**Pros**:
- Simple to restore (single file)
- Fast restore
- Simplest to understand

**Cons**:
- Large storage requirement
- Long backup time for large databases
- Resource intensive

**When to use**:
- Small to medium databases
- As baseline for incremental/differential
- Weekly/monthly for large databases

```bash
# PostgreSQL full backup
pg_dump -h localhost -U postgres -d mydb > full_backup_$(date +%Y%m%d).sql

# MySQL full backup
mysqldump -u root -p mydb > full_backup_$(date +%Y%m%d).sql

# SQL Server full backup
BACKUP DATABASE MyDatabase TO DISK = 'C:\Backups\MyDatabase_Full.bak' WITH INIT;
```

### 2. Incremental Backup

Only data changed since last backup (full or incremental).

**Pros**:
- Small backup size
- Fast backup process
- Frequent backups possible

**Cons**:
- Complex restore (need all incrementals)
- Longer restore time
- If one incremental is corrupted, all subsequent backups unusable

**When to use**:
- Large databases with frequent changes
- Combined with weekly full backups
- When backup windows are limited

```bash
# PostgreSQL WAL archiving (incremental)
# postgresql.conf
archive_mode = on
archive_command = 'cp %p /backup/wal/%f'
wal_level = replica

# MySQL binary log (incremental)
# my.cnf
log-bin = /var/log/mysql/mysql-bin
expire_logs_days = 7
```

### 3. Differential Backup

Data changed since last full backup.

**Pros**:
- Faster restore than incremental (only need full + latest differential)
- Smaller than full backup
- Good balance between full and incremental

**Cons**:
- Larger than incremental
- Each differential grows over time

**When to use**:
- Medium to large databases
- Good compromise between full and incremental
- Daily backups with weekly full

```sql
-- SQL Server differential backup
BACKUP DATABASE MyDatabase
TO DISK = 'C:\Backups\MyDatabase_Diff.bak'
WITH DIFFERENTIAL;
```

### 4. Continuous Backup (Transaction Log Backup)

Real-time or near-real-time backup of transactions.

**Pros**:
- Minimal data loss (RPO in minutes or seconds)
- Point-in-time recovery
- Can replay transactions

**Cons**:
- Requires more storage
- More complex to manage
- Requires transaction log management

**When to use**:
- Critical data that can't be lost
- Compliance requirements
- Low RPO requirements

```bash
# PostgreSQL continuous archiving
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /backup/wal/%f && cp %p /backup/wal/%f'
archive_timeout = 60  # Force WAL switch every 60 seconds

# MySQL binary log backup
mysqldump --single-transaction --flush-logs --master-data=2 \
    -u root -p mydb > backup.sql

# Archive binary logs
mysqlbinlog mysql-bin.000001 > binlog_backup_000001.sql
```

---

## Point-in-Time Recovery

Point-in-Time Recovery (PITR) allows restoring database to a specific timestamp, useful for recovering from accidental data deletion or corruption.

### PostgreSQL PITR

```bash
# Setup
# 1. Enable WAL archiving in postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/wal/%f'
max_wal_senders = 3

# 2. Take base backup
pg_basebackup -h localhost -D /backup/base -U replicator -P -v --wal-method=stream

# 3. Create recovery.conf (PostgreSQL < 12) or recovery.signal (>= 12)
# recovery.conf
restore_command = 'cp /backup/wal/%f %p'
recovery_target_time = '2024-01-15 14:30:00'
# Or: recovery_target_xid = '12345'
# Or: recovery_target_name = 'before_drop_table'

# 4. Restore
# Stop PostgreSQL
systemctl stop postgresql

# Restore base backup
rm -rf /var/lib/postgresql/data/*
cp -r /backup/base/* /var/lib/postgresql/data/

# Create recovery configuration
# PostgreSQL 12+:
touch /var/lib/postgresql/data/recovery.signal
echo "restore_command = 'cp /backup/wal/%f %p'" >> postgresql.conf
echo "recovery_target_time = '2024-01-15 14:30:00'" >> postgresql.conf

# Start PostgreSQL (will recover to target time)
systemctl start postgresql

# Example: Restore to before accidental DELETE
# 1. Find transaction ID before DELETE
SELECT txid_current();  -- Returns: 123456

# Oops! Accidentally deleted data
DELETE FROM important_table WHERE id > 100;

# 2. Restore to before DELETE
# recovery.conf
restore_command = 'cp /backup/wal/%f %p'
recovery_target_xid = '123455'
recovery_target_inclusive = false
```

### MySQL PITR

```bash
# Setup
# 1. Enable binary logging in my.cnf
[mysqld]
log-bin = /var/log/mysql/mysql-bin
binlog_format = ROW
expire_logs_days = 7
server-id = 1

# 2. Take full backup with binary log position
mysqldump --single-transaction --flush-logs --master-data=2 \
    -u root -p mydb > backup_$(date +%Y%m%d).sql

# This includes: -- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000010', MASTER_LOG_POS=154;

# 3. Restore to point in time
# Step 1: Restore full backup
mysql -u root -p mydb < backup_20240115.sql

# Step 2: Find binary logs to replay
SHOW BINARY LOGS;

# Step 3: Replay binary logs up to incident time
mysqlbinlog --stop-datetime="2024-01-15 14:30:00" \
    /var/log/mysql/mysql-bin.000010 \
    /var/log/mysql/mysql-bin.000011 | mysql -u root -p mydb

# Example: Skip problematic transaction
# If you know the problematic transaction position
mysqlbinlog --stop-position=12345 /var/log/mysql/mysql-bin.000010 | mysql -u root -p
mysqlbinlog --start-position=12400 /var/log/mysql/mysql-bin.000010 | mysql -u root -p
```

### SQL Server PITR

```sql
-- Setup
-- 1. Set recovery model to FULL
ALTER DATABASE MyDatabase SET RECOVERY FULL;

-- 2. Take full backup
BACKUP DATABASE MyDatabase TO DISK = 'C:\Backups\Full.bak' WITH INIT;

-- 3. Take transaction log backups regularly
BACKUP LOG MyDatabase TO DISK = 'C:\Backups\Log1.trn' WITH INIT;

-- 4. Restore to point in time
-- Stop all connections
ALTER DATABASE MyDatabase SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- Restore full backup
RESTORE DATABASE MyDatabase FROM DISK = 'C:\Backups\Full.bak'
WITH NORECOVERY, REPLACE;

-- Restore log backups to specific time
RESTORE LOG MyDatabase FROM DISK = 'C:\Backups\Log1.trn'
WITH NORECOVERY;

RESTORE LOG MyDatabase FROM DISK = 'C:\Backups\Log2.trn'
WITH RECOVERY, STOPAT = '2024-01-15 14:30:00';

-- Allow connections
ALTER DATABASE MyDatabase SET MULTI_USER;
```

---

## Replication Patterns

### 1. Master-Slave (Primary-Replica) Replication

One primary server accepts writes, multiple replicas serve reads.

**Pros**:
- Read scaling (distribute read load)
- High availability (promote replica on primary failure)
- Zero data loss with synchronous replication
- Simple architecture

**Cons**:
- Write bottleneck (single primary)
- Replication lag with asynchronous
- Manual failover (unless automated)

**Use cases**: Most web applications, read-heavy workloads

```
┌──────────┐
│ Primary  │──┐
│ (Write)  │  │ Replication
└──────────┘  │
              ├──>┌──────────┐
              │   │ Replica1 │
              │   │  (Read)  │
              │   └──────────┘
              │
              └──>┌──────────┐
                  │ Replica2 │
                  │  (Read)  │
                  └──────────┘
```

### 2. Master-Master (Multi-Master) Replication

Multiple servers accept writes and replicate to each other.

**Pros**:
- Write scaling (distribute write load)
- High availability (any node can serve)
- Geographic distribution
- No single point of failure

**Cons**:
- Conflict resolution needed
- More complex
- Potential data inconsistency
- Harder to maintain

**Use cases**: Multi-region applications, always-on requirements

```
┌──────────┐      ┌──────────┐
│ Master1  │◄────►│ Master2  │
│  (R/W)   │      │  (R/W)   │
└──────────┘      └──────────┘
     │                 │
     └─────Replicate───┘
```

### 3. Cascading Replication

Replicas replicate from other replicas.

**Pros**:
- Reduces load on primary
- Better for geographically distributed systems
- More replicas without overloading primary

**Cons**:
- Increased replication lag
- More complex topology
- Replica failures affect downstream

**Use cases**: Large number of replicas, multi-region setups

```
┌──────────┐
│ Primary  │
└──────────┘
     │
     ▼
┌──────────┐
│ Replica1 │
└──────────┘
     │
     ├──>┌──────────┐
     │   │ Replica2 │
     │   └──────────┘
     │
     └──>┌──────────┐
         │ Replica3 │
         └──────────┘
```

### 4. Synchronous vs Asynchronous Replication

**Synchronous**:
```
┌──────────┐                    ┌──────────┐
│ Primary  │──1. Write data────>│ Replica  │
│          │<─2. Acknowledge────│          │
│          │──3. Confirm────────>  Client  │
└──────────┘                    └──────────┘

Pros: No data loss, strong consistency
Cons: Higher latency, reduced availability
```

**Asynchronous**:
```
┌──────────┐                    ┌──────────┐
│ Primary  │──1. Write data────>│          │
│          │──2. Confirm────────>  Client  │
│          │──3. Replicate─────>│ Replica  │
└──────────┘   (background)     └──────────┘

Pros: Lower latency, higher availability
Cons: Potential data loss, replication lag
```

**Semi-Synchronous** (MySQL):
```sql
-- Primary waits for at least one replica

-- Enable on master
INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
SET GLOBAL rpl_semi_sync_master_enabled = 1;
SET GLOBAL rpl_semi_sync_master_timeout = 1000;  -- 1 second

-- Enable on slave
INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
SET GLOBAL rpl_semi_sync_slave_enabled = 1;

-- Check status
SHOW STATUS LIKE 'Rpl_semi_sync%';
```

---

## High Availability

### PostgreSQL High Availability

#### 1. Streaming Replication

```bash
# Primary setup (postgresql.conf)
wal_level = replica
max_wal_senders = 3
wal_keep_size = 1GB  # PostgreSQL 13+, or wal_keep_segments in older versions
hot_standby = on

# Create replication user
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'secure_password';

# pg_hba.conf (allow replication connections)
host replication replicator replica_ip/32 md5

# Standby setup
# 1. Take base backup
pg_basebackup -h primary_ip -D /var/lib/postgresql/data -U replicator -P -v -R

# -R creates standby.signal and adds connection info to postgresql.auto.conf

# 2. Start standby
systemctl start postgresql

# Monitor replication
SELECT * FROM pg_stat_replication;

# Check replication lag
SELECT
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    sync_state,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;
```

#### 2. Logical Replication

```sql
-- Primary (publisher)
-- 1. Set wal_level
ALTER SYSTEM SET wal_level = logical;
-- Restart PostgreSQL

-- 2. Create publication
CREATE PUBLICATION my_publication FOR TABLE users, orders;
-- Or for all tables:
CREATE PUBLICATION all_tables FOR ALL TABLES;

-- Standby (subscriber)
-- 1. Create subscription
CREATE SUBSCRIPTION my_subscription
    CONNECTION 'host=primary_ip port=5432 dbname=mydb user=replicator password=pass'
    PUBLICATION my_publication;

-- Monitor
SELECT * FROM pg_stat_subscription;
SELECT * FROM pg_replication_origin_status;
```

#### 3. Patroni (Automated Failover)

```yaml
# patroni.yml
scope: postgres-cluster
name: node1

restapi:
  listen: 0.0.0.0:8008
  connect_address: node1_ip:8008

etcd:
  hosts: etcd1:2379,etcd2:2379,etcd3:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: on
        max_wal_senders: 5
        max_replication_slots: 5

postgresql:
  listen: 0.0.0.0:5432
  connect_address: node1_ip:5432
  data_dir: /var/lib/postgresql/data
  authentication:
    replication:
      username: replicator
      password: secure_password
    superuser:
      username: postgres
      password: postgres_password

# Start Patroni
patroni /etc/patroni.yml

# Check cluster status
patronictl -c /etc/patroni.yml list
```

### MySQL High Availability

#### 1. MySQL Replication

```sql
-- Master configuration (my.cnf)
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-format = ROW
gtid-mode = ON
enforce-gtid-consistency = ON

-- Create replication user
CREATE USER 'replicator'@'%' IDENTIFIED BY 'secure_password';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';

-- Slave configuration
[mysqld]
server-id = 2
relay-log = relay-bin
read-only = 1
gtid-mode = ON
enforce-gtid-consistency = ON

-- Set up replication on slave
CHANGE MASTER TO
    MASTER_HOST = 'master_ip',
    MASTER_USER = 'replicator',
    MASTER_PASSWORD = 'secure_password',
    MASTER_AUTO_POSITION = 1;  -- Use GTID

START SLAVE;

-- Check replication status
SHOW SLAVE STATUS\G

-- Monitor replication lag
SHOW SLAVE STATUS\G
-- Look at: Seconds_Behind_Master

-- Skip replication errors (use carefully!)
STOP SLAVE;
SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
START SLAVE;
```

#### 2. Group Replication (Multi-Master)

```sql
-- Node 1 configuration (my.cnf)
[mysqld]
server-id = 1
gtid-mode = ON
enforce-gtid-consistency = ON
binlog-checksum = NONE
log-bin = binlog
log-slave-updates = ON
binlog-format = ROW

plugin-load-add = group_replication.so
group_replication_group_name = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
group_replication_start_on_boot = OFF
group_replication_local_address = "node1:33061"
group_replication_group_seeds = "node1:33061,node2:33061,node3:33061"
group_replication_bootstrap_group = OFF

-- Bootstrap the group (node 1 only)
SET GLOBAL group_replication_bootstrap_group = ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group = OFF;

-- Join the group (other nodes)
START GROUP_REPLICATION;

-- Check group status
SELECT * FROM performance_schema.replication_group_members;
```

#### 3. MariaDB Galera Cluster

```ini
# my.cnf
[galera]
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_address = "gcomm://node1,node2,node3"
wsrep_cluster_name = "production_cluster"
wsrep_node_address = "node1_ip"
wsrep_node_name = "node1"
wsrep_sst_method = rsync

binlog_format = ROW
default_storage_engine = InnoDB
innodb_autoinc_lock_mode = 2
```

```bash
# Bootstrap first node
galera_new_cluster

# Start other nodes
systemctl start mariadb

# Check cluster status
mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
mysql -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
```

### MongoDB Replica Sets

```javascript
// Initialize replica set
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo1:27017", priority: 2 },
    { _id: 1, host: "mongo2:27017", priority: 1 },
    { _id: 2, host: "mongo3:27017", priority: 1, arbiterOnly: true }
  ]
});

// Check replica set status
rs.status();

// Add member
rs.add("mongo4:27017");

// Remove member
rs.remove("mongo4:27017");

// Step down primary (force election)
rs.stepDown();

// Reconfigure
cfg = rs.conf();
cfg.members[0].priority = 3;
rs.reconfig(cfg);

// Check replication lag
rs.printSecondaryReplicationInfo();

// Read from secondary
db.collection.find().readPref("secondary");
```

---

## Disaster Recovery

### Disaster Recovery Plan

```markdown
# Disaster Recovery Plan

## 1. Define Objectives
- RTO (Recovery Time Objective): 2 hours
- RPO (Recovery Point Objective): 15 minutes

## 2. Backup Strategy
- Full backup: Daily at 2 AM
- Incremental backup: Every 15 minutes
- Offsite backup: Replicated to different region

## 3. Failure Scenarios

### Scenario 1: Single Server Failure
- Detection: Monitoring alerts
- Response: Automatic failover to replica (5 minutes)
- Impact: Minimal, reads continue from replicas

### Scenario 2: Data Center Failure
- Detection: All servers unreachable
- Response: Failover to DR site (30 minutes)
- Impact: Service unavailable during failover

### Scenario 3: Data Corruption
- Detection: Application errors, data validation
- Response: Point-in-time recovery (1-2 hours)
- Impact: Service unavailable during recovery

### Scenario 4: Accidental Data Deletion
- Detection: User reports, monitoring
- Response: PITR to before deletion (30 minutes)
- Impact: Minimal if caught quickly

## 4. Recovery Procedures

### Step 1: Assess Situation
- Identify failure type
- Estimate impact
- Notify stakeholders

### Step 2: Initiate Recovery
- Follow appropriate scenario procedure
- Monitor recovery progress
- Verify data integrity

### Step 3: Validate Recovery
- Run health checks
- Verify data consistency
- Test application functionality

### Step 4: Resume Operations
- Update DNS/load balancers
- Monitor closely
- Communicate with stakeholders

### Step 5: Post-Mortem
- Document incident
- Identify root cause
- Implement improvements

## 5. Testing Schedule
- Restore test: Monthly
- Failover test: Quarterly
- Full DR drill: Annually
```

### Multi-Region Disaster Recovery

```
Region 1 (Primary)          Region 2 (DR)
┌─────────────┐            ┌─────────────┐
│   Primary   │            │   Standby   │
│   Database  │───async───▶│   Database  │
└─────────────┘ replication└─────────────┘
       │                           │
       │                           │
┌─────────────┐            ┌─────────────┐
│ Application │            │ Application │
│   Servers   │            │   Servers   │
└─────────────┘            └─────────────┘

Normal Operation:
- All traffic to Region 1
- Region 2 receives replicated data

Disaster (Region 1 fails):
- Promote Region 2 standby to primary
- Route traffic to Region 2
- Set up new standby in Region 3
```

**Implementation**:

```bash
# PostgreSQL cross-region replication
# Primary (Region 1) - postgresql.conf
wal_level = replica
max_wal_senders = 5
wal_keep_size = 5GB

# Standby (Region 2)
# Use streaming replication over VPN or AWS VPC peering
primary_conninfo = 'host=primary_region1 port=5432 user=replicator'

# Monitoring replication lag
SELECT
    client_addr,
    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes,
    extract(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds
FROM pg_stat_replication;

# Automated failover with route53 health checks (AWS)
aws route53 create-health-check \
    --caller-reference $(date +%s) \
    --health-check-config \
        IPAddress=primary_ip,Port=5432,Type=TCP

# Update DNS on failure
aws route53 change-resource-record-sets \
    --hosted-zone-id Z123456 \
    --change-batch file://failover.json
```

---

## Database-Specific Implementations

### PostgreSQL Backup & Replication

```bash
# Backup Methods

# 1. pg_dump (logical backup)
pg_dump -h localhost -U postgres -d mydb -F c -f backup.dump
pg_dump -h localhost -U postgres -d mydb -F p -f backup.sql  # Plain SQL
pg_dump -h localhost -U postgres -d mydb -F d -j 4 -f backup_dir/  # Parallel

# Restore
pg_restore -h localhost -U postgres -d mydb backup.dump
psql -h localhost -U postgres -d mydb < backup.sql

# 2. pg_basebackup (physical backup)
pg_basebackup -h localhost -D /backup/base -U replicator -P -v --wal-method=stream

# 3. WAL archiving (continuous backup)
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /backup/wal/%f && cp %p /backup/wal/%f'

# 4. Using WAL-G (modern backup tool)
# Install WAL-G
# Configure
export WALG_S3_PREFIX="s3://my-bucket/postgres-backups"
export AWS_REGION="us-east-1"

# Push base backup
wal-g backup-push /var/lib/postgresql/data

# List backups
wal-g backup-list

# Restore
wal-g backup-fetch /var/lib/postgresql/data LATEST

# Automated backup script
#!/bin/bash
BACKUP_DIR="/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Full backup
pg_dump -h localhost -U postgres -d mydb -F c -f "$BACKUP_DIR/backup_$DATE.dump"

# Compress
gzip "$BACKUP_DIR/backup_$DATE.dump"

# Upload to S3
aws s3 cp "$BACKUP_DIR/backup_$DATE.dump.gz" "s3://my-bucket/backups/"

# Clean old backups
find $BACKUP_DIR -name "backup_*.dump.gz" -mtime +$RETENTION_DAYS -delete

# Verify backup
if [ $? -eq 0 ]; then
    echo "Backup successful: backup_$DATE.dump.gz"
else
    echo "Backup failed!" | mail -s "Backup Failed" admin@example.com
fi
```

### MySQL Backup & Replication

```bash
# Backup Methods

# 1. mysqldump (logical backup)
mysqldump -u root -p --single-transaction --routines --triggers \
    --master-data=2 mydb > backup_$(date +%Y%m%d).sql

# All databases
mysqldump -u root -p --all-databases --single-transaction > all_backup.sql

# Restore
mysql -u root -p mydb < backup_20240115.sql

# 2. mysqlpump (parallel logical backup)
mysqlpump -u root -p --default-parallelism=4 mydb > backup.sql

# 3. Percona XtraBackup (hot physical backup)
xtrabackup --backup --target-dir=/backup/full

# Restore
xtrabackup --prepare --target-dir=/backup/full
xtrabackup --copy-back --target-dir=/backup/full

# 4. Binary log backup
mysqlbinlog --read-from-remote-server --host=localhost \
    --user=root --password=pass mysql-bin.000001 > binlog_000001.sql

# Automated backup script
#!/bin/bash
BACKUP_DIR="/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Full backup with mysqldump
mysqldump -u root -p$MYSQL_PASSWORD \
    --single-transaction \
    --routines \
    --triggers \
    --all-databases \
    --master-data=2 | gzip > "$BACKUP_DIR/backup_$DATE.sql.gz"

# Binary log backup
mysql -u root -p$MYSQL_PASSWORD -e "FLUSH LOGS;"
cp /var/log/mysql/mysql-bin.* /backups/binlogs/

# Upload to S3
aws s3 sync $BACKUP_DIR s3://my-bucket/mysql-backups/

# Clean old backups
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Verify backup size
BACKUP_SIZE=$(stat -f%z "$BACKUP_DIR/backup_$DATE.sql.gz")
if [ $BACKUP_SIZE -gt 1000000 ]; then
    echo "Backup successful: $BACKUP_SIZE bytes"
else
    echo "Backup too small, may be corrupted!" | mail -s "Backup Warning" admin@example.com
fi
```

### MongoDB Backup & Replication

```bash
# Backup Methods

# 1. mongodump (logical backup)
mongodump --host localhost --port 27017 --out /backup/$(date +%Y%m%d)

# Specific database
mongodump --db mydb --out /backup/mydb

# With authentication
mongodump --username admin --password pass --authenticationDatabase admin --out /backup

# Restore
mongorestore --host localhost --port 27017 /backup/20240115

# 2. File system snapshot (if using WiredTiger)
# Stop writes temporarily
db.fsyncLock()

# Take snapshot (e.g., LVM or EBS snapshot)
lvcreate --size 10G --snapshot --name mongo-snapshot /dev/vg0/mongo-data

# Resume writes
db.fsyncUnlock()

# 3. MongoDB Cloud Manager / Ops Manager
# Automated backups with point-in-time recovery

# 4. Automated backup script
#!/bin/bash
BACKUP_DIR="/backups/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Create backup
mongodump --host localhost --port 27017 --out "$BACKUP_DIR/backup_$DATE"

# Compress
tar -czf "$BACKUP_DIR/backup_$DATE.tar.gz" "$BACKUP_DIR/backup_$DATE"
rm -rf "$BACKUP_DIR/backup_$DATE"

# Upload to S3
aws s3 cp "$BACKUP_DIR/backup_$DATE.tar.gz" "s3://my-bucket/mongodb-backups/"

# Clean old backups
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "MongoDB backup completed: backup_$DATE.tar.gz"
```

---

## Best Practices

### Backup Best Practices

1. **3-2-1 Rule**: 3 copies, 2 different media, 1 offsite
2. **Automate Everything**: Schedule backups, don't rely on manual processes
3. **Test Restores Regularly**: Backup is useless if you can't restore
4. **Monitor Backup Jobs**: Alert on failures immediately
5. **Encrypt Backups**: Both in transit and at rest
6. **Document Procedures**: Clear, step-by-step recovery procedures
7. **Version Compatibility**: Test backups with target restore version
8. **Retention Policy**: Balance cost with compliance/business needs
9. **Verify Integrity**: Checksum or test restore after backup
10. **Separate Backup Storage**: Don't store backups on same infrastructure

### Replication Best Practices

1. **Monitor Replication Lag**: Alert on excessive lag
2. **Use Proper Hardware**: Replicas should match primary specs
3. **Network Reliability**: Stable, low-latency connections
4. **Authentication**: Secure replication connections
5. **Read Preference**: Route reads to replicas appropriately
6. **Failover Testing**: Regularly test failover procedures
7. **Replica Promotion**: Document and automate promotion process
8. **Configuration Management**: Keep replicas in sync
9. **Monitoring**: Track replication health continuously
10. **Capacity Planning**: Plan for replica load

### Disaster Recovery Best Practices

1. **Define RTO/RPO**: Clear objectives for recovery
2. **Multi-Region**: Distribute across geographic regions
3. **Regular Testing**: Quarterly DR drills minimum
4. **Documentation**: Up-to-date runbooks
5. **Communication Plan**: Clear escalation procedures
6. **Automate Failover**: Reduce manual intervention
7. **Health Checks**: Automated monitoring and alerts
8. **Capacity**: DR site can handle production load
9. **Data Validation**: Verify data integrity after recovery
10. **Post-Mortem**: Learn from every incident

### Monitoring Checklist

**Backups**:
- [ ] Backup job completion status
- [ ] Backup file size (detect truncation)
- [ ] Backup duration (detect performance issues)
- [ ] Backup storage space
- [ ] Last successful backup timestamp
- [ ] Restore test results

**Replication**:
- [ ] Replication lag (bytes and seconds)
- [ ] Replica connection status
- [ ] Replica health
- [ ] Synchronization state
- [ ] Conflicts (multi-master)
- [ ] Replication errors

**General**:
- [ ] Disk space
- [ ] Database connections
- [ ] Query performance
- [ ] CPU and memory usage
- [ ] Lock contention
- [ ] Transaction log size

---

## Backup Automation Example

Complete automated backup solution with monitoring:

```bash
#!/bin/bash
# /opt/scripts/database-backup.sh

set -euo pipefail

# Configuration
DB_TYPE="postgresql"  # or mysql, mongodb
DB_HOST="localhost"
DB_NAME="mydb"
DB_USER="backup_user"
BACKUP_DIR="/backups"
S3_BUCKET="s3://my-backups"
RETENTION_DAYS=7
LOG_FILE="/var/log/database-backup.log"
ALERT_EMAIL="admin@example.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

alert() {
    local message="$1"
    echo "$message" | mail -s "Database Backup Alert" "$ALERT_EMAIL"
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" "$SLACK_WEBHOOK"
}

backup_postgresql() {
    local backup_file="$BACKUP_DIR/pg_${DB_NAME}_$(date +%Y%m%d_%H%M%S).dump"
    pg_dump -h "$DB_HOST" -U "$DB_USER" -F c -f "$backup_file" "$DB_NAME"
    echo "$backup_file"
}

backup_mysql() {
    local backup_file="$BACKUP_DIR/mysql_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
    mysqldump -h "$DB_HOST" -u "$DB_USER" \
        --single-transaction --routines --triggers \
        "$DB_NAME" > "$backup_file"
    echo "$backup_file"
}

backup_mongodb() {
    local backup_dir="$BACKUP_DIR/mongo_${DB_NAME}_$(date +%Y%m%d_%H%M%S)"
    mongodump --host "$DB_HOST" --db "$DB_NAME" --out "$backup_dir"
    tar -czf "${backup_dir}.tar.gz" "$backup_dir"
    rm -rf "$backup_dir"
    echo "${backup_dir}.tar.gz"
}

verify_backup() {
    local backup_file="$1"
    local min_size=1000000  # 1MB

    if [ ! -f "$backup_file" ]; then
        log "ERROR: Backup file not found: $backup_file"
        return 1
    fi

    local size=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file")
    if [ "$size" -lt "$min_size" ]; then
        log "ERROR: Backup file too small: $size bytes"
        return 1
    fi

    log "Backup verified: $size bytes"
    return 0
}

# Main execution
log "Starting backup for $DB_TYPE database: $DB_NAME"

START_TIME=$(date +%s)

# Perform backup
case "$DB_TYPE" in
    postgresql)
        BACKUP_FILE=$(backup_postgresql)
        ;;
    mysql)
        BACKUP_FILE=$(backup_mysql)
        ;;
    mongodb)
        BACKUP_FILE=$(backup_mongodb)
        ;;
    *)
        log "ERROR: Unknown database type: $DB_TYPE"
        alert "Backup failed: Unknown database type"
        exit 1
        ;;
esac

# Verify backup
if ! verify_backup "$BACKUP_FILE"; then
    alert "Backup verification failed for $DB_NAME"
    exit 1
fi

# Compress if not already compressed
if [[ "$BACKUP_FILE" != *.gz ]]; then
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
fi

# Upload to S3
log "Uploading backup to S3..."
if aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/$(basename $BACKUP_FILE)"; then
    log "Upload successful"
else
    alert "Failed to upload backup to S3"
    exit 1
fi

# Clean old backups
log "Cleaning old backups..."
find "$BACKUP_DIR" -name "${DB_TYPE}_${DB_NAME}_*.gz" -mtime +$RETENTION_DAYS -delete
aws s3 ls "$S3_BUCKET/" | while read -r line; do
    createDate=$(echo $line | awk '{print $1" "$2}')
    createDate=$(date -d "$createDate" +%s)
    olderThan=$(date -d "$RETENTION_DAYS days ago" +%s)
    if [[ $createDate -lt $olderThan ]]; then
        fileName=$(echo $line | awk '{print $4}')
        if [[ $fileName != "" ]]; then
            aws s3 rm "$S3_BUCKET/$fileName"
        fi
    fi
done

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

log "Backup completed successfully in ${DURATION} seconds"

# Send success notification
curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"✅ Backup successful: $DB_NAME ($DURATION seconds)\"}" \
    "$SLACK_WEBHOOK"

exit 0
```

**Crontab entry**:
```bash
# Daily full backup at 2 AM
0 2 * * * /opt/scripts/database-backup.sh >> /var/log/database-backup.log 2>&1

# Hourly incremental (if supported)
0 * * * * /opt/scripts/incremental-backup.sh >> /var/log/database-backup.log 2>&1
```

---

## Conclusion

Effective backup and replication strategies are essential for:
- **Data durability**: Protect against data loss
- **High availability**: Minimize downtime
- **Disaster recovery**: Recover from catastrophic failures
- **Compliance**: Meet regulatory requirements
- **Business continuity**: Keep business running

Remember: **Untested backups are not backups!**

---

## Additional Resources

### Tools
- PostgreSQL: pg_dump, pg_basebackup, WAL-G, Patroni, repmgr
- MySQL: mysqldump, mysqlpump, Percona XtraBackup, MySQL Enterprise Backup
- MongoDB: mongodump, Ops Manager, Cloud Manager
- Cross-platform: Barman, pgBackRest, restic, duplicity

### Documentation
- PostgreSQL Backup: https://www.postgresql.org/docs/current/backup.html
- MySQL Replication: https://dev.mysql.com/doc/refman/8.0/en/replication.html
- MongoDB Backup: https://docs.mongodb.com/manual/core/backups/

### Books
- "PostgreSQL High Availability Cookbook"
- "MySQL High Availability"
- "Designing Data-Intensive Applications" by Martin Kleppmann

---

**End of Skills Documentation**
