---
name: api-design
description: Design and build professional APIs with REST, GraphQL, and gRPC. Master authentication, documentation, testing, and operational concerns.
sasmp_version: "1.3.0"
bonded_agent: api-development-agent
bond_type: PRIMARY_BOND
---

# API Design Skill

**Bonded to:** `api-development-agent`

---

## Quick Start

```bash
# Example: Invoke api-design skill
"Design a REST API for user management with authentication"
```

---

## Instructions

1. **Analyze Requirements**: Understand client needs and data flow
2. **Choose Paradigm**: Select REST, GraphQL, or gRPC
3. **Design Endpoints**: Create resource-oriented API structure
4. **Implement Security**: Add authentication and authorization
5. **Document API**: Generate OpenAPI specification

---

## API Paradigm Selection

| Paradigm | Best For | Performance |
|----------|----------|-------------|
| REST | Public APIs, CRUD | Good |
| GraphQL | Complex data, Mobile | Good |
| gRPC | Internal services | Excellent |

---

## Examples

### Example 1: REST Design
```
Input: "Create user management API"
Output: POST /users, GET /users/{id}, PUT /users/{id}, DELETE /users/{id}
```

### Example 2: Authentication
```
Input: "Add JWT authentication to my API"
Output: Implement JWT strategy with access/refresh tokens
```

---

## References

See `references/` directory for detailed documentation.
