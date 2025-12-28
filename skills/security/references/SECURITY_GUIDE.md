# Security Best Practices Guide

## OWASP Top 10 Prevention

### 1. Broken Access Control
- Implement role-based access control (RBAC)
- Deny by default
- Rate limit API requests
- Log access control failures

### 2. Cryptographic Failures
- Use TLS 1.3 for data in transit
- AES-256 for data at rest
- Never store plaintext passwords
- Use secure random generators

### 3. Injection Prevention
```python
# BAD - SQL Injection vulnerable
query = f"SELECT * FROM users WHERE id = {user_id}"

# GOOD - Parameterized query
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

## Authentication Checklist

- [ ] Strong password policy (min 12 chars)
- [ ] Account lockout after failed attempts
- [ ] Multi-factor authentication
- [ ] Secure session management
- [ ] Password hashing (bcrypt/argon2)

## Security Scanning Tools

| Type | Tool | Purpose |
|------|------|---------|
| SAST | SonarQube, Semgrep | Static code analysis |
| DAST | OWASP ZAP, Burp | Dynamic testing |
| SCA | Snyk, Dependabot | Dependency scanning |
| Container | Trivy, Clair | Image scanning |

## Compliance Quick Reference

| Standard | Focus | Key Requirements |
|----------|-------|------------------|
| GDPR | Privacy | Consent, data rights, breach notification |
| HIPAA | Healthcare | PHI protection, access controls |
| PCI-DSS | Payment | Cardholder data security |
| SOC 2 | Trust | Security, availability, integrity |
