<div align="center">

# Backend Development Assistant

### Professional Backend Development Plugin for Claude Code

**Build production-ready backends with 7 specialized agents covering databases, APIs, architecture, DevOps, and security**

[![Verified](https://img.shields.io/badge/Verified-Working-success?style=flat-square&logo=checkmarx)](https://github.com/pluginagentmarketplace/custom-plugin-backend)
[![License](https://img.shields.io/badge/License-Custom-yellow?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0.0-blue?style=flat-square)](https://github.com/pluginagentmarketplace/custom-plugin-backend)
[![Status](https://img.shields.io/badge/Status-Production_Ready-brightgreen?style=flat-square)](https://github.com/pluginagentmarketplace/custom-plugin-backend)
[![Agents](https://img.shields.io/badge/Agents-7-orange?style=flat-square)](#agents-overview)
[![Skills](https://img.shields.io/badge/Skills-7-purple?style=flat-square)](#skills-reference)
[![SASMP](https://img.shields.io/badge/SASMP-v1.3.0-blueviolet?style=flat-square)](#)

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue?style=for-the-badge&logo=python)](https://python.org)
[![Node.js](https://img.shields.io/badge/Node.js-20%2B-green?style=for-the-badge&logo=nodedotjs)](https://nodejs.org)
[![Go](https://img.shields.io/badge/Go-1.21%2B-cyan?style=for-the-badge&logo=go)](https://golang.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)](https://docker.com)

[Quick Start](#quick-start) | [Agents](#agents-overview) | [Skills](#skills-reference) | [Commands](#commands)

</div>

---

## Verified Installation

> **This plugin has been tested and verified working on Claude Code.**
> Last verified: December 2025

---

## Quick Start

### Option 1: Install from GitHub (Recommended)

```bash
# Step 1: Add the marketplace from GitHub
/plugin add marketplace pluginagentmarketplace/custom-plugin-backend

# Step 2: Install the plugin
/plugin install backend-development-assistant@pluginagentmarketplace-backend

# Step 3: Restart Claude Code to load new plugins
```

### Option 2: Clone and Load Locally

```bash
# Clone the repository
git clone https://github.com/pluginagentmarketplace/custom-plugin-backend.git

# Navigate to the directory in Claude Code
cd custom-plugin-backend

# Load the plugin
/plugin load .
```

After loading, restart Claude Code.

### Verify Installation

After restarting Claude Code, verify the plugin is loaded. You should see these agents available:

```
custom-plugin-backend:01-programming-fundamentals
custom-plugin-backend:02-database-management
custom-plugin-backend:03-api-development
custom-plugin-backend:04-architecture-patterns
custom-plugin-backend:05-caching-performance
custom-plugin-backend:06-devops-infrastructure
custom-plugin-backend:07-testing-security
```

---

## Available Skills

Once installed, these 7 skills become available:

| Skill | Invoke Command | Golden Format |
|-------|----------------|---------------|
| Languages | `Skill("custom-plugin-backend:languages")` | language-comparison.yaml, setup_environment.sh |
| Databases | `Skill("custom-plugin-backend:databases")` | schema-template.sql, backup_database.sh |
| API Design | `Skill("custom-plugin-backend:api-design")` | openapi-template.yaml, generate_openapi.sh |
| Architecture | `Skill("custom-plugin-backend:architecture")` | design-patterns.yaml, analyze_dependencies.sh |
| Performance | `Skill("custom-plugin-backend:performance")` | redis-config.yaml, benchmark_api.sh |
| DevOps | `Skill("custom-plugin-backend:devops")` | Dockerfile.template, docker_build.sh |
| Security | `Skill("custom-plugin-backend:security")` | security-headers.yaml, security_scan.sh |

---

## What This Plugin Does

This plugin provides **7 specialized agents** and **7 production-ready skills** for backend development:

| Agent | Purpose |
|-------|---------|
| **Programming Fundamentals** | Languages, Git, package management (Python, Node.js, Go, Rust) |
| **Database Management** | SQL, NoSQL, query optimization (PostgreSQL, MongoDB, Redis) |
| **API Development** | REST, GraphQL, gRPC, authentication |
| **Architecture Patterns** | SOLID, design patterns, microservices |
| **Caching & Performance** | Redis, load balancing, monitoring |
| **DevOps & Infrastructure** | Docker, Kubernetes, CI/CD |
| **Testing & Security** | OWASP, testing strategies, compliance |

---

## Agents Overview

### 7 Implementation Agents

Each agent is designed to **do the work**, not just explain:

| Agent | Capabilities | Example Prompts |
|-------|--------------|-----------------|
| **Programming Fundamentals** | Language selection, Git workflows, dependency management | `"Set up Python project"`, `"Configure Git workflow"` |
| **Database Management** | Schema design, query optimization, migrations | `"Design e-commerce schema"`, `"Optimize slow query"` |
| **API Development** | REST API design, OpenAPI specs, authentication | `"Create REST API for users"`, `"Add JWT auth"` |
| **Architecture Patterns** | SOLID principles, design patterns, microservices | `"Apply repository pattern"`, `"Design microservices"` |
| **Caching & Performance** | Redis caching, load balancing, profiling | `"Add Redis caching"`, `"Optimize API performance"` |
| **DevOps & Infrastructure** | Docker, Kubernetes, CI/CD pipelines | `"Containerize my app"`, `"Set up GitHub Actions"` |
| **Testing & Security** | Unit/E2E testing, OWASP, security scanning | `"Write unit tests"`, `"Audit for OWASP Top 10"` |

---

## Commands

4 interactive commands for backend development:

| Command | Usage | Description |
|---------|-------|-------------|
| `/learn` | `/learn` | Start learning backend development with guided paths |
| `/assess` | `/assess` | Assess your backend knowledge level |
| `/browse-agent` | `/browse-agent` | Browse available agents and their capabilities |
| `/projects` | `/projects` | Get project ideas and templates |

---

## Skills Reference

Each skill includes **Golden Format** content:
- `assets/` - YAML templates, SQL schemas, Dockerfiles
- `scripts/` - Shell scripts for automation
- `references/` - Detailed methodology guides

### Skills Deep Dive

| Skill | Focus Areas | Real Assets |
|-------|-------------|-------------|
| **languages** | Python, Node.js, Go, Rust, Java | `language-comparison.yaml` |
| **databases** | PostgreSQL, MongoDB, Redis, MySQL | `schema-template.sql` |
| **api-design** | REST, GraphQL, OpenAPI 3.0 | `openapi-template.yaml` |
| **architecture** | SOLID, Repository, Factory patterns | `design-patterns.yaml` |
| **performance** | Caching, CDN, load balancing | `redis-config.yaml` |
| **devops** | Docker, Kubernetes, CI/CD | `Dockerfile.template` |
| **security** | OWASP Top 10, headers, scanning | `security-headers.yaml` |

---

## Usage Examples

### Example 1: Database Schema Design

```
User: "Design a database schema for my e-commerce application"

Database Management Agent activated!

Recommended Schema:
├── users (id, email, password_hash, created_at)
├── products (id, name, price, category_id, stock)
├── orders (id, user_id, total, status, created_at)
└── order_items (id, order_id, product_id, quantity, price)

Indexes:
- users(email) UNIQUE
- products(category_id)
- orders(user_id, created_at)
```

### Example 2: Containerize Application

**Before:**
```
Manual deployment with dependencies on local environment
```

**After (with DevOps Agent):**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]
```

### Example 3: Security Audit

```
User: "Audit my app for OWASP Top 10 vulnerabilities"

Testing & Security Agent:
✓ SQL Injection: Protected (parameterized queries)
✗ XSS: Vulnerable (missing output encoding)
✓ CSRF: Protected (token validation)
✗ Security Headers: Missing (add CSP, HSTS)

Recommendations:
1. Add output encoding in templates
2. Configure security headers
3. Enable rate limiting
```

---

## Plugin Structure

```
custom-plugin-backend/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest
│   └── marketplace.json      # Marketplace config
├── agents/                   # 7 specialized agents
│   ├── 01-programming-fundamentals.md
│   ├── 02-database-management.md
│   ├── 03-api-development.md
│   ├── 04-architecture-patterns.md
│   ├── 05-caching-performance.md
│   ├── 06-devops-infrastructure.md
│   └── 07-testing-security.md
├── skills/                   # 7 skills (Golden Format)
│   ├── languages/
│   │   ├── SKILL.md
│   │   ├── assets/language-comparison.yaml
│   │   ├── scripts/setup_environment.sh
│   │   └── references/LANGUAGE_GUIDE.md
│   ├── databases/
│   ├── api-design/
│   ├── architecture/
│   ├── performance/
│   ├── devops/
│   └── security/
├── commands/                 # 4 slash commands
│   ├── learn.md
│   ├── assess.md
│   ├── browse-agent.md
│   └── projects.md
├── docs/                     # Additional documentation
├── config/                   # Agent registry
├── hooks/hooks.json
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── ARCHITECTURE.md
├── LEARNING-PATH.md
└── LICENSE
```

---

## Technology Coverage

| Category | Technologies |
|----------|--------------|
| **Languages** | Python, Node.js, Go, Java, C#, Rust, PHP, Ruby |
| **Databases** | PostgreSQL, MySQL, MongoDB, Redis, Elasticsearch |
| **Frameworks** | FastAPI, Express, Gin, Spring Boot, .NET |
| **DevOps** | Docker, Kubernetes, GitHub Actions, Jenkins |
| **Cloud** | AWS, GCP, Azure basics |

---

## Learning Paths

| Path | Duration | Focus |
|------|----------|-------|
| Fast Track | 16 weeks | Core backend skills |
| Full-Stack | 20 weeks | Complete web development |
| Microservices | 28 weeks | Distributed systems |
| DevOps | 24 weeks | Infrastructure focus |
| Comprehensive | 36 weeks | All domains |

See [LEARNING-PATH.md](LEARNING-PATH.md) for detailed curriculum.

---

## Security Notice

This plugin is designed for **authorized development use only**:

✅ **USE FOR:**
- Building production applications
- Learning backend development
- Security best practices implementation
- DevOps automation

❌ **NEVER:**
- Commit secrets or credentials
- Skip security validation
- Ignore OWASP guidelines

---

## Contributing

Contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Follow the Golden Format for new skills
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## Metadata

| Field | Value |
|-------|-------|
| **Last Updated** | 2025-12-28 |
| **Maintenance Status** | Active |
| **SASMP Version** | 1.3.0 |
| **Support** | [Issues](../../issues) |

---

## License

Custom License - See [LICENSE](LICENSE) for details.

---

## Contributors

**Authors:**
- **Dr. Umit Kacar** - Senior AI Researcher & Engineer
- **Muhsin Elcicek** - Senior Software Architect

---

<div align="center">

**Build production-ready backends with AI assistance!** 🚀

[![Made for Backend](https://img.shields.io/badge/Made%20for-Backend_Development-blue?style=for-the-badge&logo=fastapi)](https://github.com/pluginagentmarketplace/custom-plugin-backend)

**Built by Dr. Umit Kacar & Muhsin Elcicek**

</div>
