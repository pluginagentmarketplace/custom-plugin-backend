---
name: security
description: Secure backend applications against OWASP threats. Implement authentication, encryption, scanning, compliance, and incident response procedures.
sasmp_version: "2.0.0"
bonded_agent: 07-testing-security
bond_type: PRIMARY_BOND

# === PRODUCTION-GRADE SKILL CONFIG (SASMP v2.0.0) ===

atomic_operations:
  - VULNERABILITY_SCAN
  - AUTH_IMPLEMENTATION
  - ENCRYPTION_CONFIG
  - COMPLIANCE_CHECK

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5
    maxLength: 2500
  security_focus:
    type: string
    enum: [owasp, compliance, scanning, auth]
    required: false
  compliance_framework:
    type: string
    enum: [gdpr, hipaa, pci-dss, soc2]
    required: false

retry_logic:
  max_attempts: 2
  backoff: exponential
  initial_delay_ms: 1500

logging_hooks:
  on_invoke: "skill.security.invoked"
  on_success: "skill.security.completed"
  on_error: "skill.security.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  CRITICAL_VULNERABILITY: 2
  COMPLIANCE_VIOLATION: 3
---

# Security Skill

**Bonded to:** `testing-security-agent`

---

## Quick Start

```bash
# Invoke security skill
"Check my code for OWASP vulnerabilities"
"Implement JWT authentication securely"
"Prepare for GDPR compliance audit"
```

---

## Instructions

1. **Assess Risks**: Identify threats and vulnerabilities
2. **Implement Controls**: Add authentication, encryption
3. **Configure Scanning**: Set up SAST, DAST, SCA
4. **Ensure Compliance**: Meet regulatory requirements
5. **Prepare Response**: Create incident response plan

---

## OWASP Top 10 (2025)

| # | Vulnerability | Prevention | Severity |
|---|---------------|------------|----------|
| 1 | Broken Access Control | RBAC, least privilege | Critical |
| 2 | Cryptographic Failures | Strong encryption, TLS | Critical |
| 3 | Injection | Parameterized queries | Critical |
| 4 | Insecure Design | Threat modeling | High |
| 5 | Security Misconfiguration | Hardening | High |
| 6 | Vulnerable Components | SCA scanning | High |
| 7 | Auth Failures | MFA, secure sessions | High |
| 8 | Data Integrity Failures | Signatures | Medium |
| 9 | Logging Failures | Audit logging | Medium |
| 10 | SSRF | Input validation | Medium |

---

## Security Scanning Tools

| Type | Purpose | Tools |
|------|---------|-------|
| SAST | Static code | SonarQube, Semgrep |
| DAST | Dynamic testing | OWASP ZAP, Burp |
| SCA | Dependencies | Snyk, Dependabot |
| Container | Images | Trivy, Grype |
| Secrets | Detection | GitLeaks, TruffleHog |

---

## Examples

### Example 1: Secure Authentication
```python
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
from jose import jwt
import secrets

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_token(user_id: str) -> str:
    return jwt.encode(
        {"sub": user_id, "jti": secrets.token_urlsafe(16)},
        SECRET_KEY,
        algorithm="HS256"
    )
```

### Example 2: SQL Injection Prevention
```python
# BAD - Vulnerable to SQL injection
def get_user_bad(user_id: str):
    query = f"SELECT * FROM users WHERE id = '{user_id}'"
    return db.execute(query)

# GOOD - Parameterized query
def get_user_good(user_id: str):
    query = "SELECT * FROM users WHERE id = :id"
    return db.execute(query, {"id": user_id})
```

### Example 3: Security Headers
```python
from fastapi import FastAPI
from starlette.middleware.base import BaseHTTPMiddleware

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000"
        response.headers["Content-Security-Policy"] = "default-src 'self'"
        return response

app = FastAPI()
app.add_middleware(SecurityHeadersMiddleware)
```

---

## Compliance Checklists

### GDPR
- [ ] Lawful basis for processing
- [ ] Data minimization
- [ ] Right to access/deletion
- [ ] Breach notification (72h)
- [ ] DPO if required

### PCI-DSS
- [ ] Encrypt cardholder data
- [ ] No CVV storage
- [ ] Access controls
- [ ] Regular testing
- [ ] Audit logging

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Token expired | Short TTL | Implement refresh tokens |
| CORS blocked | Missing headers | Configure CORS properly |
| Weak encryption | Old algorithms | Use AES-256, RSA-2048+ |
| SQL injection | String concat | Use parameterized queries |

### Incident Response

```
Incident Detected
    │
    ├─→ Contain: Isolate affected systems
    ├─→ Assess: Determine scope
    ├─→ Remediate: Fix vulnerability
    ├─→ Recover: Restore services
    └─→ Post-mortem: Document & improve
```

---

## Test Template

```python
# tests/test_security.py
import pytest

class TestSecurityControls:
    def test_password_is_hashed(self):
        password = "secure123"
        hashed = hash_password(password)
        assert password not in hashed
        assert verify_password(password, hashed)

    def test_sql_injection_prevented(self):
        malicious_input = "'; DROP TABLE users; --"
        # Should not execute the DROP TABLE
        result = get_user(malicious_input)
        assert result is None  # User not found, not table dropped

    def test_auth_required_for_protected_routes(self, client):
        response = client.get("/api/v1/users/me")
        assert response.status_code == 401
```

---

## Resources

- [OWASP Top 10](https://owasp.org/Top10/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CWE Top 25](https://cwe.mitre.org/top25/)
