---
name: observability
description: Logging, metrics, and distributed tracing. OpenTelemetry, Prometheus, Grafana, and production debugging.
sasmp_version: "2.0.0"
bonded_agent: backend-observability-agent
bond_type: PRIMARY_BOND

# === PRODUCTION-GRADE SKILL CONFIG (SASMP v2.0.0) ===

atomic_operations:
  - LOGGING_SETUP
  - METRICS_COLLECTION
  - TRACING_IMPLEMENTATION
  - ALERTING_CONFIGURATION

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5
    maxLength: 2000
  pillar:
    type: string
    enum: [logs, metrics, traces, alerts]
    required: false

retry_logic:
  max_attempts: 3
  backoff: exponential
  initial_delay_ms: 1000

logging_hooks:
  on_invoke: "skill.observability.invoked"
  on_success: "skill.observability.completed"
  on_error: "skill.observability.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  COLLECTION_ERROR: 2
---

# Observability Skill

**Bonded to:** `backend-observability-agent` (Primary)

---

## Quick Start

```bash
# Invoke observability skill
"Set up structured logging for my application"
"Configure Prometheus metrics"
"Implement distributed tracing with OpenTelemetry"
```

---

## Three Pillars

| Pillar | Purpose | Tools |
|--------|---------|-------|
| Logs | What happened | ELK, Loki |
| Metrics | System state | Prometheus, Grafana |
| Traces | Request flow | Jaeger, OpenTelemetry |

---

## Examples

### Structured Logging
```python
import structlog

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ]
)

logger = structlog.get_logger()

def process_request(request):
    log = logger.bind(
        correlation_id=request.headers.get("X-Correlation-ID"),
        user_id=request.user.id
    )
    log.info("request_started", method=request.method)
```

### Prometheus Metrics
```python
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter('http_requests_total', 'Total requests', ['method', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'Request latency')

@REQUEST_LATENCY.time()
async def handle_request(request):
    response = await process(request)
    REQUEST_COUNT.labels(method=request.method, status=response.status_code).inc()
    return response
```

### OpenTelemetry Tracing
```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

@tracer.start_as_current_span("process_order")
def process_order(order_id: str):
    span = trace.get_current_span()
    span.set_attribute("order.id", order_id)

    with tracer.start_as_current_span("validate"):
        validate(order_id)

    with tracer.start_as_current_span("charge"):
        charge(order_id)
```

---

## Key Metrics (RED Method)

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Rate | Requests/sec | Drop > 50% |
| Errors | Error rate % | > 1% for 5 min |
| Duration | P99 latency | > 500ms for 5 min |

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Missing logs | Log level too high | Adjust log level |
| High cardinality | Too many labels | Reduce label values |
| Broken traces | Context not propagated | Forward headers |

---

## Resources

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
