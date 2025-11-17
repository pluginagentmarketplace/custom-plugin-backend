# API Documentation & Testing: Comprehensive Guide

## Table of Contents
1. [API Documentation Overview](#api-documentation-overview)
2. [OpenAPI/Swagger](#openapiswagger)
3. [Error Handling](#error-handling)
4. [API Versioning](#api-versioning)
5. [Testing Strategies](#testing-strategies)
6. [Documentation Tools](#documentation-tools)
7. [Best Practices](#best-practices)

---

## API Documentation Overview

Comprehensive API documentation enables developers to understand endpoints, required data, and expected responses efficiently.

### Why Documentation Matters

- **Developer Experience**: Well-documented APIs reduce integration time by up to 30%
- **Adoption**: Clear documentation increases API adoption
- **Support**: Reduces support requests
- **Maintenance**: Helps team understand API functionality
- **Onboarding**: New developers can start quickly

### What to Document

✅ **Getting Started Guide**
✅ **Authentication & Authorization**
✅ **All Endpoints with Examples**
✅ **Request/Response Formats**
✅ **Error Codes & Handling**
✅ **Rate Limits & Quotas**
✅ **Pagination, Filtering, Sorting**
✅ **Webhooks (if applicable)**
✅ **SDKs & Client Libraries**
✅ **Changelog & Migration Guides**
✅ **Code Examples**
✅ **Best Practices**

---

## OpenAPI/Swagger

OpenAPI Specification (formerly Swagger) is the industry-standard for describing RESTful APIs in a machine-readable format.

### Current Version: OpenAPI 3.2

Released in late 2023 with improvements:
- Enhanced webhook support
- Better security schemas
- Improved API Gateway integrations
- Better discriminator support
- Enhanced anyOf/oneOf support

### OpenAPI Structure

```yaml
openapi: 3.2.0

info:
  title: User Management API
  description: API for managing users and their resources
  version: 1.0.0
  contact:
    name: API Support
    email: support@example.com
    url: https://example.com/support
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT
  termsOfService: https://example.com/terms

servers:
  - url: https://api.example.com/v1
    description: Production server
  - url: https://staging.api.example.com/v1
    description: Staging server
  - url: http://localhost:3000/v1
    description: Local development

paths:
  /users:
    get:
      summary: List all users
      description: Retrieves a paginated list of users with optional filtering
      operationId: listUsers
      tags:
        - Users
      parameters:
        - name: page
          in: query
          description: Page number for pagination
          required: false
          schema:
            type: integer
            default: 1
            minimum: 1
        - name: limit
          in: query
          description: Number of items per page
          required: false
          schema:
            type: integer
            default: 20
            minimum: 1
            maximum: 100
        - name: role
          in: query
          description: Filter by user role
          required: false
          schema:
            type: string
            enum: [admin, editor, viewer]
        - name: sort
          in: query
          description: Sort field and direction
          required: false
          schema:
            type: string
            example: -createdAt
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
              examples:
                success:
                  value:
                    data:
                      - id: 123
                        name: John Doe
                        email: john@example.com
                        role: admin
                      - id: 124
                        name: Jane Smith
                        email: jane@example.com
                        role: editor
                    pagination:
                      page: 1
                      limit: 20
                      total: 100
                      pages: 5
        '401':
          $ref: '#/components/responses/Unauthorized'
        '429':
          $ref: '#/components/responses/TooManyRequests'
      security:
        - BearerAuth: []

    post:
      summary: Create a new user
      description: Creates a new user with the provided information
      operationId: createUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            examples:
              basic:
                value:
                  name: John Doe
                  email: john@example.com
                  role: editor
      responses:
        '201':
          description: User created successfully
          headers:
            Location:
              description: URI of the created user
              schema:
                type: string
                example: https://api.example.com/v1/users/125
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          $ref: '#/components/responses/Conflict'
      security:
        - BearerAuth: []

  /users/{userId}:
    parameters:
      - name: userId
        in: path
        required: true
        description: User ID
        schema:
          type: integer
          minimum: 1

    get:
      summary: Get user by ID
      description: Retrieves a single user by their ID
      operationId: getUser
      tags:
        - Users
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
      security:
        - BearerAuth: []

    put:
      summary: Update user
      description: Updates an existing user (full replacement)
      operationId: updateUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateUserRequest'
      responses:
        '200':
          description: User updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
      security:
        - BearerAuth: []

    delete:
      summary: Delete user
      description: Deletes a user by their ID
      operationId: deleteUser
      tags:
        - Users
      responses:
        '204':
          description: User deleted successfully
        '404':
          $ref: '#/components/responses/NotFound'
      security:
        - BearerAuth: []

components:
  schemas:
    User:
      type: object
      required:
        - id
        - name
        - email
        - role
      properties:
        id:
          type: integer
          description: User ID
          example: 123
        name:
          type: string
          description: User's full name
          example: John Doe
          minLength: 1
          maxLength: 100
        email:
          type: string
          format: email
          description: User's email address
          example: john@example.com
        role:
          type: string
          enum: [admin, editor, viewer]
          description: User's role
          example: editor
        createdAt:
          type: string
          format: date-time
          description: User creation timestamp
          example: '2025-01-15T10:30:00Z'
        updatedAt:
          type: string
          format: date-time
          description: User last update timestamp
          example: '2025-01-15T10:30:00Z'

    CreateUserRequest:
      type: object
      required:
        - name
        - email
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
          example: John Doe
        email:
          type: string
          format: email
          example: john@example.com
        role:
          type: string
          enum: [admin, editor, viewer]
          default: viewer
          example: editor

    UpdateUserRequest:
      type: object
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
          example: John Updated
        email:
          type: string
          format: email
          example: john.updated@example.com
        role:
          type: string
          enum: [admin, editor, viewer]
          example: admin

    Pagination:
      type: object
      properties:
        page:
          type: integer
          example: 1
        limit:
          type: integer
          example: 20
        total:
          type: integer
          example: 100
        pages:
          type: integer
          example: 5

    Error:
      type: object
      required:
        - code
        - message
      properties:
        code:
          type: string
          description: Error code for programmatic handling
          example: VALIDATION_ERROR
        message:
          type: string
          description: Human-readable error message
          example: Invalid input data
        details:
          type: array
          description: Detailed error information
          items:
            type: object
            properties:
              field:
                type: string
                example: email
              message:
                type: string
                example: Invalid email format
        timestamp:
          type: string
          format: date-time
          example: '2025-01-15T10:30:00Z'
        path:
          type: string
          example: /api/v1/users
        requestId:
          type: string
          example: abc-123-def-456

  responses:
    BadRequest:
      description: Bad Request - Invalid input data
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                $ref: '#/components/schemas/Error'
          example:
            error:
              code: VALIDATION_ERROR
              message: Invalid input data
              details:
                - field: email
                  message: Invalid email format
              timestamp: '2025-01-15T10:30:00Z'
              path: /api/v1/users
              requestId: abc-123-def-456

    Unauthorized:
      description: Unauthorized - Authentication required
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                $ref: '#/components/schemas/Error'
          example:
            error:
              code: AUTH_REQUIRED
              message: Authentication required

    NotFound:
      description: Not Found - Resource not found
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                $ref: '#/components/schemas/Error'
          example:
            error:
              code: RESOURCE_NOT_FOUND
              message: User not found

    Conflict:
      description: Conflict - Resource already exists
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                $ref: '#/components/schemas/Error'
          example:
            error:
              code: DUPLICATE_EMAIL
              message: Email already exists

    TooManyRequests:
      description: Too Many Requests - Rate limit exceeded
      headers:
        X-RateLimit-Limit:
          schema:
            type: integer
          description: Request limit per window
        X-RateLimit-Remaining:
          schema:
            type: integer
          description: Remaining requests in window
        X-RateLimit-Reset:
          schema:
            type: integer
          description: Unix timestamp when limit resets
        Retry-After:
          schema:
            type: integer
          description: Seconds until retry
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                $ref: '#/components/schemas/Error'

  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token obtained from /auth/login endpoint

    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: API key for server-to-server authentication

security:
  - BearerAuth: []

tags:
  - name: Users
    description: User management operations
  - name: Posts
    description: Post management operations
```

### Generating OpenAPI from Code

#### Node.js (Express + swagger-jsdoc)

```javascript
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.2.0',
    info: {
      title: 'User API',
      version: '1.0.0',
      description: 'User management API'
    },
    servers: [
      {
        url: 'http://localhost:3000/api/v1'
      }
    ]
  },
  apis: ['./routes/*.js']  // Files containing annotations
};

const specs = swaggerJsdoc(options);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

// In route file:
/**
 * @openapi
 * /users:
 *   get:
 *     summary: List all users
 *     tags: [Users]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/User'
 */
app.get('/users', (req, res) => {
  // Implementation
});

/**
 * @openapi
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - id
 *         - name
 *         - email
 *       properties:
 *         id:
 *           type: integer
 *         name:
 *           type: string
 *         email:
 *           type: string
 *           format: email
 */
```

#### Python (FastAPI)

FastAPI automatically generates OpenAPI documentation:

```python
from fastapi import FastAPI, Query
from pydantic import BaseModel, EmailStr
from typing import Optional

app = FastAPI(
    title="User Management API",
    description="API for managing users",
    version="1.0.0",
    contact={
        "name": "API Support",
        "email": "support@example.com"
    }
)

class User(BaseModel):
    id: int
    name: str
    email: EmailStr
    role: str

class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr
    role: str = "viewer"

@app.get("/users", response_model=list[User], tags=["Users"])
async def list_users(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    role: Optional[str] = Query(None, description="Filter by role")
):
    """
    List all users with pagination and filtering.

    Returns a paginated list of users.
    """
    # Implementation
    pass

@app.post("/users", response_model=User, status_code=201, tags=["Users"])
async def create_user(user: CreateUserRequest):
    """
    Create a new user.

    Creates a new user with the provided information.
    """
    # Implementation
    pass

# OpenAPI docs automatically available at:
# /docs (Swagger UI)
# /redoc (ReDoc)
# /openapi.json (OpenAPI spec)
```

### Swagger UI

Interactive API documentation with try-it-out functionality.

**Features**:
- Interactive testing of endpoints
- Automatic code generation
- Request/response examples
- Authentication support
- Multiple language code snippets

**Setup**:

```javascript
const express = require('express');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./openapi.json');

const app = express();

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: "API Documentation",
  customfavIcon: "/favicon.ico"
}));
```

### ReDoc

Modern, responsive API documentation alternative to Swagger UI.

**Features**:
- Clean, modern design
- Responsive layout
- Three-panel design
- Better for large APIs
- Markdown support

**Setup**:

```javascript
const express = require('express');
const { redoc } = require('redoc-express');

const app = express();

app.get('/docs', redoc({
  title: 'API Documentation',
  specUrl: '/openapi.json'
}));

app.get('/openapi.json', (req, res) => {
  res.json(require('./openapi.json'));
});
```

---

## Error Handling

Proper error handling helps clients understand what went wrong and how to fix it.

### HTTP Status Codes

#### 2xx Success
- `200 OK`: Standard success response
- `201 Created`: Resource created successfully
- `202 Accepted`: Request accepted for processing (async)
- `204 No Content`: Success but no content to return

#### 4xx Client Errors
- `400 Bad Request`: Malformed request syntax
- `401 Unauthorized`: Authentication required or failed
- `403 Forbidden`: Server understood but refuses to authorize
- `404 Not Found`: Resource not found
- `405 Method Not Allowed`: HTTP method not supported
- `409 Conflict`: Request conflicts with current state
- `422 Unprocessable Entity`: Semantic validation errors
- `429 Too Many Requests`: Rate limit exceeded

#### 5xx Server Errors
- `500 Internal Server Error`: Generic server error
- `502 Bad Gateway`: Invalid response from upstream
- `503 Service Unavailable`: Server temporarily unavailable
- `504 Gateway Timeout`: Upstream server timeout

### Error Response Format

#### RFC 7807 (Problem Details)

Standard format for machine-readable error details:

```json
{
  "type": "https://api.example.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 400,
  "detail": "Account balance of $50 is insufficient for transaction of $100",
  "instance": "/transactions/12345",
  "balance": 50,
  "requiredAmount": 100
}
```

#### Custom Format

Common custom error format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format",
        "code": "INVALID_EMAIL"
      },
      {
        "field": "age",
        "message": "Must be at least 18",
        "code": "AGE_TOO_LOW"
      }
    ],
    "timestamp": "2025-01-15T10:30:00Z",
    "path": "/api/v1/users",
    "requestId": "abc-123-def-456"
  }
}
```

### Error Handling Implementation

```javascript
// Custom error classes
class APIError extends Error {
  constructor(message, statusCode, code, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

class ValidationError extends APIError {
  constructor(message, details) {
    super(message, 400, 'VALIDATION_ERROR', details);
  }
}

class NotFoundError extends APIError {
  constructor(message) {
    super(message, 404, 'RESOURCE_NOT_FOUND');
  }
}

class UnauthorizedError extends APIError {
  constructor(message) {
    super(message, 401, 'AUTH_REQUIRED');
  }
}

// Global error handler middleware
app.use((err, req, res, next) => {
  // Log error
  console.error({
    error: err.message,
    stack: err.stack,
    requestId: req.id,
    path: req.path,
    method: req.method
  });

  // Determine status code
  const statusCode = err.statusCode || 500;
  const errorCode = err.code || 'INTERNAL_ERROR';

  // Don't expose internal errors in production
  const message = statusCode === 500 && process.env.NODE_ENV === 'production'
    ? 'Internal server error'
    : err.message;

  // Send error response
  res.status(statusCode).json({
    error: {
      code: errorCode,
      message,
      details: err.details,
      timestamp: new Date().toISOString(),
      path: req.path,
      requestId: req.id
    }
  });
});

// Usage in routes
app.post('/api/users', async (req, res, next) => {
  try {
    // Validation
    const errors = [];
    if (!req.body.email || !isValidEmail(req.body.email)) {
      errors.push({
        field: 'email',
        message: 'Invalid email format'
      });
    }
    if (!req.body.name || req.body.name.length < 1) {
      errors.push({
        field: 'name',
        message: 'Name is required'
      });
    }

    if (errors.length > 0) {
      throw new ValidationError('Invalid input data', errors);
    }

    // Check if user exists
    const existing = await db.users.findOne({ email: req.body.email });
    if (existing) {
      throw new APIError('Email already exists', 409, 'DUPLICATE_EMAIL');
    }

    // Create user
    const user = await db.users.create(req.body);
    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
});
```

### Application Error Codes

Organize error codes by category:

```javascript
const ErrorCodes = {
  // Authentication
  AUTH_INVALID_TOKEN: 'AUTH_INVALID_TOKEN',
  AUTH_TOKEN_EXPIRED: 'AUTH_TOKEN_EXPIRED',
  AUTH_INSUFFICIENT_PERMISSIONS: 'AUTH_INSUFFICIENT_PERMISSIONS',
  AUTH_INVALID_CREDENTIALS: 'AUTH_INVALID_CREDENTIALS',

  // Validation
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  INVALID_FORMAT: 'INVALID_FORMAT',
  MISSING_REQUIRED_FIELD: 'MISSING_REQUIRED_FIELD',
  VALUE_OUT_OF_RANGE: 'VALUE_OUT_OF_RANGE',

  // Business Logic
  INSUFFICIENT_FUNDS: 'INSUFFICIENT_FUNDS',
  DUPLICATE_ENTRY: 'DUPLICATE_ENTRY',
  RESOURCE_NOT_FOUND: 'RESOURCE_NOT_FOUND',
  OPERATION_NOT_ALLOWED: 'OPERATION_NOT_ALLOWED',

  // System
  DATABASE_ERROR: 'DATABASE_ERROR',
  EXTERNAL_SERVICE_ERROR: 'EXTERNAL_SERVICE_ERROR',
  TIMEOUT: 'TIMEOUT',
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED'
};
```

---

## API Versioning

API versioning manages changes and allows evolution without breaking existing clients.

### Versioning Strategies

#### 1. URI Versioning (Most Common)

```
https://api.example.com/v1/users
https://api.example.com/v2/users
```

**Advantages**:
✅ Easy to debug and test
✅ Clear documentation
✅ Browser-friendly
✅ Easy to cache

**Disadvantages**:
❌ Adds clutter to URIs
❌ URL changes for every version
❌ Violates REST principles

**Implementation**:

```javascript
const express = require('express');
const app = express();

// Version 1 routes
const v1Router = express.Router();
v1Router.get('/users', (req, res) => {
  // V1 implementation
  res.json({ version: 1, users: [] });
});

// Version 2 routes
const v2Router = express.Router();
v2Router.get('/users', (req, res) => {
  // V2 implementation with new fields
  res.json({ version: 2, users: [], metadata: {} });
});

app.use('/api/v1', v1Router);
app.use('/api/v2', v2Router);
```

#### 2. Header Versioning

```http
GET /api/users HTTP/1.1
Accept-Version: v1

GET /api/users HTTP/1.1
X-API-Version: 2
```

**Advantages**:
✅ Clean URIs
✅ Follows REST principles
✅ Better cache utilization

**Disadvantages**:
❌ Less visible
❌ Harder to test in browser
❌ May be overlooked

**Implementation**:

```javascript
function versionMiddleware(req, res, next) {
  const version = req.headers['accept-version'] || req.headers['x-api-version'] || 'v1';
  req.apiVersion = version;
  next();
}

app.use(versionMiddleware);

app.get('/api/users', (req, res) => {
  if (req.apiVersion === 'v1') {
    // V1 implementation
  } else if (req.apiVersion === 'v2') {
    // V2 implementation
  } else {
    res.status(400).json({ error: 'Unsupported API version' });
  }
});
```

#### 3. Content Negotiation

```http
GET /api/users HTTP/1.1
Accept: application/vnd.example.v1+json

GET /api/users HTTP/1.1
Accept: application/vnd.example.v2+json
```

**Advantages**:
✅ RESTful approach
✅ Standards-based
✅ Flexible

**Disadvantages**:
❌ Most complex
❌ Harder for clients
❌ Less intuitive

#### 4. Query Parameter (Not Recommended)

```
https://api.example.com/users?version=1
https://api.example.com/users?api-version=2
```

**Disadvantages**:
❌ Pollutes query string
❌ Can be accidentally omitted
❌ Caching complications

### Semantic Versioning

Use semantic versioning (MAJOR.MINOR.PATCH):

```
v1.0.0 - Initial release
v1.1.0 - Added new endpoint (backward compatible)
v1.1.1 - Bug fix
v2.0.0 - Breaking change (removed endpoint)
```

**Recommendations**:
- Only include MAJOR version in API path (v1, v2)
- Use full version in API responses
- Document version in headers
- Support multiple major versions simultaneously

### Deprecation Strategy

```javascript
// Deprecation headers
app.get('/api/v1/users', (req, res) => {
  res.setHeader('Warning', '299 - "Deprecated API version. Migrate to v2 by 2025-12-31"');
  res.setHeader('Sunset', 'Sat, 31 Dec 2025 23:59:59 GMT');
  res.setHeader('X-API-Deprecated', 'true');
  res.setHeader('X-API-Sunset-Date', '2025-12-31');
  res.setHeader('X-API-Migration-Guide', 'https://api.example.com/docs/migration/v1-to-v2');

  // Return data
  res.json({ users: [] });
});
```

**Deprecation Timeline**:
1. **Announcement**: Announce deprecation 3-6 months in advance
2. **Warning Period**: Add deprecation warnings to responses
3. **Sunset Date**: Set clear end-of-life date
4. **Removal**: Remove deprecated version after sunset date

**Best Practices**:
✅ Provide 30-90 days notice for minor changes
✅ Provide 3-6 months notice for major changes
✅ Never break existing versions without notice
✅ Maintain at least 2 major versions
✅ Log usage of deprecated endpoints
✅ Reach out to heavy users
✅ Provide migration guides
✅ Consider gradual rollout

---

## Testing Strategies

### 1. Unit Tests

Test individual functions and methods.

```javascript
const request = require('supertest');
const app = require('../app');

describe('User API', () => {
  describe('GET /api/users', () => {
    it('should return list of users', async () => {
      const res = await request(app)
        .get('/api/users')
        .set('Authorization', 'Bearer valid-token')
        .expect(200);

      expect(res.body).toHaveProperty('data');
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/users')
        .expect(401);

      expect(res.body.error.code).toBe('AUTH_REQUIRED');
    });

    it('should support pagination', async () => {
      const res = await request(app)
        .get('/api/users?page=1&limit=10')
        .set('Authorization', 'Bearer valid-token')
        .expect(200);

      expect(res.body.pagination).toEqual({
        page: 1,
        limit: 10,
        total: expect.any(Number),
        pages: expect.any(Number)
      });
    });
  });

  describe('POST /api/users', () => {
    it('should create new user', async () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com',
        role: 'editor'
      };

      const res = await request(app)
        .post('/api/users')
        .set('Authorization', 'Bearer valid-token')
        .send(userData)
        .expect(201);

      expect(res.body).toMatchObject(userData);
      expect(res.body).toHaveProperty('id');
      expect(res.headers.location).toMatch(/\/api\/users\/\d+/);
    });

    it('should validate required fields', async () => {
      const res = await request(app)
        .post('/api/users')
        .set('Authorization', 'Bearer valid-token')
        .send({ name: 'John Doe' })  // Missing email
        .expect(400);

      expect(res.body.error.code).toBe('VALIDATION_ERROR');
      expect(res.body.error.details).toContainEqual({
        field: 'email',
        message: expect.any(String)
      });
    });

    it('should prevent duplicate emails', async () => {
      const userData = {
        name: 'John Doe',
        email: 'existing@example.com'
      };

      const res = await request(app)
        .post('/api/users')
        .set('Authorization', 'Bearer valid-token')
        .send(userData)
        .expect(409);

      expect(res.body.error.code).toBe('DUPLICATE_EMAIL');
    });
  });
});
```

### 2. Integration Tests

Test multiple components working together.

```javascript
describe('User Workflow', () => {
  let authToken;
  let userId;

  beforeAll(async () => {
    // Login to get token
    const loginRes = await request(app)
      .post('/auth/login')
      .send({
        email: 'test@example.com',
        password: 'password'
      });

    authToken = loginRes.body.accessToken;
  });

  it('should complete full user lifecycle', async () => {
    // 1. Create user
    const createRes = await request(app)
      .post('/api/users')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Test User',
        email: 'testuser@example.com'
      })
      .expect(201);

    userId = createRes.body.id;

    // 2. Get user
    const getRes = await request(app)
      .get(`/api/users/${userId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(getRes.body.id).toBe(userId);

    // 3. Update user
    const updateRes = await request(app)
      .put(`/api/users/${userId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Updated User',
        email: 'updated@example.com'
      })
      .expect(200);

    expect(updateRes.body.name).toBe('Updated User');

    // 4. Delete user
    await request(app)
      .delete(`/api/users/${userId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(204);

    // 5. Verify deletion
    await request(app)
      .get(`/api/users/${userId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .expect(404);
  });
});
```

### 3. Load Testing

Test API performance under load using k6:

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up to 20 users
    { duration: '1m', target: 20 },   // Stay at 20 users
    { duration: '30s', target: 0 },   // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],     // Less than 1% failures
  },
};

export default function () {
  const url = 'https://api.example.com/v1/users';
  const params = {
    headers: {
      'Authorization': 'Bearer token123',
    },
  };

  const res = http.get(url, params);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}
```

Run with: `k6 run load-test.js`

### 4. Security Testing

Test for common security vulnerabilities:

```javascript
describe('Security Tests', () => {
  it('should prevent SQL injection', async () => {
    const res = await request(app)
      .get("/api/users?name='; DROP TABLE users; --")
      .set('Authorization', 'Bearer valid-token')
      .expect(200);

    // Should not execute SQL injection
  });

  it('should prevent XSS', async () => {
    const res = await request(app)
      .post('/api/users')
      .set('Authorization', 'Bearer valid-token')
      .send({
        name: '<script>alert("XSS")</script>',
        email: 'test@example.com'
      })
      .expect(201);

    // Should sanitize input
    expect(res.body.name).not.toContain('<script>');
  });

  it('should enforce rate limiting', async () => {
    const requests = Array(101).fill().map(() =>
      request(app)
        .get('/api/users')
        .set('Authorization', 'Bearer valid-token')
    );

    const results = await Promise.all(requests);
    const rateLimited = results.filter(res => res.status === 429);

    expect(rateLimited.length).toBeGreaterThan(0);
  });

  it('should require HTTPS in production', () => {
    // Verify redirect or rejection of HTTP requests
  });
});
```

### 5. Contract Testing

Ensure API matches documented contract using Pact:

```javascript
const { Pact } = require('@pact-foundation/pact');
const { like, eachLike } = require('@pact-foundation/pact/dsl/matchers');

const provider = new Pact({
  consumer: 'Client',
  provider: 'UserAPI',
  port: 3000,
});

describe('User API Contract', () => {
  beforeAll(() => provider.setup());
  afterAll(() => provider.finalize());
  afterEach(() => provider.verify());

  it('should get list of users', async () => {
    await provider.addInteraction({
      state: 'users exist',
      uponReceiving: 'a request for users',
      withRequest: {
        method: 'GET',
        path: '/api/users',
        headers: {
          Authorization: like('Bearer token123')
        }
      },
      willRespondWith: {
        status: 200,
        body: {
          data: eachLike({
            id: like(123),
            name: like('John Doe'),
            email: like('john@example.com')
          })
        }
      }
    });

    // Make actual request and verify
  });
});
```

---

## Documentation Tools

### Swagger/OpenAPI Tools

- **Swagger UI**: Interactive documentation
- **Swagger Editor**: Design and document APIs
- **Swagger Codegen**: Generate client SDKs
- **ReDoc**: Modern, responsive documentation
- **Stoplight**: Collaborative API design
- **Apidog**: API design, debugging, and testing

### Postman

- **Collections**: Organize API requests
- **Environments**: Manage variables
- **Tests**: Automated testing
- **Mock Servers**: Simulate APIs
- **Documentation**: Auto-generated docs
- **Monitors**: Scheduled test runs

### Additional Tools

- **Slate**: Beautiful static documentation
- **Docusaurus**: Documentation websites
- **ReadMe**: Automated documentation platform
- **Apiary**: API design and docs

---

## Best Practices

### Documentation

✅ **Structure**:
- Organize endpoints logically
- Use consistent formatting
- Include table of contents
- Provide getting started guide
- Group related endpoints

✅ **Content**:
- Clear, detailed descriptions
- Avoid jargon
- Include examples for all endpoints
- Show request/response examples
- Document all parameters
- List all response codes
- Include error examples

✅ **Maintenance**:
- Keep documentation up-to-date
- Version documentation with API
- Automate documentation generation
- Use version control (Git)
- Review docs in code reviews
- Test all examples regularly

✅ **Interactivity**:
- Provide try-it-out functionality
- Include sandbox environments
- Offer downloadable Postman collections
- Provide SDKs when possible

### Testing

✅ Test all endpoints
✅ Test error cases
✅ Test authentication/authorization
✅ Test rate limiting
✅ Test pagination
✅ Test edge cases
✅ Automate testing in CI/CD
✅ Monitor API in production
✅ Set up alerts for failures

### Error Handling

✅ Use appropriate HTTP status codes
✅ Provide clear, actionable error messages
✅ Include error codes for programmatic handling
✅ Don't expose sensitive information
✅ Be consistent across endpoints
✅ Include request ID for tracking
✅ Document all possible errors

## Summary

Comprehensive API documentation and testing are essential for successful API development:

- **OpenAPI/Swagger**: Industry standard for API documentation
- **Error Handling**: Proper status codes and clear error messages
- **Versioning**: Plan for API evolution without breaking clients
- **Testing**: Unit, integration, load, and security testing
- **Tools**: Leverage Swagger UI, Postman, and testing frameworks
- **Best Practices**: Keep documentation up-to-date, automate testing

Well-documented and thoroughly tested APIs reduce integration time, improve developer experience, and ensure reliability in production.
