---
name: architecture
description: Master architectural design with SOLID principles, design patterns, microservices, and event-driven systems. Learn to design scalable backend systems.
sasmp_version: "1.3.0"
bonded_agent: architecture-patterns-agent
bond_type: PRIMARY_BOND
---

# System Architecture Skill

**Bonded to:** `architecture-patterns-agent`

---

## Quick Start

```bash
# Example: Invoke architecture skill
"Help me decompose this monolith into microservices"
```

---

## Instructions

1. **Analyze Requirements**: Understand system needs and constraints
2. **Apply SOLID**: Use SOLID principles for clean design
3. **Select Patterns**: Choose appropriate design patterns
4. **Design Architecture**: Select monolithic or distributed approach
5. **Validate Design**: Review for scalability and maintainability

---

## Architecture Styles

| Style | Best For | Complexity |
|-------|----------|------------|
| Monolithic | Simple apps, MVPs | Low |
| Microservices | Large teams, scaling | High |
| Event-Driven | Real-time, async | Medium |
| Serverless | Variable load | Medium |

---

## Examples

### Example 1: Design Pattern
```
Input: "Which pattern for notification system?"
Output: Observer pattern for publish-subscribe notifications
```

### Example 2: Microservices
```
Input: "Decompose e-commerce monolith"
Output: User, Product, Order, Payment, Notification services
```

---

## References

See `references/` directory for detailed documentation.
