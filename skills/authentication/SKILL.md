---
name: authentication
description: Backend authentication and authorization patterns. JWT, OAuth2, session management, RBAC, and secure token handling.
sasmp_version: "2.0.0"
bonded_agent: 03-api-development
bond_type: SECONDARY_BOND

# === PRODUCTION-GRADE SKILL CONFIG (SASMP v2.0.0) ===

atomic_operations:
  - JWT_IMPLEMENTATION
  - OAUTH2_SETUP
  - SESSION_MANAGEMENT
  - RBAC_CONFIGURATION

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5
    maxLength: 2000
  auth_type:
    type: string
    enum: [jwt, oauth2, session, api_key]
    required: false

retry_logic:
  max_attempts: 2
  backoff: exponential
  initial_delay_ms: 1000

logging_hooks:
  on_invoke: "skill.authentication.invoked"
  on_success: "skill.authentication.completed"
  on_error: "skill.authentication.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  SECURITY_ISSUE: 2
---

# Authentication Skill

**Bonded to:** `api-development-agent` (Secondary)

---

## Quick Start

```bash
# Invoke authentication skill
"Implement JWT authentication for my API"
"Set up OAuth2 with Google login"
"Configure role-based access control"
```

---

## Auth Methods Comparison

| Method | Best For | Stateless | Complexity |
|--------|----------|-----------|------------|
| JWT | APIs, microservices | Yes | Medium |
| OAuth2 | Third-party login | Yes | High |
| Session | Traditional web apps | No | Low |
| API Key | Simple integrations | Yes | Low |

---

## Examples

### JWT Authentication
```python
from jose import jwt
from datetime import datetime, timedelta

SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"

def create_access_token(user_id: str, expires_delta: timedelta = timedelta(minutes=30)):
    expire = datetime.utcnow() + expires_delta
    return jwt.encode(
        {"sub": user_id, "exp": expire},
        SECRET_KEY,
        algorithm=ALGORITHM
    )

def verify_token(token: str) -> str:
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    return payload.get("sub")
```

### RBAC Implementation
```python
from enum import Enum
from functools import wraps

class Role(Enum):
    ADMIN = "admin"
    USER = "user"
    VIEWER = "viewer"

PERMISSIONS = {
    Role.ADMIN: ["read", "write", "delete", "admin"],
    Role.USER: ["read", "write"],
    Role.VIEWER: ["read"]
}

def require_permission(permission: str):
    def decorator(func):
        @wraps(func)
        async def wrapper(user, *args, **kwargs):
            if permission not in PERMISSIONS.get(user.role, []):
                raise HTTPException(status_code=403)
            return await func(user, *args, **kwargs)
        return wrapper
    return decorator
```

---

## Security Checklist

- [ ] Use HTTPS everywhere
- [ ] Short-lived access tokens (15-60 min)
- [ ] Refresh token rotation
- [ ] Secure token storage (HttpOnly cookies)
- [ ] Rate limiting on auth endpoints
- [ ] Account lockout after failed attempts

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Token expired | Short TTL | Implement refresh tokens |
| Invalid signature | Wrong secret | Verify SECRET_KEY |
| 401 on valid token | Clock skew | Sync server time |

---

## Resources

- [JWT.io Debugger](https://jwt.io/)
- [OAuth 2.0 Simplified](https://aaronparecki.com/oauth-2-simplified/)
