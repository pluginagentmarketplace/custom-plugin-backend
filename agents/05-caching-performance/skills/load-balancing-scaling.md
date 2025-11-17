# Load Balancing & Scaling Strategies

## Overview

Load balancing and scaling are essential techniques for building high-performance, highly available systems that can handle growing traffic. Load balancing distributes traffic across multiple servers, while scaling strategies determine how to add capacity to meet demand.

## Table of Contents

1. [Load Balancing Fundamentals](#load-balancing-fundamentals)
2. [Load Balancing Algorithms](#load-balancing-algorithms)
3. [Load Balancer Types](#load-balancer-types)
4. [Horizontal vs Vertical Scaling](#scaling-strategies)
5. [Database Scaling](#database-scaling)
6. [Sharding Strategies](#sharding)
7. [Auto-Scaling](#auto-scaling)
8. [Implementation Examples](#implementation)

---

## Load Balancing Fundamentals

### What is Load Balancing?

Load balancing is the process of distributing network traffic across multiple servers to prevent any single server from being overwhelmed, ensuring high availability and optimal resource utilization.

### Benefits

```yaml
Primary Benefits:
  - Prevents server overload
  - Improves application performance
  - Increases availability and fault tolerance
  - Enables zero-downtime deployments
  - Facilitates horizontal scaling
  - Better resource utilization

Secondary Benefits:
  - Geographic distribution
  - SSL termination offloading
  - DDoS protection
  - Request routing based on content
  - Health monitoring
```

### Architecture Pattern

```
                    ┌─────────────┐
                    │   Clients   │
                    └──────┬──────┘
                           │
                           ▼
                  ┌────────────────┐
                  │ Load Balancer  │
                  └────────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────┐      ┌─────────┐      ┌─────────┐
   │Server 1 │      │Server 2 │      │Server 3 │
   └─────────┘      └─────────┘      └─────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Database   │
                    └─────────────┘
```

---

## Load Balancing Algorithms

### 1. Round Robin

**Description:** Distributes requests sequentially to each server in rotation.

**Flow:**
```
Request 1 → Server A
Request 2 → Server B
Request 3 → Server C
Request 4 → Server A
Request 5 → Server B
...
```

**Implementation (Nginx):**
```nginx
http {
    upstream backend {
        # Simple round-robin (default)
        server backend1.example.com;
        server backend2.example.com;
        server backend3.example.com;
    }

    server {
        listen 80;
        location / {
            proxy_pass http://backend;
        }
    }
}
```

**Characteristics:**

| Aspect | Details |
|--------|---------|
| **Complexity** | Very Low |
| **State Required** | None |
| **Distribution** | Even over time |
| **Server Awareness** | None |
| **Best For** | Identical servers, similar request times |

**Advantages:**
- ✅ Simple to implement
- ✅ Even distribution over time
- ✅ No state required
- ✅ Predictable behavior

**Disadvantages:**
- ❌ Doesn't account for server load
- ❌ Assumes identical server capacity
- ❌ May send requests to overloaded servers

---

### 2. Weighted Round Robin

**Description:** Assigns weights to servers based on capacity, routing more traffic to powerful servers.

**Implementation (Nginx):**
```nginx
upstream backend {
    server backend1.example.com weight=3;  # Receives 3x traffic
    server backend2.example.com weight=2;  # Receives 2x traffic
    server backend3.example.com weight=1;  # Receives 1x traffic
}
```

**Distribution Example:**
```
Weights: A=3, B=2, C=1
Pattern: A, A, B, A, B, C, A, A, B, A, B, C...

Out of 6 requests:
  Server A: 3 requests (50%)
  Server B: 2 requests (33%)
  Server C: 1 request  (17%)
```

**Python Implementation:**
```python
class WeightedRoundRobin:
    def __init__(self, servers):
        """
        servers: [(server, weight), ...]
        Example: [('server1', 3), ('server2', 2), ('server3', 1)]
        """
        self.servers = []
        for server, weight in servers:
            self.servers.extend([server] * weight)
        self.index = 0

    def get_server(self):
        server = self.servers[self.index]
        self.index = (self.index + 1) % len(self.servers)
        return server

# Usage
lb = WeightedRoundRobin([
    ('192.168.1.10', 3),
    ('192.168.1.11', 2),
    ('192.168.1.12', 1),
])

for _ in range(12):
    print(lb.get_server())
```

**Use Cases:**
- Heterogeneous server specifications
- Different server capacities
- Gradual rollout (give new server low weight)

---

### 3. Least Connections

**Description:** Routes requests to the server with the fewest active connections.

**Implementation (Nginx):**
```nginx
upstream backend {
    least_conn;  # Enable least connections
    server backend1.example.com;
    server backend2.example.com;
    server backend3.example.com;
}
```

**Implementation (HAProxy):**
```haproxy
backend servers
    balance leastconn
    server server1 192.168.1.10:80 check
    server server2 192.168.1.11:80 check
    server server3 192.168.1.12:80 check
```

**Python Implementation:**
```python
class LeastConnections:
    def __init__(self, servers):
        self.connections = {server: 0 for server in servers}

    def get_server(self):
        # Find server with minimum connections
        server = min(self.connections, key=self.connections.get)
        self.connections[server] += 1
        return server

    def release_server(self, server):
        self.connections[server] -= 1

# Usage
lb = LeastConnections(['server1', 'server2', 'server3'])

server = lb.get_server()
# ... handle request ...
lb.release_server(server)
```

**Advantages:**
- ✅ Dynamic load balancing
- ✅ Accounts for actual server load
- ✅ Better for variable request times
- ✅ Prevents overloading slower servers

**Disadvantages:**
- ❌ Requires connection tracking
- ❌ More complex than round-robin
- ❌ Overhead in maintaining counts

**Best For:**
- Longer-lived connections
- Variable request processing times
- WebSocket connections
- Database connections

---

### 4. Weighted Least Connections

**Description:** Combines least connections with server weights.

**Formula:**
```
Score = Active_Connections / Weight

Route to server with lowest score
```

**Implementation (HAProxy):**
```haproxy
backend servers
    balance leastconn
    server server1 192.168.1.10:80 weight 3 check
    server server2 192.168.1.11:80 weight 2 check
    server server3 192.168.1.12:80 weight 1 check
```

---

### 5. IP Hash

**Description:** Routes requests from the same client IP to the same server using hash function.

**Implementation (Nginx):**
```nginx
upstream backend {
    ip_hash;
    server backend1.example.com;
    server backend2.example.com;
    server backend3.example.com;
}
```

**How It Works:**
```
Client IP: 192.168.1.100
Hash(192.168.1.100) mod 3 = 1
→ Always routes to Server 2

Client IP: 192.168.1.101
Hash(192.168.1.101) mod 3 = 0
→ Always routes to Server 1
```

**Python Implementation:**
```python
import hashlib

class IPHashLoadBalancer:
    def __init__(self, servers):
        self.servers = servers

    def get_server(self, client_ip):
        # Hash client IP
        hash_value = int(hashlib.md5(client_ip.encode()).hexdigest(), 16)
        # Map to server
        index = hash_value % len(self.servers)
        return self.servers[index]

# Usage
lb = IPHashLoadBalancer(['server1', 'server2', 'server3'])
server = lb.get_server('192.168.1.100')  # Always returns same server
```

**Advantages:**
- ✅ Session persistence without state
- ✅ Same client → same server
- ✅ Simple implementation

**Disadvantages:**
- ❌ Uneven distribution possible
- ❌ Adding/removing servers disrupts all mappings
- ❌ Doesn't account for server load

**Best For:**
- Stateful applications
- Session-based applications without shared storage
- Applications requiring sticky sessions

---

### 6. Consistent Hashing

**Description:** Uses hash ring to minimize remapping when servers are added/removed.

**Architecture:**
```
         Hash Ring (0-360°)
              0°
              │
        ┌─────┴─────┐
        │           │
   270°─┤   Ring    ├─90°
        │           │
        └─────┬─────┘
             180°

Servers hashed onto ring:
  Server A: 45°
  Server B: 135°
  Server C: 270°

Request for key "user:123":
  Hash("user:123") = 100°
  → Route to next server clockwise = Server B (135°)
```

**Python Implementation:**
```python
import hashlib
import bisect

class ConsistentHash:
    def __init__(self, servers, virtual_nodes=150):
        self.virtual_nodes = virtual_nodes
        self.ring = {}
        self.sorted_keys = []

        for server in servers:
            self.add_server(server)

    def _hash(self, key):
        return int(hashlib.md5(key.encode()).hexdigest(), 16)

    def add_server(self, server):
        """Add server with virtual nodes"""
        for i in range(self.virtual_nodes):
            virtual_key = f"{server}:{i}"
            hash_value = self._hash(virtual_key)
            self.ring[hash_value] = server
            bisect.insort(self.sorted_keys, hash_value)

    def remove_server(self, server):
        """Remove server and its virtual nodes"""
        for i in range(self.virtual_nodes):
            virtual_key = f"{server}:{i}"
            hash_value = self._hash(virtual_key)
            del self.ring[hash_value]
            self.sorted_keys.remove(hash_value)

    def get_server(self, key):
        """Get server for given key"""
        if not self.ring:
            return None

        hash_value = self._hash(key)

        # Find first server clockwise
        index = bisect.bisect(self.sorted_keys, hash_value)
        if index == len(self.sorted_keys):
            index = 0

        return self.ring[self.sorted_keys[index]]

# Usage
lb = ConsistentHash(['server1', 'server2', 'server3'])

# These will consistently map to same servers
print(lb.get_server('user:123'))
print(lb.get_server('user:456'))

# Add new server - only ~25% of keys remapped
lb.add_server('server4')

# Remove server - only ~33% of keys remapped
lb.remove_server('server2')
```

**Advantages:**
- ✅ Minimal disruption when adding/removing servers
- ✅ Only ~1/N requests remap (N = server count)
- ✅ Scalable and flexible
- ✅ Even distribution with virtual nodes

**Disadvantages:**
- ❌ More complex implementation
- ❌ Requires careful hash function selection

**Best For:**
- Distributed caching (Redis, Memcached clusters)
- Microservices
- Dynamic scaling environments
- Distributed databases

**Impact When Adding Server:**
```
3 servers → 4 servers:
  - Simple hash: 75% keys remapped
  - Consistent hash: 25% keys remapped
```

---

### 7. Least Response Time

**Description:** Routes to server with fastest response time.

**Implementation (Nginx Plus - Commercial):**
```nginx
upstream backend {
    least_time header;  # or 'last_byte'
    server backend1.example.com;
    server backend2.example.com;
    server backend3.example.com;
}
```

**Python Implementation:**
```python
import time
from collections import defaultdict

class LeastResponseTime:
    def __init__(self, servers):
        self.servers = servers
        self.response_times = defaultdict(list)
        self.max_history = 100

    def get_server(self):
        if not any(self.response_times.values()):
            # No history, use round-robin
            return self.servers[0]

        # Calculate average response time
        avg_times = {}
        for server in self.servers:
            if self.response_times[server]:
                avg_times[server] = sum(self.response_times[server]) / len(self.response_times[server])
            else:
                avg_times[server] = float('inf')

        return min(avg_times, key=avg_times.get)

    def record_response_time(self, server, duration):
        self.response_times[server].append(duration)
        # Keep only recent history
        if len(self.response_times[server]) > self.max_history:
            self.response_times[server].pop(0)

# Usage
lb = LeastResponseTime(['server1', 'server2', 'server3'])

server = lb.get_server()
start = time.time()
# ... make request to server ...
duration = time.time() - start
lb.record_response_time(server, duration)
```

**Best For:**
- Applications prioritizing response time
- Geographically distributed servers
- Mixed server performance

---

### 8. Resource-Based

**Description:** Routes based on real-time server resource availability (CPU, memory, etc.).

**Implementation Concept:**
```python
class ResourceBasedLoadBalancer:
    def __init__(self, servers):
        self.servers = servers

    def get_server_metrics(self, server):
        """Get current server resource usage"""
        # In production, query monitoring system
        return {
            'cpu': 45.2,      # CPU usage %
            'memory': 60.1,   # Memory usage %
            'connections': 150,
            'response_time': 125  # ms
        }

    def calculate_score(self, metrics):
        """Lower score = better server"""
        return (
            metrics['cpu'] * 0.4 +
            metrics['memory'] * 0.3 +
            metrics['response_time'] * 0.3
        )

    def get_server(self):
        scores = {}
        for server in self.servers:
            metrics = self.get_server_metrics(server)
            scores[server] = self.calculate_score(metrics)

        return min(scores, key=scores.get)
```

**Advantages:**
- ✅ Optimal resource utilization
- ✅ Prevents overload
- ✅ Adapts to real conditions

**Disadvantages:**
- ❌ Complex to implement
- ❌ Monitoring overhead
- ❌ Latency in decision-making

---

## Load Balancer Types

### Layer 4 (Transport Layer)

**Operates at:** TCP/UDP level

**Routes based on:** IP address, port

**Example (HAProxy):**
```haproxy
frontend tcp_front
    bind *:80
    mode tcp
    default_backend tcp_back

backend tcp_back
    mode tcp
    balance roundrobin
    server server1 192.168.1.10:80 check
    server server2 192.168.1.11:80 check
```

**Characteristics:**

| Aspect | Details |
|--------|---------|
| **Speed** | Very fast |
| **Overhead** | Minimal |
| **Protocol Awareness** | None (TCP/UDP only) |
| **SSL Termination** | No |
| **Content Routing** | No |
| **Use Cases** | High-performance needs, non-HTTP protocols |

**Advantages:**
- ✅ Very fast (minimal processing)
- ✅ Simple and efficient
- ✅ Works with any protocol
- ✅ Low latency

**Disadvantages:**
- ❌ No content-based routing
- ❌ Limited intelligence
- ❌ No SSL termination

---

### Layer 7 (Application Layer)

**Operates at:** HTTP/HTTPS level

**Routes based on:** URLs, headers, cookies, content

**Example (Nginx):**
```nginx
http {
    upstream api_servers {
        server api1.example.com;
        server api2.example.com;
    }

    upstream web_servers {
        server web1.example.com;
        server web2.example.com;
    }

    server {
        listen 80;

        # Route based on URL path
        location /api/ {
            proxy_pass http://api_servers;
        }

        location / {
            proxy_pass http://web_servers;
        }

        # Route based on header
        location /admin/ {
            if ($http_x_admin_token = "secret") {
                proxy_pass http://admin_servers;
            }
            return 403;
        }
    }
}
```

**Advanced Routing (Traefik):**
```yaml
http:
  routers:
    api-router:
      rule: "Host(`api.example.com`) && PathPrefix(`/v1`)"
      service: api-service

    web-router:
      rule: "Host(`example.com`)"
      service: web-service

  services:
    api-service:
      loadBalancer:
        servers:
          - url: "http://api1:8080"
          - url: "http://api2:8080"

    web-service:
      loadBalancer:
        servers:
          - url: "http://web1:80"
          - url: "http://web2:80"
```

**Advantages:**
- ✅ Content-based routing
- ✅ URL path routing
- ✅ Host-based routing
- ✅ SSL termination
- ✅ Caching
- ✅ Compression
- ✅ Advanced features

**Disadvantages:**
- ❌ Higher latency
- ❌ More resource intensive
- ❌ More complex configuration

**Best For:**
- Microservices
- API gateways
- Complex routing requirements
- Multi-tenant applications

---

## Scaling Strategies

### Horizontal Scaling (Scale Out)

**Definition:** Add more servers to distribute load.

**Architecture:**
```
Before Scaling:
┌─────────────┐
│  1 Server   │
│ 8 CPU       │
│ 16GB RAM    │
└─────────────┘

After Horizontal Scaling:
┌───────────┐  ┌───────────┐  ┌───────────┐
│ Server 1  │  │ Server 2  │  │ Server 3  │
│ 8 CPU     │  │ 8 CPU     │  │ 8 CPU     │
│ 16GB RAM  │  │ 16GB RAM  │  │ 16GB RAM  │
└───────────┘  └───────────┘  └───────────┘
```

**Characteristics:**

| Aspect | Details |
|--------|---------|
| **Scalability** | Near-infinite |
| **Availability** | High (no single point of failure) |
| **Cost** | Linear, predictable |
| **Complexity** | Higher |
| **Deployment** | Rolling deployments possible |

**Advantages:**
- ✅ Near-infinite scalability
- ✅ High availability and fault tolerance
- ✅ No single point of failure
- ✅ Incremental scaling
- ✅ Cost-effective with cloud auto-scaling
- ✅ Easier upgrades (rolling)

**Disadvantages:**
- ❌ Application must be stateless
- ❌ More complex architecture
- ❌ Network communication overhead
- ❌ Data consistency challenges
- ❌ Requires load balancer

**Requirements:**
```yaml
Application Requirements:
  - Stateless design
  - Shared session storage (Redis/database)
  - No local file storage
  - Database supports connections from multiple servers

Infrastructure Requirements:
  - Load balancer
  - Shared storage (if needed)
  - Service discovery (for microservices)
  - Distributed logging
  - Centralized configuration
```

**Implementation (Docker Swarm):**
```bash
# Scale service to 5 replicas
docker service scale web_app=5

# Auto-scaling
docker service create \
  --name web_app \
  --replicas 3 \
  --publish 80:80 \
  --update-parallelism 1 \
  --update-delay 10s \
  myapp:latest
```

**Implementation (Kubernetes):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: myapp:latest
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

### Vertical Scaling (Scale Up)

**Definition:** Increase resources of existing server (CPU, RAM, disk).

**Architecture:**
```
Before Scaling:
┌─────────────┐
│  1 Server   │
│ 4 CPU       │
│ 8GB RAM     │
└─────────────┘

After Vertical Scaling:
┌─────────────┐
│  1 Server   │
│ 16 CPU      │
│ 32GB RAM    │
└─────────────┘
```

**Characteristics:**

| Aspect | Details |
|--------|---------|
| **Scalability** | Limited (hardware limits) |
| **Availability** | Single point of failure |
| **Cost** | Exponential at high end |
| **Complexity** | Low |
| **Deployment** | Requires downtime |

**Typical Progression:**
```
1. Start:   2 CPU,  4GB RAM   → $20/month
2. Upgrade: 4 CPU,  8GB RAM   → $40/month
3. Upgrade: 8 CPU, 16GB RAM   → $80/month
4. Upgrade: 16 CPU, 32GB RAM  → $160/month
5. Limit:   32 CPU, 64GB RAM  → $320/month
   ↓
   Must switch to horizontal scaling
```

**Advantages:**
- ✅ Simple architecture
- ✅ No application changes needed
- ✅ Lower complexity
- ✅ No distributed system challenges
- ✅ Better for stateful applications

**Disadvantages:**
- ❌ Hard scaling limits
- ❌ Expensive at high end
- ❌ Single point of failure
- ❌ Downtime during upgrades
- ❌ Less cost-effective at scale

**Cloud Implementation (AWS):**
```bash
# Stop instance
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Change instance type
aws ec2 modify-instance-attribute \
  --instance-id i-1234567890abcdef0 \
  --instance-type t3.large

# Start instance
aws ec2 start-instances --instance-ids i-1234567890abcdef0
```

---

### Comparison

| Factor | Horizontal | Vertical |
|--------|------------|----------|
| **Max Capacity** | Near-infinite | Hardware limited |
| **Cost at Scale** | Linear | Exponential |
| **Downtime** | None (rolling updates) | Required |
| **Fault Tolerance** | High | Low |
| **Complexity** | High | Low |
| **Best For** | Cloud-native apps | Legacy/monolithic apps |

---

## Database Scaling

### Replication

#### Master-Slave (Primary-Replica)

**Architecture:**
```
                    ┌──────────────┐
                    │   Master     │ ← All writes
                    │  (Primary)   │
                    └──────┬───────┘
                           │
                  ┌────────┼────────┐
                  │        │        │
            ┌─────▼──┐ ┌──▼─────┐ ┌▼──────┐
            │ Slave1 │ │ Slave2 │ │Slave3 │ ← Read queries
            │(Replica│ │(Replica│ │(Repli-│
            │   )    │ │   )    │ │  ca)  │
            └────────┘ └────────┘ └───────┘
```

**Implementation (MySQL):**
```sql
-- On Master
CREATE USER 'replication'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%';
FLUSH PRIVILEGES;

-- Get binary log position
SHOW MASTER STATUS;

-- On Slave
CHANGE MASTER TO
  MASTER_HOST='master_host',
  MASTER_USER='replication',
  MASTER_PASSWORD='password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=107;

START SLAVE;
SHOW SLAVE STATUS\G
```

**Application Code (Python):**
```python
import pymysql
from pymysql import cursors

class DatabasePool:
    def __init__(self, master_config, slave_configs):
        self.master = pymysql.connect(**master_config)
        self.slaves = [pymysql.connect(**config) for config in slave_configs]
        self.slave_index = 0

    def write(self, query, params=None):
        """All writes go to master"""
        with self.master.cursor() as cursor:
            cursor.execute(query, params)
        self.master.commit()

    def read(self, query, params=None):
        """Reads distributed across slaves"""
        slave = self.slaves[self.slave_index]
        self.slave_index = (self.slave_index + 1) % len(self.slaves)

        with slave.cursor() as cursor:
            cursor.execute(query, params)
            return cursor.fetchall()

# Usage
db = DatabasePool(
    master_config={'host': 'master.db', 'user': 'app', 'password': 'pass', 'database': 'mydb'},
    slave_configs=[
        {'host': 'slave1.db', 'user': 'app', 'password': 'pass', 'database': 'mydb'},
        {'host': 'slave2.db', 'user': 'app', 'password': 'pass', 'database': 'mydb'},
    ]
)

# Write
db.write("INSERT INTO users (name) VALUES (%s)", ('John',))

# Read
users = db.read("SELECT * FROM users WHERE status = %s", ('active',))
```

**Advantages:**
- ✅ Scales read capacity
- ✅ High availability
- ✅ Backup without impacting production
- ✅ Geographic distribution

**Disadvantages:**
- ❌ Replication lag (eventual consistency)
- ❌ Doesn't scale writes
- ❌ Master is single point of contention

---

#### Master-Master (Multi-Master)

**Architecture:**
```
     ┌──────────────┐ ←─ Bi-directional ─→ ┌──────────────┐
     │   Master 1   │     Replication      │   Master 2   │
     │ (Read/Write) │ ←─────────────────→ │ (Read/Write) │
     └──────────────┘                      └──────────────┘
          ↑                                      ↑
          │                                      │
     Write + Read                           Write + Read
```

**Advantages:**
- ✅ Scales both reads and writes
- ✅ High availability
- ✅ Geographic write distribution

**Disadvantages:**
- ❌ Complex conflict resolution
- ❌ Potential data conflicts
- ❌ More complex to manage

---

## Sharding

### What is Sharding?

**Definition:** Partitioning data across multiple databases to scale beyond single database capacity.

### Horizontal Sharding

**Architecture:**
```
Application
     │
     ├─ Shard 1: Users 1-1000      (DB Server 1)
     ├─ Shard 2: Users 1001-2000   (DB Server 2)
     ├─ Shard 3: Users 2001-3000   (DB Server 3)
     └─ Shard 4: Users 3001-4000   (DB Server 4)
```

**Sharding Strategies:**

#### 1. Range-Based Sharding
```python
def get_shard(user_id):
    if user_id <= 1000:
        return 'shard1'
    elif user_id <= 2000:
        return 'shard2'
    elif user_id <= 3000:
        return 'shard3'
    else:
        return 'shard4'
```

**Pros:** Simple, range queries efficient
**Cons:** Uneven distribution, hotspots

#### 2. Hash-Based Sharding
```python
def get_shard(user_id):
    shards = ['shard1', 'shard2', 'shard3', 'shard4']
    return shards[hash(user_id) % len(shards)]
```

**Pros:** Even distribution
**Cons:** Range queries difficult, resharding complex

#### 3. Geographic Sharding
```python
def get_shard(country):
    shard_map = {
        'US': 'shard_americas',
        'UK': 'shard_europe',
        'JP': 'shard_asia',
    }
    return shard_map.get(country, 'shard_default')
```

**Pros:** Low latency for users, data sovereignty
**Cons:** Uneven distribution possible

---

### Sharding Implementation

```python
class ShardedDatabase:
    def __init__(self, shard_configs):
        self.shards = {
            name: pymysql.connect(**config)
            for name, config in shard_configs.items()
        }

    def get_shard_for_user(self, user_id):
        """Hash-based sharding"""
        shard_count = len(self.shards)
        shard_index = hash(user_id) % shard_count
        shard_name = f'shard{shard_index + 1}'
        return self.shards[shard_name]

    def insert_user(self, user_id, data):
        shard = self.get_shard_for_user(user_id)
        with shard.cursor() as cursor:
            cursor.execute(
                "INSERT INTO users (id, name, email) VALUES (%s, %s, %s)",
                (user_id, data['name'], data['email'])
            )
        shard.commit()

    def get_user(self, user_id):
        shard = self.get_shard_for_user(user_id)
        with shard.cursor(cursors.DictCursor) as cursor:
            cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
            return cursor.fetchone()

# Usage
db = ShardedDatabase({
    'shard1': {'host': 'shard1.db', 'user': 'app', 'database': 'users'},
    'shard2': {'host': 'shard2.db', 'user': 'app', 'database': 'users'},
    'shard3': {'host': 'shard3.db', 'user': 'app', 'database': 'users'},
    'shard4': {'host': 'shard4.db', 'user': 'app', 'database': 'users'},
})

db.insert_user(12345, {'name': 'John', 'email': 'john@example.com'})
user = db.get_user(12345)
```

---

## Auto-Scaling

### Cloud Auto-Scaling (AWS)

```yaml
# Auto Scaling Group Configuration
LaunchTemplate:
  ImageId: ami-0c55b159cbfafe1f0
  InstanceType: t3.medium
  KeyName: my-key
  SecurityGroupIds:
    - sg-0123456789

AutoScalingGroup:
  MinSize: 2
  MaxSize: 10
  DesiredCapacity: 3
  HealthCheckGracePeriod: 300

ScalingPolicies:
  ScaleUp:
    MetricName: CPUUtilization
    Threshold: 70
    Adjustment: +2 instances

  ScaleDown:
    MetricName: CPUUtilization
    Threshold: 30
    Adjustment: -1 instance
```

---

## Summary

Load balancing and scaling are critical for building performant, highly available systems:

- **Start with Layer 7 load balancing** for flexibility
- **Use Round Robin or Least Connections** for most use cases
- **Design for horizontal scaling** from day one
- **Implement database replication** for read-heavy workloads
- **Consider sharding** when single database can't handle load
- **Use auto-scaling** to handle traffic variations efficiently

Choose strategies based on your application's specific needs, traffic patterns, and growth trajectory.
