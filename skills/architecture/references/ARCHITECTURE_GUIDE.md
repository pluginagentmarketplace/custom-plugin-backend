# Architecture Design Guide

## SOLID Principles

| Principle | Description | Violation Example |
|-----------|-------------|-------------------|
| **S**ingle Responsibility | One reason to change | Class handles UI + DB |
| **O**pen/Closed | Open for extension, closed for modification | Modifying class for new feature |
| **L**iskov Substitution | Subtypes replaceable | Square extends Rectangle |
| **I**nterface Segregation | No unused methods | Fat interfaces |
| **D**ependency Inversion | Depend on abstractions | Class depends on implementation |

## Microservices Decomposition

### Domain-Driven Design Approach
1. Identify bounded contexts
2. Define aggregates
3. Map domain events
4. Design service boundaries

### Common Service Boundaries
- **User Service**: Authentication, profile
- **Product Service**: Catalog, inventory
- **Order Service**: Cart, checkout
- **Payment Service**: Transactions
- **Notification Service**: Email, SMS, push

## Event-Driven Patterns

| Pattern | Use Case |
|---------|----------|
| Event Notification | Simple pub/sub |
| Event-Carried State | Reduce coupling |
| Event Sourcing | Audit trail, replay |
| CQRS | Separate read/write |

## Communication Patterns

| Pattern | Latency | Coupling |
|---------|---------|----------|
| Synchronous (REST) | Low | High |
| Async (Message Queue) | Higher | Low |
| Event-Driven | Variable | Very Low |
