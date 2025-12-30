---
name: microservices
description: Microservices architecture patterns and best practices. Service decomposition, inter-service communication, and distributed data management.
sasmp_version: "2.0.0"
bonded_agent: architecture-patterns-agent
bond_type: SECONDARY_BOND

# === PRODUCTION-GRADE SKILL CONFIG (SASMP v2.0.0) ===

atomic_operations:
  - SERVICE_DECOMPOSITION
  - API_GATEWAY_SETUP
  - SERVICE_DISCOVERY
  - DATA_MANAGEMENT

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5
    maxLength: 3000
  pattern:
    type: string
    enum: [saga, cqrs, event-sourcing, api-gateway]
    required: false

retry_logic:
  max_attempts: 2
  backoff: exponential
  initial_delay_ms: 2000

logging_hooks:
  on_invoke: "skill.microservices.invoked"
  on_success: "skill.microservices.completed"
  on_error: "skill.microservices.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  ANTI_PATTERN_DETECTED: 2
---

# Microservices Skill

**Bonded to:** `architecture-patterns-agent` (Secondary)

---

## Quick Start

```bash
# Invoke microservices skill
"Decompose my monolith into microservices"
"Design API gateway for my services"
"Implement Saga pattern for distributed transactions"
```

---

## Decomposition Strategies

| Strategy | Best For | Complexity |
|----------|----------|------------|
| By Business Capability | Clear domains | Medium |
| By Subdomain (DDD) | Complex domains | High |
| By Team | Conway's Law | Medium |
| Strangler Fig | Migration | Low |

---

## Service Decomposition Example

```
E-commerce Monolith → Microservices

├── user-service          # Authentication, profiles
├── product-service       # Catalog, inventory
├── order-service         # Orders, checkout
├── payment-service       # Transactions
├── notification-service  # Email, push, SMS
└── api-gateway           # Routing, auth, rate limiting
```

---

## Communication Patterns

### Synchronous (REST/gRPC)
```python
# Service-to-service call
import httpx

async def get_user_from_user_service(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(f"http://user-service/users/{user_id}")
        return response.json()
```

### Asynchronous (Events)
```python
# Event publishing
from kafka import KafkaProducer

producer = KafkaProducer(bootstrap_servers=['kafka:9092'])

def publish_order_created(order):
    producer.send('order-events', {
        'type': 'ORDER_CREATED',
        'order_id': order.id,
        'user_id': order.user_id
    })
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Sign | Solution |
|--------------|------|----------|
| Distributed Monolith | Tight coupling | Define bounded contexts |
| Shared Database | Multiple services, one DB | Database per service |
| Chatty Services | Too many sync calls | Use async messaging |
| Data Inconsistency | No transaction strategy | Implement Saga |

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Cascading failures | No resilience | Circuit breakers |
| Data inconsistency | Distributed tx | Saga pattern |
| High latency | Chatty calls | Batch requests, cache |

---

## Resources

- [Sam Newman - Building Microservices](https://samnewman.io/books/)
- [Microsoft Microservices Architecture](https://docs.microsoft.com/en-us/azure/architecture/microservices/)
