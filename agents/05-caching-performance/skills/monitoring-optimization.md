# Performance Monitoring & Optimization

## Overview

Performance monitoring and optimization are continuous processes essential for maintaining healthy, efficient systems. This guide covers tools, techniques, and methodologies for identifying bottlenecks, monitoring system health, and systematically improving performance.

## Table of Contents

1. [APM (Application Performance Monitoring)](#apm)
2. [Profiling Tools & Techniques](#profiling)
3. [Bottleneck Identification](#bottlenecks)
4. [Performance Metrics](#metrics)
5. [Monitoring Strategies](#monitoring-strategies)
6. [Optimization Workflows](#optimization-workflows)
7. [Load Testing](#load-testing)

---

## APM (Application Performance Monitoring)

### What is APM?

Application Performance Monitoring provides comprehensive visibility into application performance, user experience, and system health through automated data collection and analysis.

### Key Components

```yaml
Core Components:
  1. Agents: Collect data from application
  2. Metrics Collection: Gather performance data
  3. Data Aggregation: Centralize and analyze
  4. Visualization: Dashboards and reports
  5. Alerting: Notify on issues
  6. Distributed Tracing: Track requests across services
```

### APM Architecture

```
┌─────────────────────────────────────────────────┐
│              Application Layer                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Service1 │  │ Service2 │  │ Service3 │     │
│  │  (APM    │  │  (APM    │  │  (APM    │     │
│  │  Agent)  │  │  Agent)  │  │  Agent)  │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
└───────┼─────────────┼─────────────┼────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
              ┌───────▼────────┐
              │  APM Platform  │
              │  ┌──────────┐  │
              │  │Collector │  │
              │  │Analytics │  │
              │  │Dashboard │  │
              │  │ Alerts   │  │
              │  └──────────┘  │
              └────────────────┘
```

---

### Distributed Tracing

**Purpose:** Track requests across microservices to identify latency and failures.

**Trace Structure:**
```
Trace ID: abc-123-def-456
│
├─ Span 1: API Gateway (10ms)
│   │
│   ├─ Span 2: Auth Service (5ms)
│   │
│   ├─ Span 3: User Service (120ms) ← SLOW!
│   │   │
│   │   └─ Span 4: Database Query (115ms) ← BOTTLENECK
│   │
│   └─ Span 5: Response Processing (3ms)
│
Total: 138ms
```

**Implementation (OpenTelemetry - Python):**
```python
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Initialize tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configure exporter
jaeger_exporter = JaegerExporter(
    agent_host_name="localhost",
    agent_port=6831,
)

trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

# Instrument code
def process_order(order_id):
    with tracer.start_as_current_span("process_order") as span:
        span.set_attribute("order.id", order_id)

        # Child span for validation
        with tracer.start_as_current_span("validate_order"):
            validate_order(order_id)

        # Child span for database
        with tracer.start_as_current_span("save_to_database"):
            db.save_order(order_id)

        # Child span for notification
        with tracer.start_as_current_span("send_notification"):
            send_email(order_id)

        return {"status": "success"}
```

**Implementation (Node.js):**
```javascript
const { trace } = require('@opentelemetry/api');
const tracer = trace.getTracer('my-service');

async function processOrder(orderId) {
  const span = tracer.startSpan('process_order');
  span.setAttribute('order.id', orderId);

  try {
    // Validate
    const validateSpan = tracer.startSpan('validate_order', { parent: span });
    await validateOrder(orderId);
    validateSpan.end();

    // Save to DB
    const dbSpan = tracer.startSpan('save_to_database', { parent: span });
    await db.saveOrder(orderId);
    dbSpan.end();

    // Send notification
    const notifySpan = tracer.startSpan('send_notification', { parent: span });
    await sendEmail(orderId);
    notifySpan.end();

    return { status: 'success' };
  } finally {
    span.end();
  }
}
```

---

### Popular APM Tools

#### Commercial Solutions

**1. Datadog**
```python
# Installation
pip install ddtrace

# Configuration
from ddtrace import tracer, patch_all
patch_all()  # Auto-instrument common libraries

# Custom instrumentation
@tracer.wrap('custom.operation')
def my_operation():
    with tracer.trace('database.query') as span:
        span.set_tag('query.type', 'SELECT')
        result = db.query('SELECT * FROM users')
    return result

# Run with
# ddtrace-run python app.py
```

**Features:**
- Full-stack observability
- 400+ integrations
- AI-powered alerts
- APM, logs, metrics in one platform
- Real User Monitoring (RUM)

**Pricing:** ~$15-31/host/month

---

**2. New Relic**
```python
# Installation
pip install newrelic

# Configuration (newrelic.ini)
[newrelic]
license_key = YOUR_LICENSE_KEY
app_name = My Application

# Instrument
import newrelic.agent
newrelic.agent.initialize('newrelic.ini')

@newrelic.agent.background_task()
def background_job():
    # Task code
    pass

@newrelic.agent.function_trace()
def slow_function():
    # Function to monitor
    pass
```

**Features:**
- AI-powered insights (Applied Intelligence)
- Full-stack monitoring
- Synthetic monitoring
- Mobile app monitoring
- Browser monitoring

**Pricing:** Free tier available, paid from $49/month

---

**3. Dynatrace**
```bash
# One-agent installation (auto-instruments everything)
wget -O Dynatrace-OneAgent.sh <download-url>
sudo /bin/sh Dynatrace-OneAgent.sh
```

**Features:**
- AI-powered root cause analysis
- Automatic discovery and instrumentation
- Digital Experience Monitoring
- Cloud automation
- Davis AI assistant

**Pricing:** Contact sales

---

#### Open Source Solutions

**1. SigNoz**
```yaml
# docker-compose.yml
version: '3.8'
services:
  signoz:
    image: signoz/signoz:latest
    ports:
      - "3301:3301"
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

```python
# Application instrumentation
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

trace.set_tracer_provider(TracerProvider())
otlp_exporter = OTLPSpanExporter(endpoint="localhost:4317")
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)
```

**Features:**
- Open-source Datadog alternative
- OpenTelemetry native
- Distributed tracing
- Metrics and logs
- Query builder
- Alerts

---

**2. Jaeger**
```bash
# Run all-in-one
docker run -d --name jaeger \
  -p 6831:6831/udp \
  -p 16686:16686 \
  jaegertracing/all-in-one:latest

# Access UI at http://localhost:16686
```

**Features:**
- CNCF project
- Excellent distributed tracing
- Service dependency analysis
- Root cause analysis
- Performance optimization

---

**3. Prometheus + Grafana**
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['localhost:8000']
```

```python
# Application metrics (Python)
from prometheus_client import Counter, Histogram, start_http_server
import time

# Define metrics
request_count = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')

@request_duration.time()
def handle_request(method, endpoint):
    request_count.labels(method=method, endpoint=endpoint).inc()
    # Handle request
    time.sleep(0.1)

# Start metrics server
start_http_server(8000)
```

**Grafana Dashboard Configuration:**
```json
{
  "dashboard": {
    "title": "Application Performance",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Response Time (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, http_request_duration_seconds_bucket)"
          }
        ]
      }
    ]
  }
}
```

---

## Profiling

### Types of Profiling

#### 1. CPU Profiling

**Identifies:** Which functions consume most CPU time

**Python (cProfile):**
```python
import cProfile
import pstats

def my_function():
    # Code to profile
    result = sum(i**2 for i in range(1000000))
    return result

# Profile
profiler = cProfile.Profile()
profiler.enable()
my_function()
profiler.disable()

# Print results
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(10)  # Top 10 functions
```

**Output:**
```
   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
        1    0.123    0.123    0.456    0.456 app.py:10(my_function)
  1000000    0.234    0.000    0.234    0.000 {built-in method builtins.sum}
  1000000    0.099    0.000    0.099    0.000 app.py:11(<genexpr>)
```

**Node.js (built-in profiler):**
```bash
# Start with profiling
node --prof app.js

# Generate report
node --prof-process isolate-0x*.log > profile.txt
```

**Go (pprof):**
```go
import (
    "net/http"
    _ "net/http/pprof"
    "runtime/pprof"
)

func main() {
    // Enable profiling endpoint
    go func() {
        http.ListenAndServe("localhost:6060", nil)
    }()

    // Your application code
}

// Access profiling at http://localhost:6060/debug/pprof/
```

```bash
# Generate CPU profile
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Visualize
go tool pprof -http=:8080 cpu.prof
```

---

#### 2. Memory Profiling

**Identifies:** Memory allocation patterns and leaks

**Python (memory_profiler):**
```python
from memory_profiler import profile

@profile
def memory_intensive_function():
    large_list = [i for i in range(1000000)]
    large_dict = {i: i**2 for i in range(100000)}
    return large_list, large_dict

memory_intensive_function()
```

**Output:**
```
Line #    Mem usage    Increment   Line Contents
================================================
     3   38.5 MiB     38.5 MiB   @profile
     4                           def memory_intensive_function():
     5   76.3 MiB     37.8 MiB       large_list = [i for i in range(1000000)]
     6  119.1 MiB     42.8 MiB       large_dict = {i: i**2 for i in range(100000)}
     7  119.1 MiB      0.0 MiB       return large_list, large_dict
```

**Node.js (heap snapshot):**
```javascript
const v8 = require('v8');
const fs = require('fs');

// Take heap snapshot
const heapSnapshot = v8.writeHeapSnapshot();
console.log(`Heap snapshot written to ${heapSnapshot}`);

// Analyze in Chrome DevTools
```

---

#### 3. I/O Profiling

**Python (py-spy):**
```bash
# Install
pip install py-spy

# Profile running process
sudo py-spy top --pid 12345

# Generate flame graph
sudo py-spy record -o profile.svg --pid 12345

# Profile during execution
py-spy record -o profile.svg -- python myapp.py
```

---

### Flame Graphs

**Visualization of profiling data showing call stacks and time spent**

```
Width = Time spent
Height = Stack depth

┌─────────────────────────────────────────────────┐ ─┐
│              main() - 100%                      │  │
├────────────┬──────────────┬─────────────────────┤  │
│process()   │ validate()   │    save()           │  ├─ Stack
│   40%      │    20%       │     40%             │  │  Depth
├─────┬──────┼──────┬───────┼──────┬──────────────┤  │
│db() │calc()│check()│parse()│query()│  commit()  │  │
│ 25% │ 15% │ 10%  │ 10%  │ 30%  │    10%      │ ─┘
└─────┴──────┴──────┴───────┴──────┴──────────────┘

Widest bars = Most time spent = Optimization targets
```

**Generate Flame Graph:**
```bash
# Using py-spy
py-spy record -o flamegraph.svg --format speedscope -- python app.py

# Using perf (Linux)
perf record -F 99 -a -g -- sleep 60
perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg
```

---

## Bottleneck Identification

### Systematic Approach

```
1. Establish Baseline
   ↓
2. Reproduce Issue
   ↓
3. Monitor & Measure
   ↓
4. Analyze Metrics
   ↓
5. Identify Bottleneck
   ↓
6. Optimize
   ↓
7. Measure Improvement
   ↓
8. Repeat
```

---

### Common Bottlenecks

#### 1. Database Bottleneck

**Symptoms:**
```yaml
Indicators:
  - High database CPU usage
  - Slow query execution times
  - Connection pool exhaustion
  - Lock contention
  - Disk I/O saturation
```

**Identification:**
```sql
-- MySQL: Show slow queries
SHOW VARIABLES LIKE 'slow_query%';
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;

-- View slow query log
SELECT * FROM mysql.slow_log;

-- Show running queries
SHOW PROCESSLIST;

-- Explain query
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';
```

**PostgreSQL:**
```sql
-- Enable pg_stat_statements
CREATE EXTENSION pg_stat_statements;

-- View slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Current activity
SELECT * FROM pg_stat_activity
WHERE state = 'active';
```

**Solutions:**
```python
# 1. Add indexes
CREATE INDEX idx_users_email ON users(email);

# 2. Optimize queries (avoid N+1)
# Bad
for user in users:
    orders = db.query(f"SELECT * FROM orders WHERE user_id = {user.id}")

# Good
users_with_orders = db.query("""
    SELECT u.*, o.*
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
""")

# 3. Connection pooling
from sqlalchemy import create_engine, pool

engine = create_engine(
    'postgresql://user:pass@localhost/db',
    poolclass=pool.QueuePool,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True
)

# 4. Query result caching
import redis
import json

cache = redis.Redis()

def get_user_orders(user_id):
    cache_key = f"user:{user_id}:orders"
    cached = cache.get(cache_key)

    if cached:
        return json.loads(cached)

    orders = db.query("SELECT * FROM orders WHERE user_id = ?", user_id)
    cache.setex(cache_key, 3600, json.dumps(orders))
    return orders
```

---

#### 2. Network Bottleneck

**Symptoms:**
```yaml
Indicators:
  - High network latency
  - Bandwidth saturation
  - Packet loss
  - Slow external API calls
```

**Monitoring:**
```bash
# Network statistics
netstat -i
ifconfig

# Bandwidth usage
iftop
nethogs

# Ping test
ping -c 10 api.example.com

# Traceroute
traceroute api.example.com

# DNS lookup time
dig example.com
```

**Solutions:**
```python
# 1. Enable compression
import gzip
import json

def compress_response(data):
    json_data = json.dumps(data)
    compressed = gzip.compress(json_data.encode())
    return compressed

# 2. Use HTTP/2
# In your web server configuration (Nginx)
# listen 443 ssl http2;

# 3. Connection pooling for HTTP
import requests
from requests.adapters import HTTPAdapter

session = requests.Session()
adapter = HTTPAdapter(
    pool_connections=10,
    pool_maxsize=20,
    max_retries=3
)
session.mount('http://', adapter)
session.mount('https://', adapter)

# 4. Reduce payload size
def minimize_payload(data):
    return {k: v for k, v in data.items() if v is not None}

# 5. Implement caching
@cache.cached(timeout=300)
def fetch_external_api(endpoint):
    return session.get(endpoint).json()
```

---

#### 3. CPU Bottleneck

**Identification:**
```bash
# CPU usage
top
htop

# Per-process CPU
ps aux --sort=-%cpu | head -10

# CPU info
lscpu
cat /proc/cpuinfo
```

**Profiling:**
```python
import cProfile
import time

def cpu_intensive_task():
    result = 0
    for i in range(1000000):
        result += i ** 2
    return result

# Profile
cProfile.run('cpu_intensive_task()')
```

**Solutions:**
```python
# 1. Optimize algorithms
# Bad: O(n²)
def find_duplicates_slow(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j]:
                duplicates.append(items[i])
    return duplicates

# Good: O(n)
def find_duplicates_fast(items):
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return list(duplicates)

# 2. Use caching
from functools import lru_cache

@lru_cache(maxsize=1000)
def expensive_calculation(n):
    if n <= 1:
        return n
    return expensive_calculation(n-1) + expensive_calculation(n-2)

# 3. Parallel processing
from multiprocessing import Pool

def process_item(item):
    # CPU-intensive processing
    return item ** 2

with Pool(4) as pool:
    results = pool.map(process_item, range(1000000))

# 4. Use compiled extensions (Cython, numba)
import numba

@numba.jit(nopython=True)
def fast_computation(n):
    result = 0
    for i in range(n):
        result += i ** 2
    return result
```

---

#### 4. Memory Bottleneck

**Monitoring:**
```bash
# Memory usage
free -h
vmstat 1

# Per-process memory
ps aux --sort=-%mem | head -10

# Detailed memory info
cat /proc/meminfo
```

**Python Memory Debugging:**
```python
import tracemalloc

tracemalloc.start()

# Your code here
large_list = [i for i in range(1000000)]

current, peak = tracemalloc.get_traced_memory()
print(f"Current memory: {current / 10**6:.1f} MB")
print(f"Peak memory: {peak / 10**6:.1f} MB")

# Get top memory consumers
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

for stat in top_stats[:10]:
    print(stat)

tracemalloc.stop()
```

**Solutions:**
```python
# 1. Use generators instead of lists
# Bad: Loads everything into memory
def get_all_records():
    return [record for record in database.query("SELECT * FROM huge_table")]

# Good: Yields one at a time
def get_records_generator():
    for record in database.query("SELECT * FROM huge_table"):
        yield record

# 2. Implement pagination
def get_paginated_results(page=1, page_size=100):
    offset = (page - 1) * page_size
    return database.query(
        f"SELECT * FROM table LIMIT {page_size} OFFSET {offset}"
    )

# 3. Stream large files
def process_large_file(filename):
    with open(filename, 'r') as f:
        for line in f:  # Reads one line at a time
            process_line(line)

# 4. Clear unused references
import gc

large_object = load_large_dataset()
process(large_object)
del large_object
gc.collect()  # Force garbage collection
```

---

## Performance Metrics

### Golden Signals

```yaml
1. Latency:
   - p50 (median): 50% of requests faster than this
   - p95: 95% of requests faster than this
   - p99: 99% of requests faster than this
   - p99.9: 99.9% of requests faster than this

2. Traffic:
   - Requests per second
   - Bytes per second
   - Concurrent users

3. Errors:
   - Error rate (%)
   - Error types (4xx, 5xx)
   - Failed requests

4. Saturation:
   - CPU usage
   - Memory usage
   - Disk I/O
   - Network bandwidth
```

### Application Metrics

```python
from prometheus_client import Counter, Histogram, Gauge, Summary
import time

# Counter: Monotonically increasing
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

# Histogram: Observations in buckets
request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

# Gauge: Value that can go up or down
active_users = Gauge('active_users', 'Number of active users')
memory_usage = Gauge('memory_usage_bytes', 'Memory usage in bytes')

# Summary: Similar to histogram, calculates quantiles
request_size = Summary(
    'http_request_size_bytes',
    'HTTP request size'
)

# Usage
@app.route('/api/users')
def get_users():
    start = time.time()

    try:
        users = database.get_users()
        http_requests_total.labels(method='GET', endpoint='/api/users', status='200').inc()
        return users
    except Exception as e:
        http_requests_total.labels(method='GET', endpoint='/api/users', status='500').inc()
        raise
    finally:
        duration = time.time() - start
        request_duration.labels(method='GET', endpoint='/api/users').observe(duration)
```

### Database Metrics

```python
import psycopg2
from prometheus_client import Gauge

# Connection pool metrics
db_connections_active = Gauge('db_connections_active', 'Active database connections')
db_connections_idle = Gauge('db_connections_idle', 'Idle database connections')
db_query_duration = Histogram('db_query_duration_seconds', 'Database query duration')

def monitor_database():
    conn = psycopg2.connect(database="mydb")
    cur = conn.cursor()

    # Get connection stats
    cur.execute("""
        SELECT state, count(*)
        FROM pg_stat_activity
        GROUP BY state
    """)

    for state, count in cur.fetchall():
        if state == 'active':
            db_connections_active.set(count)
        elif state == 'idle':
            db_connections_idle.set(count)
```

### Cache Metrics

```python
cache_hits = Counter('cache_hits_total', 'Cache hits')
cache_misses = Counter('cache_misses_total', 'Cache misses')
cache_size = Gauge('cache_size_bytes', 'Cache size in bytes')

def get_with_cache(key):
    value = cache.get(key)

    if value:
        cache_hits.inc()
        return value

    cache_misses.inc()
    value = database.get(key)
    cache.set(key, value)
    return value

# Calculate hit rate
def get_cache_hit_rate():
    hits = cache_hits._value.get()
    misses = cache_misses._value.get()
    total = hits + misses

    if total == 0:
        return 0

    return (hits / total) * 100
```

---

## Monitoring Strategies

### Infrastructure Monitoring

```yaml
# Prometheus configuration
global:
  scrape_interval: 15s

scrape_configs:
  # Node exporter (system metrics)
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  # Application metrics
  - job_name: 'app'
    static_configs:
      - targets: ['localhost:8000']

  # Database metrics
  - job_name: 'postgres'
    static_configs:
      - targets: ['localhost:9187']

  # Redis metrics
  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']
```

### Alerting Rules

```yaml
# prometheus_alerts.yml
groups:
  - name: performance_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}% over last 5 minutes"

      # High latency
      - alert: HighLatency
        expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
          description: "P95 latency is {{ $value }}s"

      # High CPU usage
      - alert: HighCPU
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"

      # High memory usage
      - alert: HighMemory
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value }}%"

      # Database connection pool exhaustion
      - alert: DatabasePoolExhaustion
        expr: db_connections_active / db_connections_max > 0.9
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Database connection pool near exhaustion"
```

---

## Optimization Workflows

### Performance Optimization Process

```
1. Baseline Measurement
   ├─ Current metrics
   ├─ Performance targets
   └─ Acceptable thresholds

2. Profiling
   ├─ CPU profiling
   ├─ Memory profiling
   ├─ I/O profiling
   └─ Network profiling

3. Bottleneck Identification
   ├─ Analyze profiling data
   ├─ Review metrics
   ├─ Identify slowest components
   └─ Prioritize by impact

4. Optimization
   ├─ Algorithm improvement
   ├─ Caching implementation
   ├─ Query optimization
   ├─ Resource allocation
   └─ Code refactoring

5. Testing
   ├─ Load testing
   ├─ Stress testing
   ├─ Benchmark comparison
   └─ Regression testing

6. Deployment
   ├─ Gradual rollout
   ├─ Monitor metrics
   ├─ A/B testing
   └─ Rollback plan

7. Measurement
   ├─ Compare to baseline
   ├─ Verify improvements
   ├─ Document changes
   └─ Iterate if needed
```

---

## Load Testing

### Apache JMeter

```xml
<!-- test-plan.jmx -->
<jmeterTestPlan>
  <TestPlan>
    <ThreadGroup>
      <numThreads>100</numThreads>
      <rampTime>10</rampTime>
      <loopCount>1000</loopCount>
    </ThreadGroup>

    <HTTPSampler>
      <domain>api.example.com</domain>
      <port>443</port>
      <protocol>https</protocol>
      <path>/api/users</path>
      <method>GET</method>
    </HTTPSampler>
  </TestPlan>
</jmeterTestPlan>
```

```bash
# Run test
jmeter -n -t test-plan.jmx -l results.jtl -e -o report/
```

---

### k6 (Modern Load Testing)

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Ramp-up to 50 users
    { duration: '3m', target: 50 },   // Stay at 50 users
    { duration: '1m', target: 100 },  // Ramp-up to 100 users
    { duration: '3m', target: 100 },  // Stay at 100 users
    { duration: '1m', target: 0 },    // Ramp-down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500'],  // 95% of requests < 500ms
    'errors': ['rate<0.1'],               // Error rate < 10%
  },
};

export default function() {
  const res = http.get('https://api.example.com/users');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  }) || errorRate.add(1);

  sleep(1);
}
```

```bash
# Run test
k6 run load-test.js

# With output to InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 load-test.js
```

---

### Locust (Python)

```python
# locustfile.py
from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)  # Wait 1-3 seconds between tasks

    @task(3)  # Weight: 3x more likely than other tasks
    def get_users(self):
        self.client.get("/api/users")

    @task(1)
    def create_user(self):
        self.client.post("/api/users", json={
            "name": "Test User",
            "email": "test@example.com"
        })

    @task(2)
    def get_user_profile(self):
        user_id = 123
        self.client.get(f"/api/users/{user_id}")

    def on_start(self):
        # Login before starting tests
        self.client.post("/login", json={
            "username": "test",
            "password": "test123"
        })
```

```bash
# Run Locust
locust -f locustfile.py --host=https://api.example.com

# Headless mode
locust -f locustfile.py --host=https://api.example.com \
  --users 100 --spawn-rate 10 --run-time 10m --headless
```

---

## Summary

Effective performance monitoring and optimization requires:

1. **Comprehensive Monitoring:** Implement APM and collect all relevant metrics
2. **Proactive Profiling:** Regular profiling to identify issues before they impact users
3. **Systematic Approach:** Follow structured bottleneck identification process
4. **Continuous Testing:** Regular load testing and benchmarking
5. **Iterative Optimization:** Measure, optimize, measure again

**Best Practices:**
- Monitor at all layers (application, infrastructure, database)
- Set up meaningful alerts
- Use percentiles (p95, p99) not just averages
- Profile in production (with minimal overhead)
- Load test before major releases
- Document optimization efforts
- Create performance budgets
- Automate monitoring and alerting

Performance optimization is an ongoing journey, not a destination.
