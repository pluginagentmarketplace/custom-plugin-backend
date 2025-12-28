# Usage Guide

## Available Agents

| Agent | Triggers | Purpose |
|-------|----------|---------|
| `programming-fundamentals-agent` | "programming", "git", "language" | Language selection, Git workflows |
| `database-management-agent` | "database", "sql", "mongodb" | Database design, optimization |
| `api-development-agent` | "api", "rest", "graphql" | API design, authentication |
| `architecture-patterns-agent` | "architecture", "microservices" | System design, patterns |
| `caching-performance-agent` | "performance", "redis", "cache" | Caching, optimization |
| `devops-infrastructure-agent` | "docker", "kubernetes", "ci/cd" | Deployment, infrastructure |
| `testing-security-agent` | "security", "testing", "owasp" | Security, testing |

## Example Usage

### Database Design
```
"Design a database schema for my e-commerce application"
→ database-management-agent activates
```

### API Development
```
"Create a REST API with JWT authentication"
→ api-development-agent activates
```

### DevOps
```
"Containerize my FastAPI application"
→ devops-infrastructure-agent activates
```

## Skills

Each agent has bonded skills with real templates:

- `languages/` - Language comparison YAML
- `databases/` - SQL schema templates
- `api-design/` - OpenAPI templates
- `architecture/` - Design patterns YAML
- `performance/` - Redis config templates
- `devops/` - Dockerfile templates
- `security/` - Security headers config
