# Testing Strategies for Backend Development

## Table of Contents
1. [Introduction to Testing](#introduction-to-testing)
2. [The Test Pyramid](#the-test-pyramid)
3. [Unit Testing](#unit-testing)
4. [Integration Testing](#integration-testing)
5. [End-to-End (E2E) Testing](#end-to-end-testing)
6. [Test-Driven Development (TDD)](#test-driven-development)
7. [CI/CD Integration](#cicd-integration)
8. [Testing Frameworks by Language](#testing-frameworks-by-language)
9. [Advanced Testing Techniques](#advanced-testing-techniques)
10. [Best Practices & Anti-Patterns](#best-practices-and-anti-patterns)

---

## Introduction to Testing

### Why Testing Matters

**Cost of Bugs by Stage**:
- **Development**: $100 to fix
- **QA/Testing**: $1,000 to fix
- **Production**: $10,000 - $100,000+ to fix

**Benefits of Automated Testing**:
- ✅ Catch bugs early in development
- ✅ Enable confident refactoring
- ✅ Serve as living documentation
- ✅ Reduce manual testing time
- ✅ Enable continuous deployment
- ✅ Improve code design (testable code is better code)
- ✅ Reduce regression bugs

### Types of Testing

| Test Type | Scope | Speed | Cost | Quantity |
|-----------|-------|-------|------|----------|
| **Unit** | Individual functions/methods | Fast (ms) | Low | Many (70%) |
| **Integration** | Multiple modules/services | Medium (sec) | Medium | Some (20%) |
| **E2E** | Complete user workflows | Slow (min) | High | Few (10%) |
| **Contract** | API interfaces | Fast | Low | As needed |
| **Performance** | Load/stress | Slow | High | Critical paths |
| **Security** | Vulnerabilities | Medium | Medium | All code |

---

## The Test Pyramid

```
        /\
       /  \      E2E Tests (10%)
      /    \     - Slow, expensive, brittle
     /------\    - Critical user journeys only
    /        \
   /          \  Integration Tests (20%)
  /            \ - Test module interactions
 /--------------\- Database, API, services
/                \
/                 \ Unit Tests (70%)
/___________________\- Fast, isolated, comprehensive
      FOUNDATION      - Business logic coverage
```

### Test Pyramid Principles

1. **More Unit Tests**: They're fast, stable, and cheap to write
2. **Some Integration Tests**: Verify modules work together
3. **Few E2E Tests**: Cover critical business workflows only
4. **Invert = Anti-Pattern**: Ice cream cone (mostly E2E) is slow and brittle

### Test Pyramid in Practice

**Good Distribution** (Recommended):
- 1,000 unit tests (run in 10 seconds)
- 200 integration tests (run in 2 minutes)
- 20 E2E tests (run in 10 minutes)
- **Total CI/CD time**: ~12 minutes

**Anti-Pattern** (Ice Cream Cone):
- 50 unit tests
- 100 integration tests
- 500 E2E tests
- **Total CI/CD time**: Several hours, many flaky tests

---

## Unit Testing

### What is Unit Testing?

**Definition**: Testing individual units of code (functions, methods, classes) in isolation from external dependencies.

**Characteristics**:
- ✅ Fast execution (milliseconds per test)
- ✅ No external dependencies (database, network, file system)
- ✅ Deterministic results (same input = same output)
- ✅ Independent (can run in any order)
- ✅ Focused on single behavior

### AAA Pattern

**Arrange, Act, Assert** - The standard structure for unit tests:

```javascript
// JavaScript/Jest Example
describe('UserService', () => {
  test('should create user with hashed password', () => {
    // Arrange - Set up test data and dependencies
    const userService = new UserService();
    const userData = {
      email: 'test@example.com',
      password: 'SecurePass123!'
    };

    // Act - Execute the function being tested
    const result = userService.createUser(userData);

    // Assert - Verify the outcome
    expect(result.email).toBe('test@example.com');
    expect(result.password).not.toBe('SecurePass123!'); // Password should be hashed
    expect(result.id).toBeDefined();
  });
});
```

```python
# Python/PyTest Example
import pytest
from user_service import UserService

class TestUserService:
    def test_create_user_with_hashed_password(self):
        # Arrange
        user_service = UserService()
        user_data = {
            'email': 'test@example.com',
            'password': 'SecurePass123!'
        }

        # Act
        result = user_service.create_user(user_data)

        # Assert
        assert result['email'] == 'test@example.com'
        assert result['password'] != 'SecurePass123!'  # Password should be hashed
        assert 'id' in result
```

```java
// Java/JUnit 5 Example
@Test
void shouldCreateUserWithHashedPassword() {
    // Arrange
    UserService userService = new UserService();
    UserData userData = new UserData("test@example.com", "SecurePass123!");

    // Act
    User result = userService.createUser(userData);

    // Assert
    assertEquals("test@example.com", result.getEmail());
    assertNotEquals("SecurePass123!", result.getPassword()); // Password should be hashed
    assertNotNull(result.getId());
}
```

### Mocking and Stubbing

**Why Mock?**
- Isolate unit under test
- Control external dependencies
- Simulate error conditions
- Speed up tests (no real database/network calls)

**JavaScript (Jest) Mocking Example**:
```javascript
// userRepository.test.js
const UserRepository = require('./userRepository');
const database = require('./database');

// Mock the database module
jest.mock('./database');

describe('UserRepository', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
  });

  test('should find user by email', async () => {
    // Arrange - Mock database response
    const mockUser = { id: 1, email: 'test@example.com', name: 'Test User' };
    database.query.mockResolvedValue([mockUser]);

    const repo = new UserRepository();

    // Act
    const result = await repo.findByEmail('test@example.com');

    // Assert
    expect(database.query).toHaveBeenCalledWith(
      'SELECT * FROM users WHERE email = ?',
      ['test@example.com']
    );
    expect(result).toEqual(mockUser);
  });

  test('should handle database errors gracefully', async () => {
    // Arrange - Mock database error
    database.query.mockRejectedValue(new Error('Connection failed'));

    const repo = new UserRepository();

    // Act & Assert
    await expect(repo.findByEmail('test@example.com'))
      .rejects
      .toThrow('Connection failed');
  });
});
```

**Python (pytest with unittest.mock) Example**:
```python
import pytest
from unittest.mock import Mock, patch
from user_repository import UserRepository

class TestUserRepository:
    @patch('user_repository.database')
    def test_find_user_by_email(self, mock_db):
        # Arrange - Mock database response
        mock_user = {'id': 1, 'email': 'test@example.com', 'name': 'Test User'}
        mock_db.query.return_value = [mock_user]

        repo = UserRepository()

        # Act
        result = repo.find_by_email('test@example.com')

        # Assert
        mock_db.query.assert_called_once_with(
            'SELECT * FROM users WHERE email = %s',
            ('test@example.com',)
        )
        assert result == mock_user

    @patch('user_repository.database')
    def test_handle_database_errors(self, mock_db):
        # Arrange - Mock database error
        mock_db.query.side_effect = Exception('Connection failed')

        repo = UserRepository()

        # Act & Assert
        with pytest.raises(Exception, match='Connection failed'):
            repo.find_by_email('test@example.com')
```

### Code Coverage

**What is Code Coverage?**
- Percentage of code executed during tests
- Metrics: Line coverage, branch coverage, function coverage

**Coverage Goals**:
- **70-80%**: Minimum acceptable
- **80-90%**: Good coverage
- **90%+**: Excellent (but diminishing returns)
- **100%**: Often impractical and unnecessary

**Generating Coverage Reports**:

```bash
# JavaScript (Jest)
npm test -- --coverage

# Python (PyTest with coverage)
pytest --cov=src --cov-report=html --cov-report=term

# Java (JaCoCo with Maven)
mvn clean test jacoco:report

# Go
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

**Coverage Configuration (Jest example)**:
```json
// jest.config.js
module.exports = {
  collectCoverageFrom: [
    'src/**/*.{js,ts}',
    '!src/**/*.test.{js,ts}',
    '!src/index.js'
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

---

## Integration Testing

### What is Integration Testing?

**Definition**: Testing how different modules, services, or external dependencies work together.

**What to Test**:
- ✅ Database interactions (CRUD operations)
- ✅ API endpoints (request/response)
- ✅ Third-party service integrations
- ✅ Message queue interactions
- ✅ Cache behavior
- ✅ File system operations

### Database Integration Tests

**Using Testcontainers (Recommended)**:

```javascript
// JavaScript with Testcontainers
const { GenericContainer } = require('testcontainers');
const UserRepository = require('./userRepository');

describe('UserRepository Integration Tests', () => {
  let container;
  let repository;

  beforeAll(async () => {
    // Start PostgreSQL container
    container = await new GenericContainer('postgres:15')
      .withExposedPorts(5432)
      .withEnvironment({
        POSTGRES_USER: 'test',
        POSTGRES_PASSWORD: 'test',
        POSTGRES_DB: 'testdb'
      })
      .start();

    const connectionString = `postgresql://test:test@${container.getHost()}:${container.getMappedPort(5432)}/testdb`;

    // Run migrations
    await runMigrations(connectionString);

    repository = new UserRepository(connectionString);
  });

  afterAll(async () => {
    await container.stop();
  });

  test('should create and retrieve user from database', async () => {
    // Arrange
    const userData = {
      email: 'integration@test.com',
      name: 'Integration Test User'
    };

    // Act
    const createdUser = await repository.create(userData);
    const retrievedUser = await repository.findById(createdUser.id);

    // Assert
    expect(retrievedUser).toBeDefined();
    expect(retrievedUser.email).toBe(userData.email);
    expect(retrievedUser.name).toBe(userData.name);
  });

  test('should update user in database', async () => {
    // Arrange
    const user = await repository.create({
      email: 'update@test.com',
      name: 'Original Name'
    });

    // Act
    await repository.update(user.id, { name: 'Updated Name' });
    const updated = await repository.findById(user.id);

    // Assert
    expect(updated.name).toBe('Updated Name');
  });
});
```

```python
# Python with Testcontainers
import pytest
from testcontainers.postgres import PostgresContainer
from user_repository import UserRepository
from database import run_migrations

@pytest.fixture(scope='module')
def db_container():
    with PostgresContainer('postgres:15') as postgres:
        # Run migrations
        run_migrations(postgres.get_connection_url())
        yield postgres

@pytest.fixture
def repository(db_container):
    return UserRepository(db_container.get_connection_url())

class TestUserRepositoryIntegration:
    def test_create_and_retrieve_user(self, repository):
        # Arrange
        user_data = {
            'email': 'integration@test.com',
            'name': 'Integration Test User'
        }

        # Act
        created_user = repository.create(user_data)
        retrieved_user = repository.find_by_id(created_user['id'])

        # Assert
        assert retrieved_user is not None
        assert retrieved_user['email'] == user_data['email']
        assert retrieved_user['name'] == user_data['name']
```

### API Integration Tests

**Testing REST APIs**:

```javascript
// JavaScript with Supertest
const request = require('supertest');
const app = require('./app');

describe('API Integration Tests', () => {
  describe('POST /api/users', () => {
    test('should create new user', async () => {
      // Arrange
      const newUser = {
        email: 'api@test.com',
        password: 'SecurePass123!',
        name: 'API Test User'
      };

      // Act
      const response = await request(app)
        .post('/api/users')
        .send(newUser)
        .expect(201);

      // Assert
      expect(response.body).toHaveProperty('id');
      expect(response.body.email).toBe(newUser.email);
      expect(response.body).not.toHaveProperty('password'); // Password should not be returned
    });

    test('should return 400 for invalid email', async () => {
      // Arrange
      const invalidUser = {
        email: 'invalid-email',
        password: 'SecurePass123!',
        name: 'Test User'
      };

      // Act
      const response = await request(app)
        .post('/api/users')
        .send(invalidUser)
        .expect(400);

      // Assert
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('email');
    });
  });

  describe('GET /api/users/:id', () => {
    test('should return user by id', async () => {
      // Arrange - Create user first
      const user = await createTestUser();

      // Act
      const response = await request(app)
        .get(`/api/users/${user.id}`)
        .expect(200);

      // Assert
      expect(response.body.id).toBe(user.id);
      expect(response.body.email).toBe(user.email);
    });

    test('should return 404 for non-existent user', async () => {
      // Act
      const response = await request(app)
        .get('/api/users/99999')
        .expect(404);

      // Assert
      expect(response.body.error).toBe('User not found');
    });
  });
});
```

### Test Data Management

**Fixtures and Factories**:

```javascript
// Test data factory
class UserFactory {
  static create(overrides = {}) {
    return {
      email: `user${Date.now()}@test.com`,
      name: 'Test User',
      password: 'SecurePass123!',
      role: 'user',
      ...overrides
    };
  }

  static createMany(count, overrides = {}) {
    return Array.from({ length: count }, (_, i) =>
      this.create({ ...overrides, email: `user${i}@test.com` })
    );
  }
}

// Usage in tests
test('should list all users', async () => {
  // Arrange
  const users = UserFactory.createMany(3);
  await Promise.all(users.map(u => repository.create(u)));

  // Act
  const result = await repository.findAll();

  // Assert
  expect(result).toHaveLength(3);
});
```

**Database Cleanup Strategies**:

```javascript
// Option 1: Truncate tables after each test
afterEach(async () => {
  await database.query('TRUNCATE TABLE users CASCADE');
});

// Option 2: Use transactions and rollback
beforeEach(async () => {
  await database.query('BEGIN');
});

afterEach(async () => {
  await database.query('ROLLBACK');
});

// Option 3: Delete test data by pattern
afterEach(async () => {
  await database.query('DELETE FROM users WHERE email LIKE \'%@test.com\'');
});
```

---

## End-to-End (E2E) Testing

### What is E2E Testing?

**Definition**: Testing complete user workflows from start to finish, simulating real user interactions.

**When to Use E2E Tests**:
- ✅ Critical business workflows (checkout, registration, payment)
- ✅ User journeys spanning multiple pages/services
- ✅ Cross-browser compatibility
- ✅ Integration with third-party services in staging

**When NOT to Use E2E Tests**:
- ❌ Testing individual functions (use unit tests)
- ❌ Database operations (use integration tests)
- ❌ Edge cases and error handling (use unit/integration tests)
- ❌ Everything (leads to slow, brittle test suite)

### Cypress Example

```javascript
// cypress/e2e/user-registration.cy.js
describe('User Registration Flow', () => {
  beforeEach(() => {
    // Start with clean state
    cy.task('db:reset');
    cy.visit('/register');
  });

  it('should successfully register new user', () => {
    // Arrange - Define test data
    const user = {
      email: 'e2e@test.com',
      password: 'SecurePass123!',
      name: 'E2E Test User'
    };

    // Act - Fill registration form
    cy.get('[data-testid="email-input"]').type(user.email);
    cy.get('[data-testid="password-input"]').type(user.password);
    cy.get('[data-testid="name-input"]').type(user.name);
    cy.get('[data-testid="register-button"]').click();

    // Assert - Verify success
    cy.url().should('include', '/dashboard');
    cy.get('[data-testid="welcome-message"]').should('contain', user.name);

    // Verify user can log out and log back in
    cy.get('[data-testid="logout-button"]').click();
    cy.url().should('include', '/login');

    cy.get('[data-testid="email-input"]').type(user.email);
    cy.get('[data-testid="password-input"]').type(user.password);
    cy.get('[data-testid="login-button"]').click();

    cy.url().should('include', '/dashboard');
  });

  it('should show validation errors for invalid input', () => {
    // Act - Submit empty form
    cy.get('[data-testid="register-button"]').click();

    // Assert - Verify validation errors
    cy.get('[data-testid="email-error"]').should('be.visible');
    cy.get('[data-testid="password-error"]').should('be.visible');
    cy.get('[data-testid="name-error"]').should('be.visible');
  });

  it('should prevent duplicate email registration', () => {
    // Arrange - Create existing user
    cy.task('db:createUser', { email: 'existing@test.com' });

    // Act - Try to register with same email
    cy.get('[data-testid="email-input"]').type('existing@test.com');
    cy.get('[data-testid="password-input"]').type('SecurePass123!');
    cy.get('[data-testid="name-input"]').type('Test User');
    cy.get('[data-testid="register-button"]').click();

    // Assert - Verify error message
    cy.get('[data-testid="error-message"]')
      .should('be.visible')
      .and('contain', 'Email already registered');
  });
});
```

### Playwright Example

```javascript
// tests/e2e/checkout.spec.js
const { test, expect } = require('@playwright/test');

test.describe('E-commerce Checkout Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Set up test data
    await page.request.post('/api/test/reset-db');
    await page.goto('/');
  });

  test('should complete full checkout process', async ({ page }) => {
    // Step 1: Browse and add product to cart
    await page.click('text=Products');
    await page.click('[data-testid="product-1"]');
    await expect(page.locator('h1')).toContainText('Product Details');
    await page.click('[data-testid="add-to-cart"]');

    // Verify cart badge updated
    await expect(page.locator('[data-testid="cart-badge"]')).toHaveText('1');

    // Step 2: View cart
    await page.click('[data-testid="cart-icon"]');
    await expect(page.locator('h1')).toContainText('Shopping Cart');
    await expect(page.locator('[data-testid="cart-item"]')).toHaveCount(1);

    // Step 3: Proceed to checkout
    await page.click('text=Proceed to Checkout');

    // Step 4: Fill shipping information
    await page.fill('[name="shippingAddress"]', '123 Test St');
    await page.fill('[name="city"]', 'Test City');
    await page.fill('[name="zipCode"]', '12345');
    await page.click('text=Continue to Payment');

    // Step 5: Enter payment details (using test card)
    await page.fill('[name="cardNumber"]', '4242424242424242');
    await page.fill('[name="expiryDate"]', '12/25');
    await page.fill('[name="cvv"]', '123');

    // Step 6: Place order
    await page.click('text=Place Order');

    // Step 7: Verify order confirmation
    await expect(page.locator('h1')).toContainText('Order Confirmed');
    const orderNumber = await page.locator('[data-testid="order-number"]').textContent();
    expect(orderNumber).toMatch(/^ORD-\d+$/);

    // Step 8: Verify email sent (mock)
    const emails = await page.request.get('/api/test/emails');
    const emailData = await emails.json();
    expect(emailData).toContainEqual(
      expect.objectContaining({
        to: expect.any(String),
        subject: expect.stringContaining('Order Confirmation'),
        body: expect.stringContaining(orderNumber)
      })
    );
  });
});
```

### E2E Best Practices

**1. Use Data Attributes for Selectors**:
```html
<!-- Good: Stable selectors -->
<button data-testid="submit-button">Submit</button>
<input data-testid="email-input" type="email" />

<!-- Bad: Fragile selectors -->
<button class="btn btn-primary">Submit</button> <!-- CSS classes change -->
<input id="input-123" /> <!-- IDs may change -->
```

**2. Wait for Elements Properly**:
```javascript
// Good: Explicit waits
await page.waitForSelector('[data-testid="results"]');
await expect(page.locator('[data-testid="message"]')).toBeVisible();

// Bad: Hard-coded delays
await page.waitForTimeout(5000); // Flaky!
```

**3. Keep Tests Independent**:
```javascript
// Good: Each test sets up own data
test('should edit user', async () => {
  const user = await createTestUser(); // Create user for this test
  // ... test logic
});

// Bad: Tests depend on each other
test('should create user', async () => {
  // Creates user
});

test('should edit user', async () => {
  // Assumes user from previous test exists - FLAKY!
});
```

---

## Test-Driven Development (TDD)

### The TDD Cycle

**Red → Green → Refactor**:

```
1. RED: Write failing test
   ↓
2. GREEN: Write minimal code to pass
   ↓
3. REFACTOR: Improve code while keeping tests green
   ↓
   Repeat
```

### TDD Example Walkthrough

**Requirement**: Implement a password validator that checks:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

**Step 1: Write Failing Test (RED)**:
```javascript
// passwordValidator.test.js
describe('PasswordValidator', () => {
  test('should reject password shorter than 8 characters', () => {
    const validator = new PasswordValidator();
    const result = validator.validate('Pass1!');

    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Password must be at least 8 characters');
  });
});

// Run test: FAILS (PasswordValidator doesn't exist)
```

**Step 2: Write Minimal Code (GREEN)**:
```javascript
// passwordValidator.js
class PasswordValidator {
  validate(password) {
    if (password.length < 8) {
      return {
        valid: false,
        errors: ['Password must be at least 8 characters']
      };
    }
    return { valid: true, errors: [] };
  }
}

// Run test: PASSES
```

**Step 3: Refactor (if needed)**:
```javascript
// Code is simple, no refactoring needed yet
```

**Step 4: Add Next Test (RED)**:
```javascript
test('should reject password without uppercase letter', () => {
  const validator = new PasswordValidator();
  const result = validator.validate('password1!');

  expect(result.valid).toBe(false);
  expect(result.errors).toContain('Password must contain uppercase letter');
});

// Run test: FAILS
```

**Step 5: Implement (GREEN)**:
```javascript
class PasswordValidator {
  validate(password) {
    const errors = [];

    if (password.length < 8) {
      errors.push('Password must be at least 8 characters');
    }

    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain uppercase letter');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

// Run test: PASSES
```

**Continue TDD Cycle** for remaining requirements...

**Final Implementation**:
```javascript
class PasswordValidator {
  validate(password) {
    const errors = [];

    if (password.length < 8) {
      errors.push('Password must be at least 8 characters');
    }

    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain uppercase letter');
    }

    if (!/[a-z]/.test(password)) {
      errors.push('Password must contain lowercase letter');
    }

    if (!/\d/.test(password)) {
      errors.push('Password must contain number');
    }

    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      errors.push('Password must contain special character');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

// All tests pass!
```

### Benefits of TDD

1. **Better Design**: Forces you to think about API before implementation
2. **High Coverage**: Tests written before code = automatic coverage
3. **Confidence**: Refactor safely knowing tests will catch regressions
4. **Documentation**: Tests serve as usage examples
5. **Faster Debugging**: Small increments make bugs easier to find

---

## CI/CD Integration

### Test Automation Pipeline

**Typical CI/CD Test Flow**:
```yaml
# .github/workflows/test.yml
name: Test Pipeline

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run unit tests
        run: npm test -- --coverage

      - name: Run integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/coverage-final.json

      - name: Run E2E tests
        run: npm run test:e2e

      - name: Archive test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

### Test Stages in Pipeline

**1. Fast Feedback Loop**:
```yaml
# Run unit tests first (fastest)
- name: Unit Tests
  run: npm test
  timeout-minutes: 5
```

**2. Integration Tests**:
```yaml
# Start database service
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: test
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5

- name: Integration Tests
  run: npm run test:integration
  timeout-minutes: 10
```

**3. E2E Tests** (only on main branch or release):
```yaml
- name: E2E Tests
  if: github.ref == 'refs/heads/main'
  run: npm run test:e2e
  timeout-minutes: 20
```

### Parallel Test Execution

**Jest Parallel Configuration**:
```json
// jest.config.js
module.exports = {
  maxWorkers: '50%', // Use 50% of available CPUs
  testPathIgnorePatterns: ['/node_modules/'],
  coveragePathIgnorePatterns: ['/node_modules/', '/tests/'],
};
```

**Cypress Parallel Execution**:
```bash
# Run tests in parallel across 4 machines
cypress run --parallel --record --key=<record-key> --ci-build-id=$CI_BUILD_ID
```

### Test Quality Gates

**Fail Build on Coverage Drop**:
```json
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

**SonarQube Quality Gate**:
```yaml
- name: SonarQube Scan
  uses: SonarSource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## Testing Frameworks by Language

### JavaScript/TypeScript

#### Jest (Most Popular)
```javascript
// Comprehensive features out-of-box
const sum = require('./sum');

describe('sum function', () => {
  test('adds 1 + 2 to equal 3', () => {
    expect(sum(1, 2)).toBe(3);
  });

  test('handles negative numbers', () => {
    expect(sum(-1, 1)).toBe(0);
  });
});

// Async testing
test('fetches user data', async () => {
  const user = await fetchUser(1);
  expect(user.name).toBe('John');
});

// Mocking
jest.mock('./api');
```

**Installation**:
```bash
npm install --save-dev jest
```

**Run**:
```bash
npm test
npm test -- --coverage
npm test -- --watch
```

#### Vitest (Modern, Fast)
```javascript
// Similar API to Jest, but faster
import { describe, it, expect } from 'vitest';
import { sum } from './sum';

describe('sum', () => {
  it('adds numbers', () => {
    expect(sum(1, 2)).toBe(3);
  });
});
```

### Python

#### PyTest (Recommended)
```python
# test_calculator.py
import pytest
from calculator import Calculator

class TestCalculator:
    @pytest.fixture
    def calculator(self):
        return Calculator()

    def test_add(self, calculator):
        assert calculator.add(2, 3) == 5

    def test_divide_by_zero(self, calculator):
        with pytest.raises(ValueError, match="Cannot divide by zero"):
            calculator.divide(10, 0)

    @pytest.mark.parametrize("a,b,expected", [
        (2, 3, 5),
        (0, 0, 0),
        (-1, 1, 0),
        (100, 200, 300)
    ])
    def test_add_multiple(self, calculator, a, b, expected):
        assert calculator.add(a, b) == expected
```

**Installation**:
```bash
pip install pytest pytest-cov
```

**Run**:
```bash
pytest
pytest --cov=src --cov-report=html
pytest -v  # Verbose
pytest -k "test_add"  # Run specific tests
```

### Java

#### JUnit 5
```java
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Calculator Tests")
class CalculatorTest {

    private Calculator calculator;

    @BeforeEach
    void setUp() {
        calculator = new Calculator();
    }

    @Test
    @DisplayName("Should add two numbers")
    void testAdd() {
        assertEquals(5, calculator.add(2, 3));
    }

    @Test
    void testDivideByZero() {
        assertThrows(ArithmeticException.class, () -> {
            calculator.divide(10, 0);
        });
    }

    @ParameterizedTest
    @CsvSource({
        "2, 3, 5",
        "0, 0, 0",
        "-1, 1, 0",
        "100, 200, 300"
    })
    void testAddMultiple(int a, int b, int expected) {
        assertEquals(expected, calculator.add(a, b));
    }
}
```

**Maven Configuration**:
```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>
```

### Go

#### Built-in Testing Package
```go
// calculator_test.go
package calculator

import "testing"

func TestAdd(t *testing.T) {
    result := Add(2, 3)
    expected := 5

    if result != expected {
        t.Errorf("Add(2, 3) = %d; want %d", result, expected)
    }
}

func TestAddTableDriven(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"zeros", 0, 0, 0},
        {"negative", -1, 1, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("got %d, want %d", result, tt.expected)
            }
        })
    }
}

// Benchmark
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(2, 3)
    }
}
```

**Run**:
```bash
go test ./...
go test -cover
go test -bench=.
```

---

## Advanced Testing Techniques

### Contract Testing

**For Microservices Communication**:

```javascript
// Using Pact for consumer-driven contract testing
const { PactV3 } = require('@pact-foundation/pact');

describe('User Service Contract', () => {
  const provider = new PactV3({
    consumer: 'UserUI',
    provider: 'UserService'
  });

  test('should get user by ID', async () => {
    // Define expected interaction
    provider
      .given('user with ID 1 exists')
      .uponReceiving('a request for user 1')
      .withRequest({
        method: 'GET',
        path: '/users/1'
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          id: 1,
          name: 'John Doe',
          email: 'john@example.com'
        }
      });

    // Execute test
    await provider.executeTest(async (mockServer) => {
      const response = await fetch(`${mockServer.url}/users/1`);
      const user = await response.json();

      expect(user.id).toBe(1);
      expect(user.name).toBe('John Doe');
    });
  });
});
```

### Snapshot Testing

**React Component Testing**:
```javascript
import { render } from '@testing-library/react';
import UserProfile from './UserProfile';

test('renders user profile correctly', () => {
  const user = { name: 'John', email: 'john@example.com' };
  const { container } = render(<UserProfile user={user} />);

  // Creates snapshot on first run, compares on subsequent runs
  expect(container).toMatchSnapshot();
});
```

### Mutation Testing

**Ensure Test Quality**:
```bash
# Install Stryker (JavaScript mutation testing)
npm install --save-dev @stryker-mutator/core

# Run mutation testing
npx stryker run

# Stryker mutates code (e.g., changes + to -, removes conditions)
# If tests still pass, they're weak!
```

### Performance Testing

**Load Testing with k6**:
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },  // Ramp up to 50 users
    { duration: '3m', target: 50 },  // Stay at 50 users
    { duration: '1m', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],   // Less than 1% failures
  },
};

export default function () {
  const response = http.get('https://api.example.com/users');

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

---

## Best Practices and Anti-Patterns

### ✅ Best Practices

1. **Write Descriptive Test Names**
```javascript
// Good
test('should return 404 when user does not exist')

// Bad
test('test1')
test('user test')
```

2. **One Assertion Per Test (when practical)**
```javascript
// Good - focused test
test('should hash password', () => {
  const hashed = hashPassword('plain');
  expect(hashed).not.toBe('plain');
});

test('should generate different hashes for same password', () => {
  const hash1 = hashPassword('plain');
  const hash2 = hashPassword('plain');
  expect(hash1).not.toBe(hash2);
});

// Acceptable - related assertions
test('should create user with correct properties', () => {
  const user = createUser(data);
  expect(user.id).toBeDefined();
  expect(user.email).toBe(data.email);
  expect(user.password).not.toBe(data.password); // hashed
});
```

3. **Use Test Fixtures and Factories**
4. **Keep Tests Fast**
5. **Make Tests Deterministic**
6. **Test Behavior, Not Implementation**

### ❌ Anti-Patterns

1. **Testing Private Methods**
```javascript
// Bad - testing implementation details
test('_parseUserData should parse correctly', () => {
  const result = userService._parseUserData(data);
  // ...
});

// Good - test public API
test('createUser should accept valid user data', () => {
  const user = userService.createUser(data);
  // ...
});
```

2. **Excessive Mocking**
```javascript
// Bad - mocking everything
jest.mock('./database');
jest.mock('./emailService');
jest.mock('./logger');
jest.mock('./validator');
// You're testing mocks, not real code!

// Good - mock only external dependencies
jest.mock('./database'); // External dependency
// Test real validator, logger logic
```

3. **Test Interdependence**
```javascript
// Bad - tests depend on each other
let userId;

test('create user', () => {
  userId = createUser().id;
});

test('update user', () => {
  updateUser(userId, data); // Breaks if first test fails!
});
```

4. **Testing Framework Code**
```javascript
// Bad - testing library functionality
test('express should route correctly', () => {
  // Testing Express, not your code
});
```

5. **Brittle Selectors in E2E**
```javascript
// Bad - fragile
await page.click('.btn.btn-primary.submit-button');

// Good - stable
await page.click('[data-testid="submit-button"]');
```

### Test Smells

- **Slow tests**: Unit tests taking seconds instead of milliseconds
- **Flaky tests**: Tests that intermittently fail
- **Mystery guest**: Tests that depend on external state
- **Eager test**: Testing multiple things at once
- **Test code duplication**: Copy-pasted test code
- **Lack of assertions**: Tests that don't verify anything

---

## Testing Checklist

### Unit Testing
- [ ] Tests are fast (< 100ms each)
- [ ] Tests are isolated (no shared state)
- [ ] Mocks used for external dependencies
- [ ] Edge cases and error conditions tested
- [ ] Code coverage meets threshold (70%+)
- [ ] Descriptive test names
- [ ] AAA pattern followed

### Integration Testing
- [ ] Database interactions tested
- [ ] API endpoints tested
- [ ] Test data cleanup implemented
- [ ] Test containers used for dependencies
- [ ] Error scenarios tested
- [ ] Test fixtures/factories created

### E2E Testing
- [ ] Critical user journeys covered
- [ ] Stable selectors used (data-testid)
- [ ] Proper wait strategies
- [ ] Tests independent and idempotent
- [ ] Screenshot/video on failure
- [ ] Reasonable test count (not too many)

### CI/CD Integration
- [ ] Tests run on every commit
- [ ] Fast tests run first (unit → integration → E2E)
- [ ] Coverage reports generated
- [ ] Failed builds block merges
- [ ] Test results archived
- [ ] Parallel execution enabled

### General
- [ ] TDD practiced for new features
- [ ] Tests serve as documentation
- [ ] Regular test maintenance
- [ ] Flaky tests fixed immediately
- [ ] Test code quality matches production code

---

## Recommended Resources

### Books
- "Test Driven Development: By Example" - Kent Beck
- "The Art of Unit Testing" - Roy Osherove
- "Growing Object-Oriented Software, Guided by Tests" - Steve Freeman

### Online
- [Jest Documentation](https://jestjs.io/)
- [PyTest Documentation](https://docs.pytest.org/)
- [Cypress Documentation](https://docs.cypress.io/)
- [Playwright Documentation](https://playwright.dev/)
- [Testing Library](https://testing-library.com/)

### Tools
- Test Coverage: Codecov, Coveralls
- Mutation Testing: Stryker, PIT
- Performance: k6, JMeter, Gatling

---

## Summary

Testing is not optional—it's a fundamental practice for professional software development. By following the test pyramid, practicing TDD, and automating tests in CI/CD, you build confidence in your code and enable rapid, safe delivery.

**Key Takeaways**:
1. Write **more unit tests**, some integration tests, few E2E tests
2. Practice **TDD** for better design and coverage
3. **Automate** everything in CI/CD
4. Keep tests **fast**, **isolated**, and **deterministic**
5. Test **behavior**, not implementation details
6. **Maintain** tests like production code

Happy testing! 🧪
