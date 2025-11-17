# Monitoring & Observability

## Table of Contents
1. [Introduction to Observability](#introduction-to-observability)
2. [The Three Pillars of Observability](#the-three-pillars-of-observability)
3. [Metrics and Monitoring](#metrics-and-monitoring)
4. [Logging Infrastructure](#logging-infrastructure)
5. [Distributed Tracing](#distributed-tracing)
6. [Application Performance Monitoring (APM)](#application-performance-monitoring-apm)
7. [Alerting and Incident Response](#alerting-and-incident-response)
8. [SLI, SLO, and SLA](#sli-slo-and-sla)
9. [Debugging and Troubleshooting](#debugging-and-troubleshooting)

---

## Introduction to Observability

### Monitoring vs. Observability

**Monitoring**:
- Tells you **what** is broken
- Based on predefined metrics and alerts
- Reactive approach
- Known knowns and known unknowns

**Observability**:
- Tells you **why** it's broken
- Allows asking arbitrary questions
- Proactive approach
- Helps discover unknown unknowns

### Why Observability Matters

**Without Observability**:
```
User: "The app is slow!"
Dev: "Where? When? What did you do?"
User: "I don't know, it's just slow..."
Dev: *Starts guessing* 🤷
```

**With Observability**:
```
Alert: High latency detected
Dev: *Checks metrics* → Spike in database queries
     *Checks traces* → Slow query: SELECT * FROM users
     *Checks logs* → N+1 query issue in posts endpoint
     *Deploys fix* → Problem solved ✅
```

### Business Impact

- **Reduced MTTR** (Mean Time To Resolution): From hours to minutes
- **Improved Uptime**: Proactive issue detection
- **Better User Experience**: Identify and fix performance issues
- **Cost Optimization**: Find resource waste and inefficiencies
- **Data-Driven Decisions**: Performance insights guide development

---

## The Three Pillars of Observability

```
┌─────────────────────────────────────────────────────┐
│         The Three Pillars of Observability          │
├─────────────────────────────────────────────────────┤
│                                                      │
│   METRICS          LOGS             TRACES          │
│   (What)          (Why)            (Where)          │
│                                                      │
│   Request rate    Error message    Request flow     │
│   Latency P99     Stack trace      Service map      │
│   CPU/Memory      Context          Bottlenecks      │
│   Error rate      Events           Dependencies     │
│                                                      │
│   When: Always    When: Errors     When: Debugging  │
│   Format: Numbers Format: Text     Format: Spans    │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### How They Work Together

1. **Metrics** alert you to a problem
2. **Logs** provide context and error details
3. **Traces** show the exact request path and bottleneck

**Example Workflow**:
```
1. Metric: "API latency P95 > 500ms" (ALERT!)
2. Check logs: "Database timeout on /api/posts"
3. Check trace: Shows 5-second database query
4. Fix: Add database index
5. Verify: Metric returns to normal
```

---

## Metrics and Monitoring

### What are Metrics?

**Definition**: Numerical measurements of system behavior over time.

**Types of Metrics**:
- **Counter**: Monotonically increasing value (requests served, errors)
- **Gauge**: Value that can go up or down (CPU usage, active connections)
- **Histogram**: Distribution of values (request latency percentiles)
- **Summary**: Similar to histogram, with quantiles

### The Golden Signals (Google SRE)

**4 metrics to monitor for user-facing systems**:

1. **Latency**: How long requests take
   - Measure P50, P95, P99 percentiles
   - Separate successful vs. failed requests

2. **Traffic**: Demand on your system
   - Requests per second
   - Transactions per second
   - Active users

3. **Errors**: Rate of failed requests
   - HTTP 5xx errors
   - HTTP 4xx errors (client errors)
   - Application exceptions

4. **Saturation**: How "full" your service is
   - CPU usage
   - Memory usage
   - Disk usage
   - Connection pool utilization

### Prometheus (Metrics Collection)

**Installation (Docker Compose)**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  prometheus-data:
  grafana-data:
```

**Prometheus Configuration (prometheus.yml)**:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Scrape Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Scrape your application
  - job_name: 'node-app'
    static_configs:
      - targets: ['app:3000']

  # Scrape Node Exporter (system metrics)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

**Instrumenting Node.js Application**:
```javascript
const express = require('express');
const promClient = require('prom-client');

const app = express();

// Create a Registry
const register = new promClient.Registry();

// Add default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 1, 1.5, 2, 3, 5]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new promClient.Gauge({
  name: 'http_active_connections',
  help: 'Number of active HTTP connections'
});

const databaseQueryDuration = new promClient.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries',
  labelNames: ['query_type'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

// Register metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(activeConnections);
register.registerMetric(databaseQueryDuration);

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();

  activeConnections.inc();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;

    httpRequestDuration.labels(
      req.method,
      req.route?.path || req.path,
      res.statusCode
    ).observe(duration);

    httpRequestTotal.labels(
      req.method,
      req.route?.path || req.path,
      res.statusCode
    ).inc();

    activeConnections.dec();
  });

  next();
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Example: Track database query duration
async function queryDatabase(sql, params) {
  const start = Date.now();

  try {
    const result = await db.query(sql, params);

    databaseQueryDuration.labels('select').observe((Date.now() - start) / 1000);

    return result;
  } catch (error) {
    databaseQueryDuration.labels('error').observe((Date.now() - start) / 1000);
    throw error;
  }
}
```

**Python (Flask) Example**:
```python
from flask import Flask, request
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import time

app = Flask(__name__)

# Metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

ACTIVE_REQUESTS = Gauge(
    'http_requests_active',
    'Active HTTP requests'
)

@app.before_request
def before_request():
    ACTIVE_REQUESTS.inc()
    request.start_time = time.time()

@app.after_request
def after_request(response):
    latency = time.time() - request.start_time

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint,
        status=response.status_code
    ).inc()

    REQUEST_LATENCY.labels(
        method=request.method,
        endpoint=request.endpoint
    ).observe(latency)

    ACTIVE_REQUESTS.dec()

    return response

@app.route('/metrics')
def metrics():
    return generate_latest()
```

### Grafana (Visualization)

**Dashboard Example (JSON)**:
```json
{
  "dashboard": {
    "title": "API Performance",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Latency (P95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status_code=~\"5..\"}[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Active Connections",
        "targets": [
          {
            "expr": "http_active_connections"
          }
        ],
        "type": "stat"
      }
    ]
  }
}
```

**PromQL Queries (Prometheus Query Language)**:
```promql
# Request rate (requests per second)
rate(http_requests_total[5m])

# Error rate (percentage)
rate(http_requests_total{status_code=~"5.."}[5m]) /
rate(http_requests_total[5m]) * 100

# P95 latency
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket[5m])
)

# Top 5 slowest endpoints
topk(5,
  histogram_quantile(0.95,
    rate(http_request_duration_seconds_bucket[5m])
  ) by (route)
)

# CPU usage by service
avg by (service) (rate(process_cpu_seconds_total[5m]))

# Memory usage
process_resident_memory_bytes / 1024 / 1024
```

### RED Method

**For Request-Driven Services**:
1. **Rate**: Requests per second
2. **Errors**: Failed requests per second
3. **Duration**: Latency distribution

```promql
# Rate
rate(http_requests_total[5m])

# Errors
rate(http_requests_total{status=~"5.."}[5m])

# Duration (P99)
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

### USE Method

**For Resource-Focused Metrics**:
1. **Utilization**: % of time resource is busy
2. **Saturation**: Amount of work resource can't handle
3. **Errors**: Count of error events

```promql
# CPU Utilization
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Utilization
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) /
node_memory_MemTotal_bytes * 100

# Disk Saturation (queue depth)
node_disk_io_time_weighted_seconds_total
```

---

## Logging Infrastructure

### Structured Logging

**Why Structured Logging?**
- ✅ Machine-readable (JSON)
- ✅ Easy to query and filter
- ✅ Consistent format
- ✅ Rich context

**Bad (Unstructured)**:
```javascript
console.log('User john@example.com logged in from 192.168.1.1');
// Hard to parse, query, or alert on
```

**Good (Structured)**:
```javascript
logger.info('User login', {
  event: 'user_login',
  userId: 123,
  email: 'john@example.com',
  ipAddress: '192.168.1.1',
  timestamp: new Date().toISOString(),
  userAgent: req.get('user-agent')
});

// Output:
{
  "level": "info",
  "message": "User login",
  "event": "user_login",
  "userId": 123,
  "email": "john@example.com",
  "ipAddress": "192.168.1.1",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "userAgent": "Mozilla/5.0..."
}
```

### Winston (Node.js Logger)

**Setup**:
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'api-server',
    environment: process.env.NODE_ENV
  },
  transports: [
    // Write to console
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),

    // Write errors to file
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),

    // Write all logs to file
    new winston.transports.File({
      filename: 'logs/combined.log',
      maxsize: 10485760,
      maxFiles: 10
    })
  ]
});

module.exports = logger;
```

**Usage**:
```javascript
const logger = require('./logger');

// Different log levels
logger.error('Database connection failed', {
  error: err.message,
  stack: err.stack,
  database: 'postgres'
});

logger.warn('High memory usage', {
  memoryUsage: process.memoryUsage().heapUsed,
  threshold: 500 * 1024 * 1024
});

logger.info('User created', {
  userId: user.id,
  email: user.email
});

logger.debug('Cache hit', {
  key: cacheKey,
  ttl: 3600
});
```

**Correlation IDs** (Track requests across services):
```javascript
const { v4: uuidv4 } = require('uuid');

// Middleware to add correlation ID
app.use((req, res, next) => {
  req.correlationId = req.get('X-Correlation-ID') || uuidv4();
  res.set('X-Correlation-ID', req.correlationId);

  // Add to logger context
  req.logger = logger.child({ correlationId: req.correlationId });

  next();
});

// Use in routes
app.post('/api/users', async (req, res) => {
  req.logger.info('Creating user', { email: req.body.email });

  try {
    const user = await createUser(req.body);
    req.logger.info('User created successfully', { userId: user.id });
    res.status(201).json(user);
  } catch (error) {
    req.logger.error('Failed to create user', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

### Python Logging

**Setup**:
```python
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }

        if hasattr(record, 'extra'):
            log_data.update(record.extra)

        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)

        return json.dumps(log_data)

# Configure logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger.addHandler(handler)

# Usage
logger.info('User login', extra={
    'user_id': 123,
    'email': 'user@example.com',
    'ip': '192.168.1.1'
})
```

### ELK Stack (Elasticsearch, Logstash, Kibana)

**Docker Compose Setup**:
```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - es-data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5000:5000"
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  es-data:
```

**Logstash Configuration (logstash.conf)**:
```ruby
input {
  tcp {
    port => 5000
    codec => json
  }

  http {
    port => 8080
  }
}

filter {
  # Parse timestamp
  date {
    match => [ "timestamp", "ISO8601" ]
    target => "@timestamp"
  }

  # Add GeoIP data for IP addresses
  if [ipAddress] {
    geoip {
      source => "ipAddress"
    }
  }

  # Parse user agent
  if [userAgent] {
    useragent {
      source => "userAgent"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }

  # Also output to console for debugging
  stdout {
    codec => rubydebug
  }
}
```

**Ship Logs to Logstash (Winston)**:
```javascript
const winston = require('winston');
require('winston-logstash');

const logger = winston.createLogger({
  transports: [
    new winston.transports.Logstash({
      host: 'logstash',
      port: 5000,
      node_name: 'api-server',
      max_connect_retries: -1
    })
  ]
});
```

### Grafana Loki (Lightweight Alternative to ELK)

**Loki Configuration**:
```yaml
# docker-compose.yml
services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - loki-data:/loki

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - ./promtail-config.yaml:/etc/promtail/config.yaml
    command: -config.file=/etc/promtail/config.yaml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  loki-data:
  grafana-data:
```

**Promtail Configuration (promtail-config.yaml)**:
```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: app-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: app-logs
          __path__: /var/log/app/*.log

    pipeline_stages:
      - json:
          expressions:
            level: level
            message: message
            correlationId: correlationId

      - labels:
          level:
          correlationId:
```

**Query Logs in Grafana**:
```logql
# All error logs
{job="app-logs"} |= "error"

# Logs for specific correlation ID
{job="app-logs"} | correlationId="abc-123"

# Count errors per minute
rate({job="app-logs", level="error"}[1m])

# Parse JSON and filter
{job="app-logs"} | json | userId="123"
```

### Logging Best Practices

**1. Use Appropriate Log Levels**:
```javascript
// FATAL/CRITICAL: System unusable
logger.fatal('Database unreachable, shutting down');

// ERROR: Errors that need attention
logger.error('Failed to process payment', { orderId: 123, error: err });

// WARN: Potentially harmful situations
logger.warn('Cache miss rate high', { missRate: 0.8 });

// INFO: Informational messages
logger.info('User registered', { userId: user.id });

// DEBUG: Detailed debugging information
logger.debug('Cache lookup', { key: 'user:123', hit: false });

// TRACE: Very detailed diagnostic information
logger.trace('Function entry', { args: arguments });
```

**2. Don't Log Sensitive Data**:
```javascript
// BAD
logger.info('User login', {
  password: req.body.password,  // ❌ Never log passwords
  creditCard: user.creditCard,  // ❌ Never log payment info
  ssn: user.ssn                 // ❌ Never log PII
});

// GOOD
logger.info('User login', {
  userId: user.id,
  email: user.email,
  timestamp: new Date()
});
```

**3. Include Context**:
```javascript
// BAD: Vague, no context
logger.error('Query failed');

// GOOD: Specific, actionable
logger.error('Database query failed', {
  query: 'SELECT * FROM users WHERE id = ?',
  params: [userId],
  error: err.message,
  stack: err.stack,
  duration: queryDuration,
  database: 'postgres'
});
```

**4. Log Retention**:
```javascript
// Rotate logs based on size and time
const dailyRotateFile = new winston.transports.DailyRotateFile({
  filename: 'logs/app-%DATE%.log',
  datePattern: 'YYYY-MM-DD',
  maxSize: '20m',
  maxFiles: '30d',  // Keep 30 days
  compress: true     // Compress old logs
});
```

---

## Distributed Tracing

### What is Distributed Tracing?

**Definition**: Following a request as it flows through multiple services in a distributed system.

**Trace Structure**:
```
Trace (end-to-end request)
  ├── Span 1: API Gateway (10ms)
  │   └── Span 2: Auth Service (5ms)
  ├── Span 3: Order Service (50ms)
  │   ├── Span 4: Database Query (30ms)
  │   └── Span 5: Inventory Service (15ms)
  └── Span 6: Notification Service (20ms)

Total: 85ms (but only 50ms critical path)
```

### OpenTelemetry (Industry Standard)

**Installation (Node.js)**:
```bash
npm install @opentelemetry/sdk-node \
  @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-jaeger
```

**Instrumentation (tracing.js)**:
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const jaegerExporter = new JaegerExporter({
  endpoint: 'http://localhost:14268/api/traces'
});

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'api-server',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0'
  }),
  traceExporter: jaegerExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': {
        enabled: false
      }
    })
  ]
});

sdk.start();

process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
```

**Start App with Tracing**:
```javascript
// app.js
require('./tracing');  // Must be first!

const express = require('express');
const app = express();

// Your application code...
```

**Manual Instrumentation**:
```javascript
const { trace } = require('@opentelemetry/api');

const tracer = trace.getTracer('api-server', '1.0.0');

async function processOrder(orderId) {
  // Create a span
  const span = tracer.startSpan('processOrder');

  span.setAttributes({
    'order.id': orderId,
    'order.type': 'online'
  });

  try {
    // Child span for database query
    const dbSpan = tracer.startSpan('database.query', {
      parent: span
    });

    const order = await db.query('SELECT * FROM orders WHERE id = ?', [orderId]);
    dbSpan.end();

    // Add event to span
    span.addEvent('Order retrieved', {
      'order.status': order.status
    });

    // Process order logic...

    span.setStatus({ code: SpanStatusCode.OK });
  } catch (error) {
    span.recordException(error);
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error.message
    });
    throw error;
  } finally {
    span.end();
  }
}
```

### Jaeger (Tracing Backend)

**Docker Setup**:
```bash
docker run -d --name jaeger \
  -e COLLECTOR_ZIPKIN_HOST_PORT=:9411 \
  -p 5775:5775/udp \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 14268:14268 \
  -p 14250:14250 \
  -p 9411:9411 \
  jaegertracing/all-in-one:latest
```

**Access Jaeger UI**: http://localhost:16686

### Distributed Tracing Best Practices

**1. Context Propagation** (pass trace context between services):
```javascript
// Service A: Inject trace context into HTTP header
const axios = require('axios');
const { context, propagation } = require('@opentelemetry/api');

async function callServiceB() {
  const headers = {};

  // Inject current trace context into headers
  propagation.inject(context.active(), headers);

  const response = await axios.get('http://service-b/api/data', {
    headers: {
      ...headers,
      'Content-Type': 'application/json'
    }
  });

  return response.data;
}

// Service B: Extract trace context from headers
app.use((req, res, next) => {
  const extractedContext = propagation.extract(context.active(), req.headers);

  context.with(extractedContext, () => {
    next();
  });
});
```

**2. Sample Traces** (Don't trace every request in high-traffic systems):
```javascript
const { TraceIdRatioBasedSampler } = require('@opentelemetry/sdk-trace-base');

const sdk = new NodeSDK({
  sampler: new TraceIdRatioBasedSampler(0.1),  // Sample 10% of traces
  // ...
});
```

**3. Add Useful Attributes**:
```javascript
span.setAttributes({
  'http.method': req.method,
  'http.url': req.url,
  'http.status_code': res.statusCode,
  'user.id': req.user?.id,
  'db.statement': sqlQuery,
  'db.name': 'postgres',
  'cache.hit': cacheHit,
  'custom.business_metric': orderValue
});
```

---

## Application Performance Monitoring (APM)

### What is APM?

**Features**:
- Automatic instrumentation
- Transaction tracing
- Error tracking
- Database query monitoring
- External service monitoring
- Real user monitoring (RUM)
- Infrastructure metrics

### Datadog APM

**Installation (Node.js)**:
```bash
npm install dd-trace
```

**Instrumentation**:
```javascript
// Must be first!
const tracer = require('dd-trace').init({
  service: 'api-server',
  env: process.env.NODE_ENV,
  version: '1.0.0',
  logInjection: true,
  analytics: true,
  runtimeMetrics: true
});

const express = require('express');
const app = express();

// Your application code...
```

**Custom Spans**:
```javascript
const tracer = require('dd-trace');

async function processPayment(payment) {
  const span = tracer.startSpan('payment.process', {
    tags: {
      'payment.amount': payment.amount,
      'payment.currency': payment.currency,
      'payment.method': payment.method
    }
  });

  try {
    const result = await paymentGateway.charge(payment);

    span.setTag('payment.id', result.id);
    span.setTag('payment.status', result.status);

    return result;
  } catch (error) {
    span.setTag('error', true);
    span.setTag('error.message', error.message);
    span.setTag('error.stack', error.stack);
    throw error;
  } finally {
    span.finish();
  }
}
```

### New Relic APM

**Installation**:
```bash
npm install newrelic
```

**Configuration (newrelic.js)**:
```javascript
exports.config = {
  app_name: ['API Server'],
  license_key: process.env.NEW_RELIC_LICENSE_KEY,
  logging: {
    level: 'info'
  },
  transaction_tracer: {
    enabled: true,
    transaction_threshold: 'apdex_f',
    record_sql: 'obfuscated',
    explain_threshold: 500
  },
  error_collector: {
    enabled: true,
    ignore_status_codes: [404]
  },
  distributed_tracing: {
    enabled: true
  }
};
```

**Start App**:
```javascript
require('newrelic');  // Must be first!
const express = require('express');
// ...
```

**Custom Transactions**:
```javascript
const newrelic = require('newrelic');

async function processOrder(orderId) {
  newrelic.setTransactionName('Order/Process');

  newrelic.addCustomAttribute('orderId', orderId);
  newrelic.addCustomAttribute('orderType', 'online');

  try {
    const order = await getOrder(orderId);
    const result = await fulfillOrder(order);

    newrelic.recordMetric('Custom/OrderValue', order.totalValue);

    return result;
  } catch (error) {
    newrelic.noticeError(error, {
      orderId: orderId,
      customAttribute: 'value'
    });
    throw error;
  }
}
```

### Sentry (Error Tracking)

**Installation**:
```bash
npm install @sentry/node @sentry/profiling-node
```

**Setup**:
```javascript
const Sentry = require('@sentry/node');
const { ProfilingIntegration } = require('@sentry/profiling-node');

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  release: process.env.GIT_SHA,
  tracesSampleRate: 1.0,
  profilesSampleRate: 1.0,
  integrations: [
    new ProfilingIntegration()
  ]
});

// Express middleware
app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.tracingHandler());

// Your routes...

// Error handler (must be after routes)
app.use(Sentry.Handlers.errorHandler());
```

**Capture Errors with Context**:
```javascript
try {
  await processPayment(payment);
} catch (error) {
  Sentry.captureException(error, {
    tags: {
      payment_method: payment.method,
      payment_gateway: 'stripe'
    },
    extra: {
      payment_id: payment.id,
      amount: payment.amount,
      currency: payment.currency
    },
    user: {
      id: user.id,
      email: user.email
    }
  });

  throw error;
}
```

**Breadcrumbs** (track events leading to error):
```javascript
Sentry.addBreadcrumb({
  category: 'auth',
  message: 'User logged in',
  level: 'info',
  data: {
    userId: user.id,
    loginMethod: 'password'
  }
});

// Later, if error occurs, breadcrumbs are included
```

---

## Alerting and Incident Response

### Alerting Best Practices

**1. Alert on Symptoms, Not Causes**:
```yaml
# BAD: Alert on CPU usage
- alert: HighCPU
  expr: cpu_usage > 80
  # CPU might be high for good reasons (traffic spike)

# GOOD: Alert on user impact
- alert: HighLatency
  expr: http_request_duration_seconds{quantile="0.95"} > 1
  for: 5m
  annotations:
    summary: "API latency is high"
    description: "P95 latency is {{ $value }}s for 5 minutes"
```

**2. Set Appropriate Thresholds**:
```yaml
# Avoid alert fatigue
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.01  # 1% error rate
  for: 5m  # Sustained for 5 minutes
  labels:
    severity: warning
  annotations:
    summary: "Error rate above 1%"
```

**3. Include Runbooks in Alerts**:
```yaml
- alert: DatabaseConnectionPoolExhausted
  expr: database_connections_active / database_connections_max > 0.9
  annotations:
    summary: "Database connection pool nearly full"
    description: "{{ $value }}% of connections in use"
    runbook: "https://wiki.company.com/runbooks/database-connections"
```

### Prometheus Alerting Rules

**Configuration (alert.rules.yml)**:
```yaml
groups:
  - name: api_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          rate(http_requests_total{status=~"5.."}[5m]) /
          rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High HTTP error rate"
          description: "Error rate is {{ $value | humanizePercentage }}"

      # High latency
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95,
            rate(http_request_duration_seconds_bucket[5m])
          ) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High API latency"
          description: "P95 latency is {{ $value }}s"

      # Service down
      - alert: ServiceDown
        expr: up{job="api-server"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service is down"
          description: "{{ $labels.instance }} has been down for 1 minute"

      # Database connection issues
      - alert: DatabaseConnectionFailures
        expr: rate(database_connection_errors_total[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Database connection failures"

      # High memory usage
      - alert: HighMemoryUsage
        expr: |
          (process_resident_memory_bytes /
          on(instance) group_left node_memory_MemTotal_bytes) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"
```

### Alertmanager Configuration

**Configuration (alertmanager.yml)**:
```yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'team-notifications'

  routes:
    # Critical alerts → PagerDuty
    - match:
        severity: critical
      receiver: pagerduty
      continue: true

    # Critical alerts → Slack #incidents
    - match:
        severity: critical
      receiver: slack-incidents

    # Warning alerts → Slack #alerts
    - match:
        severity: warning
      receiver: slack-alerts

receivers:
  - name: 'team-notifications'
    email_configs:
      - to: 'team@example.com'

  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
        description: '{{ .GroupLabels.alertname }}'

  - name: 'slack-incidents'
    slack_configs:
      - channel: '#incidents'
        title: '🚨 {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        send_resolved: true

  - name: 'slack-alerts'
    slack_configs:
      - channel: '#alerts'
        title: '⚠️ {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

### Incident Response Workflow

**1. Detection** (Automated)
```
Alert fired → Notification sent → On-call engineer paged
```

**2. Triage** (5-15 minutes)
```javascript
// Incident severity classification
const SEVERITY = {
  SEV1: {
    name: 'Critical',
    criteria: 'Complete service outage or data loss',
    responseTime: '15 minutes',
    escalation: 'Immediate'
  },
  SEV2: {
    name: 'High',
    criteria: 'Major functionality impaired',
    responseTime: '1 hour',
    escalation: 'Within 30 minutes'
  },
  SEV3: {
    name: 'Medium',
    criteria: 'Minor functionality impaired',
    responseTime: '4 hours',
    escalation: 'Next business day'
  },
  SEV4: {
    name: 'Low',
    criteria: 'Minimal impact',
    responseTime: '24 hours',
    escalation: 'Not required'
  }
};
```

**3. Investigation** (Use observability stack)
```
1. Check dashboards for anomalies
2. Review recent deployments
3. Search logs for errors
4. Analyze distributed traces
5. Check external dependencies
```

**4. Mitigation** (Quick fixes)
```
- Rollback recent deployment
- Scale up resources
- Failover to backup
- Disable problematic feature
- Clear cache
```

**5. Communication**
```javascript
// Status page update
await statusPage.createIncident({
  name: 'API Latency Issues',
  status: 'investigating',
  impact: 'major',
  message: 'We are investigating elevated API response times.',
  components: ['API', 'Database']
});

// Internal communication
await slack.postMessage({
  channel: '#incidents',
  text: `
    🚨 SEV2 Incident Declared

    **Issue:** High API latency (P95 > 5s)
    **Impact:** All users experiencing slow responses
    **Incident Commander:** @john
    **Status:** Investigating
    **War Room:** #incident-2024-01-15
  `
});
```

**6. Resolution**
```
1. Implement permanent fix
2. Deploy changes
3. Verify resolution in metrics
4. Update status page
5. Close incident
```

**7. Post-Mortem** (Blameless)
```markdown
# Incident Post-Mortem: High API Latency (2024-01-15)

## Summary
On January 15, 2024, users experienced elevated API latency for 2 hours.

## Timeline
- **14:00 UTC**: Alert fired for high P95 latency (3s)
- **14:05**: On-call engineer acknowledged
- **14:15**: Identified cause: missing database index
- **14:30**: Deployed database migration to add index
- **15:45**: Latency returned to normal
- **16:00**: Incident resolved

## Root Cause
A recent feature added a query that performed a full table scan on the `users` table (10M rows) due to missing index on `created_at` column.

## Impact
- 2 hours of degraded performance
- P95 latency: 3-5 seconds (normal: 200ms)
- 15% increase in timeout errors
- ~500 user complaints

## What Went Well
- Alert fired within 5 minutes
- Quick identification of root cause
- Clear communication to users

## What Went Wrong
- No performance testing before deployment
- Missing database migration review
- No query performance monitoring

## Action Items
1. [ ] Add query performance tests to CI/CD (@john, Jan 20)
2. [ ] Implement database migration review process (@jane, Jan 25)
3. [ ] Add slow query monitoring alerts (@mike, Jan 22)
4. [ ] Update deployment checklist (@sarah, Jan 18)
5. [ ] Conduct training on database indexing (@team, Feb 1)

## Lessons Learned
- Performance testing is critical for database-heavy features
- Slow query monitoring should trigger alerts
- Review all migrations before production deployment
```

---

## SLI, SLO, and SLA

### Definitions

**SLI (Service Level Indicator)**: Metrics that measure service quality
**SLO (Service Level Objective)**: Target values for SLIs
**SLA (Service Level Agreement)**: Contract with users, often with penalties

### Example SLIs

```javascript
const SLIs = {
  availability: {
    description: 'Percentage of successful requests',
    query: 'rate(http_requests_total{status!~"5.."}[30d]) / rate(http_requests_total[30d])',
    target: 0.999  // 99.9%
  },

  latency: {
    description: 'P95 latency under 500ms',
    query: 'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))',
    target: 0.5  // 500ms
  },

  errorRate: {
    description: 'Error rate under 1%',
    query: 'rate(http_requests_total{status=~"5.."}[30d]) / rate(http_requests_total[30d])',
    target: 0.01  // 1%
  }
};
```

### SLO Dashboard

**Grafana Dashboard**:
```json
{
  "panels": [
    {
      "title": "Availability SLO (99.9% target)",
      "targets": [{
        "expr": "rate(http_requests_total{status!~\"5..\"}[30d]) / rate(http_requests_total[30d]) * 100"
      }],
      "thresholds": [
        { "value": 99.9, "color": "green" },
        { "value": 99.5, "color": "yellow" },
        { "value": 99.0, "color": "red" }
      ]
    },
    {
      "title": "Error Budget Remaining",
      "targets": [{
        "expr": "1 - (rate(http_requests_total{status=~\"5..\"}[30d]) / 0.001)"
      }]
    }
  ]
}
```

### Error Budget

**Calculate Error Budget**:
```javascript
function calculateErrorBudget(slo, actualAvailability, totalRequests) {
  const allowedErrors = totalRequests * (1 - slo);
  const actualErrors = totalRequests * (1 - actualAvailability);
  const remainingBudget = allowedErrors - actualErrors;
  const budgetPercentage = (remainingBudget / allowedErrors) * 100;

  return {
    allowedErrors,
    actualErrors,
    remainingBudget,
    budgetPercentage,
    budgetExhausted: remainingBudget <= 0
  };
}

// Example
const result = calculateErrorBudget(
  0.999,      // 99.9% SLO
  0.9985,     // 99.85% actual
  10000000    // 10M requests
);

console.log(result);
// {
//   allowedErrors: 10000,
//   actualErrors: 15000,
//   remainingBudget: -5000,
//   budgetPercentage: -50,
//   budgetExhausted: true
// }
```

**Error Budget Policy**:
```javascript
if (errorBudget.budgetExhausted) {
  // Freeze feature releases
  console.log('🚨 Error budget exhausted! Freeze releases until reliability improves.');

  // Focus on reliability
  priorities.push('Fix bugs', 'Improve tests', 'Reduce errors');
} else {
  // Can take risks with new features
  console.log(`✅ ${errorBudget.budgetPercentage}% error budget remaining. Ship new features!`);
}
```

---

## Debugging and Troubleshooting

### Debugging Workflow

```
1. Reproduce issue
2. Gather data (metrics, logs, traces)
3. Form hypothesis
4. Test hypothesis
5. Implement fix
6. Verify fix
7. Document for future
```

### Common Issues and Debugging

**Issue 1: High Latency**
```bash
# 1. Check metrics
# - What's the P95/P99 latency?
# - When did it start?
# - Which endpoints are affected?

# 2. Check traces
# - Which service is slow?
# - Database query? External API?

# 3. Check logs
curl "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="app"} |= "slow"' \
  --data-urlencode 'start=1h'

# 4. Check database
SELECT * FROM pg_stat_activity WHERE state = 'active';

# 5. Possible causes:
# - Missing database index
# - N+1 queries
# - Slow external API
# - Resource saturation (CPU/memory)
```

**Issue 2: Memory Leak**
```bash
# 1. Check metrics
# - Memory usage increasing over time?
# - Does it correlate with traffic?

# 2. Heap snapshot (Node.js)
node --inspect app.js
# Chrome DevTools → Memory → Take heap snapshot

# 3. Analyze heap
# - Look for large objects
# - Check for event listener leaks
# - Check for unclosed connections

# 4. Common causes:
# - Event listeners not removed
# - Database connections not closed
# - Cache growing unbounded
# - Global variables accumulating
```

**Issue 3: Database Connection Pool Exhausted**
```javascript
// Debug connection pool
const pool = new Pool({
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
  // Add logging
  log: (msg) => console.log('Pool:', msg)
});

// Monitor pool
setInterval(() => {
  console.log('Pool status:', {
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount
  });
}, 5000);

// Likely causes:
// - Not releasing connections (missing client.release())
// - Long-running transactions
// - Traffic spike exceeding pool size
```

### Debugging Tools

**Chrome DevTools** (for Node.js):
```bash
node --inspect-brk app.js

# Open chrome://inspect in Chrome
# Set breakpoints, inspect variables, step through code
```

**Node.js Built-in Profiler**:
```bash
# CPU profiling
node --prof app.js
# ... run workload ...
# Stop process, generates isolate-*.log

# Process profile
node --prof-process isolate-*.log > profile.txt
```

**Clinic.js** (Node.js Performance):
```bash
npm install -g clinic

# Doctor (overall health)
clinic doctor -- node app.js

# Flame (CPU profiling)
clinic flame -- node app.js

# Bubbleprof (async operations)
clinic bubbleprof -- node app.js
```

**Python Profiling**:
```python
import cProfile
import pstats

# Profile function
profiler = cProfile.Profile()
profiler.enable()

# Your code here
process_data()

profiler.disable()

# Print stats
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(20)  # Top 20 functions
```

---

## Summary

Monitoring and observability are essential for operating production systems. By implementing the three pillars (metrics, logs, traces), you gain the visibility needed to understand, debug, and optimize your applications.

**Key Takeaways**:
1. **Instrument Everything**: Metrics, logs, and traces
2. **Monitor the Golden Signals**: Latency, traffic, errors, saturation
3. **Alert on User Impact**: Not internal metrics
4. **Correlation IDs**: Track requests across services
5. **Structured Logging**: Make logs searchable
6. **Distributed Tracing**: Understand service dependencies
7. **Error Budgets**: Balance features and reliability
8. **Blameless Post-Mortems**: Learn from incidents

Build observable systems! 📊
