---
name: testing
description: Backend testing strategies and test automation. Unit, integration, E2E, and load testing with best practices.
sasmp_version: "2.0.0"
bonded_agent: 07-testing-security
bond_type: SECONDARY_BOND

# === PRODUCTION-GRADE SKILL CONFIG (SASMP v2.0.0) ===

atomic_operations:
  - UNIT_TEST_CREATION
  - INTEGRATION_TEST_SETUP
  - E2E_TEST_CONFIGURATION
  - LOAD_TEST_EXECUTION

parameter_validation:
  query:
    type: string
    required: true
    minLength: 5
    maxLength: 2000
  test_type:
    type: string
    enum: [unit, integration, e2e, load, contract]
    required: false

retry_logic:
  max_attempts: 2
  backoff: exponential
  initial_delay_ms: 1000

logging_hooks:
  on_invoke: "skill.testing.invoked"
  on_success: "skill.testing.completed"
  on_error: "skill.testing.failed"

exit_codes:
  SUCCESS: 0
  INVALID_INPUT: 1
  TEST_FAILURE: 2
---

# Testing Skill

**Bonded to:** `testing-security-agent` (Secondary)

---

## Quick Start

```bash
# Invoke testing skill
"Write unit tests for my user service"
"Set up integration tests with database"
"Configure load testing with k6"
```

---

## Testing Pyramid

```
            /\
           /E2E\       Few, slow, expensive
          /────\
         /Integration\  Some, medium speed
        /────────────\
       /  Unit Tests  \ Many, fast, cheap
      /────────────────\
```

| Type | Coverage | Speed | Cost |
|------|----------|-------|------|
| Unit | 80%+ | Fast | Low |
| Integration | 60%+ | Medium | Medium |
| E2E | Critical paths | Slow | High |

---

## Examples

### Unit Test (pytest)
```python
import pytest
from unittest.mock import Mock
from app.services.user_service import UserService

class TestUserService:
    @pytest.fixture
    def service(self):
        return UserService(db=Mock())

    def test_get_user_returns_user(self, service):
        service.db.get_user.return_value = {"id": 1, "name": "John"}

        result = service.get_user(1)

        assert result["name"] == "John"
        service.db.get_user.assert_called_once_with(1)

    def test_get_user_raises_when_not_found(self, service):
        service.db.get_user.return_value = None

        with pytest.raises(UserNotFoundError):
            service.get_user(999)
```

### Integration Test
```python
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.database import get_db

@pytest.fixture
def client(test_db):
    def override_get_db():
        return test_db
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c

def test_create_and_get_user(client):
    # Create user
    response = client.post("/users", json={"email": "test@example.com"})
    assert response.status_code == 201
    user_id = response.json()["id"]

    # Get user
    response = client.get(f"/users/{user_id}")
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"
```

### Load Test (k6)
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 100 },
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('http://localhost:8000/api/v1/users');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
  sleep(1);
}
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Flaky tests | Race conditions | Use mocks, fix async |
| Slow suite | Too many E2E | Optimize pyramid |
| Low coverage | Untested edges | Add boundary tests |

---

## Resources

- [pytest Documentation](https://docs.pytest.org/)
- [k6 Documentation](https://k6.io/docs/)
- [Testing on the Toilet (Google)](https://testing.googleblog.com/)
