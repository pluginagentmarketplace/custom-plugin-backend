# REST APIs: Comprehensive Guide

## Table of Contents
1. [Introduction to REST](#introduction-to-rest)
2. [REST Principles](#rest-principles)
3. [Richardson Maturity Model](#richardson-maturity-model)
4. [HTTP Methods](#http-methods)
5. [Resource Naming Conventions](#resource-naming-conventions)
6. [HATEOAS](#hateoas)
7. [Best Practices](#best-practices)
8. [Practical Examples](#practical-examples)

## Introduction to REST

REST (Representational State Transfer) is an architectural style for designing networked applications. It was introduced by Roy Fielding in his doctoral dissertation in 2000. REST emphasizes simplicity, scalability, and the use of HTTP standard methods, making it the most widely adopted architecture for web APIs.

### Why REST?
- **Simplicity**: Leverages existing HTTP infrastructure
- **Scalability**: Stateless nature enables horizontal scaling
- **Flexibility**: Platform and language independent
- **Performance**: Built-in HTTP caching support
- **Reliability**: Well-understood patterns and practices

## REST Principles

REST is defined by six architectural constraints that guide API design:

### 1. Client-Server Architecture
**Principle**: Separation of concerns between client and server.

**Benefits**:
- Independent evolution of client and server
- Improved scalability
- Better portability across platforms
- Simplified server components

**Implementation**:
```
Client (Browser, Mobile App, CLI)
    ↓ HTTP Request
Server (API)
    ↓ HTTP Response
Client receives data
```

### 2. Statelessness
**Principle**: Each request from client to server must contain all information needed to understand the request. The server should not store client context between requests.

**Benefits**:
- Improved scalability (any server can handle any request)
- Better reliability (no session state to lose)
- Easier debugging (each request is independent)
- Simplified server design

**Example**:
```http
# ❌ Bad: Stateful approach (requires session)
POST /api/cart/add
{
  "productId": 123
}

# ✅ Good: Stateless approach (all context in request)
POST /api/users/456/cart/items
Authorization: Bearer eyJhbGc...
{
  "productId": 123,
  "quantity": 1
}
```

### 3. Cacheability
**Principle**: Responses must define themselves as cacheable or non-cacheable to improve performance.

**HTTP Cache Headers**:
```http
# Response with cache control
HTTP/1.1 200 OK
Cache-Control: max-age=3600, public
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
Last-Modified: Wed, 15 Jan 2025 10:30:00 GMT

# Conditional request
GET /api/users/123
If-None-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"

# Not modified response
HTTP/1.1 304 Not Modified
```

**Benefits**:
- Reduced bandwidth usage
- Lower server load
- Improved response times
- Better user experience

### 4. Uniform Interface
**Principle**: Standardized way of communicating between client and server using HTTP methods.

**Four Interface Constraints**:

1. **Resource Identification**: Resources identified by URIs
   ```
   https://api.example.com/users/123
   https://api.example.com/posts/456/comments
   ```

2. **Resource Manipulation through Representations**: Clients manipulate resources through representations (JSON, XML)
   ```json
   {
     "id": 123,
     "name": "John Doe",
     "email": "john@example.com"
   }
   ```

3. **Self-Descriptive Messages**: Each message includes enough information to describe how to process it
   ```http
   POST /api/users HTTP/1.1
   Host: api.example.com
   Content-Type: application/json
   Accept: application/json
   ```

4. **Hypermedia as the Engine of Application State (HATEOAS)**: Responses include links to related resources

### 5. Layered System
**Principle**: Architecture can be composed of hierarchical layers, with each layer only knowing about the immediate layer with which it is interacting.

**Example Architecture**:
```
Client
  ↓
Load Balancer
  ↓
API Gateway
  ↓
Application Server
  ↓
Database
```

**Benefits**:
- Improved security (intermediary layers can inspect/filter)
- Load balancing
- Caching layers
- Better scalability

### 6. Code on Demand (Optional)
**Principle**: Servers can extend client functionality by transferring executable code.

**Examples**:
- JavaScript sent to browser
- Mobile SDK updates
- Plugin systems

## Richardson Maturity Model

Leonard Richardson proposed a model in 2008 to classify Web APIs based on their adherence to RESTful design. The model has four levels (0-3), with each level building upon the previous.

### Level 0: The Swamp of POX (Plain Old XML)

**Characteristics**:
- Single endpoint
- All operations through POST
- No use of HTTP features
- Remote Procedure Call (RPC) style

**Example**:
```http
# All operations to single endpoint
POST /api HTTP/1.1
Content-Type: application/json

# Get user
{
  "method": "getUser",
  "params": {"id": 123}
}

# Create user
{
  "method": "createUser",
  "params": {"name": "John", "email": "john@example.com"}
}

# Delete user
{
  "method": "deleteUser",
  "params": {"id": 123}
}
```

**Problems**:
- No semantic use of HTTP
- All responses return 200 OK
- No caching possible
- Not RESTful at all

### Level 1: Resources

**Characteristics**:
- Multiple URIs for different resources
- Still primarily using POST
- Resource identification through URIs
- Beginning of RESTful thinking

**Example**:
```http
# Different endpoints for different resources
POST /api/users
POST /api/users/123
POST /api/posts
POST /api/posts/456
```

**Improvement**:
- Better organization of endpoints
- Resource-based thinking
- Still not using HTTP verbs properly

### Level 2: HTTP Verbs

**Characteristics**:
- Proper use of HTTP methods (GET, POST, PUT, DELETE, PATCH)
- Appropriate HTTP status codes
- CRUD operations mapped to HTTP verbs
- Idempotent operations where appropriate

**Example**:
```http
# Proper use of HTTP methods
GET /api/users/123              # Retrieve user
POST /api/users                 # Create user
PUT /api/users/123              # Update user (full)
PATCH /api/users/123            # Update user (partial)
DELETE /api/users/123           # Delete user

# Appropriate status codes
HTTP/1.1 200 OK                 # Success
HTTP/1.1 201 Created            # Resource created
HTTP/1.1 204 No Content         # Success, no body
HTTP/1.1 404 Not Found          # Resource not found
```

**Benefits**:
- Semantic HTTP usage
- Proper status codes
- Cacheable GET requests
- Idempotent PUT/DELETE

**Most APIs stop here** - This is considered "good enough" REST for most use cases.

### Level 3: Hypermedia Controls (HATEOAS)

**Characteristics**:
- Hypermedia links in responses
- Self-descriptive API
- Dynamic navigation
- Discoverability of API capabilities

**Example**:
```http
GET /api/users/123 HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "_links": {
    "self": {
      "href": "https://api.example.com/users/123"
    },
    "orders": {
      "href": "https://api.example.com/users/123/orders"
    },
    "edit": {
      "href": "https://api.example.com/users/123",
      "method": "PUT"
    },
    "delete": {
      "href": "https://api.example.com/users/123",
      "method": "DELETE"
    }
  }
}
```

**Benefits**:
- Reduced client-server coupling
- API evolution without breaking clients
- Self-documenting responses
- Discoverability

**Challenges**:
- More complex to implement
- Larger response payloads
- Few clients utilize hypermedia
- Limited tooling support

## HTTP Methods

HTTP methods define the type of operation to perform on a resource. Each method has specific semantics and characteristics.

### Method Characteristics

| Method | Safe | Idempotent | Cacheable |
|--------|------|------------|-----------|
| GET | Yes | Yes | Yes |
| POST | No | No | Conditional |
| PUT | No | Yes | No |
| PATCH | No | No | No |
| DELETE | No | Yes | No |
| HEAD | Yes | Yes | Yes |
| OPTIONS | Yes | Yes | No |

**Definitions**:
- **Safe**: Does not modify resource state
- **Idempotent**: Multiple identical requests have same effect as single request
- **Cacheable**: Response can be cached for future use

### GET - Retrieve Resource

**Purpose**: Retrieve resource representation

**Characteristics**:
- Safe operation (no side effects)
- Idempotent (multiple calls return same result)
- Cacheable
- Should never modify server state

**Status Codes**:
- `200 OK`: Success
- `304 Not Modified`: Resource not modified (conditional GET)
- `404 Not Found`: Resource doesn't exist

**Examples**:
```http
# Get single user
GET /api/users/123 HTTP/1.1
Accept: application/json

HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: max-age=300

{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com"
}

# Get collection with query parameters
GET /api/users?page=1&limit=20&role=admin HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}

# Conditional GET with ETag
GET /api/users/123 HTTP/1.1
If-None-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"

HTTP/1.1 304 Not Modified
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
```

**Best Practices**:
- Use query parameters for filtering, sorting, pagination
- Support conditional requests (ETag, Last-Modified)
- Implement caching headers
- Return appropriate status codes
- Include pagination metadata for collections

### POST - Create Resource

**Purpose**: Create new resource or trigger action

**Characteristics**:
- Not safe (modifies state)
- Not idempotent (multiple calls create multiple resources)
- Not cacheable by default

**Status Codes**:
- `201 Created`: Resource created successfully
- `200 OK`: Action completed (non-creation)
- `400 Bad Request`: Invalid data
- `409 Conflict`: Resource already exists

**Examples**:
```http
# Create user
POST /api/users HTTP/1.1
Content-Type: application/json

{
  "name": "Jane Smith",
  "email": "jane@example.com"
}

HTTP/1.1 201 Created
Location: https://api.example.com/users/124
Content-Type: application/json

{
  "id": 124,
  "name": "Jane Smith",
  "email": "jane@example.com",
  "createdAt": "2025-01-15T10:30:00Z"
}

# Trigger action (non-creation)
POST /api/users/123/send-welcome-email HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/json

{
  "message": "Welcome email sent",
  "sentAt": "2025-01-15T10:35:00Z"
}

# Validation error
POST /api/users HTTP/1.1
Content-Type: application/json

{
  "name": "",
  "email": "invalid-email"
}

HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "name",
        "message": "Name is required"
      },
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

**Best Practices**:
- Return created resource in response body
- Include Location header with URI of created resource
- Return 201 for creation, 200 for actions
- Validate input thoroughly
- Provide detailed validation errors

### PUT - Update/Replace Resource

**Purpose**: Update existing resource (full replacement)

**Characteristics**:
- Not safe (modifies state)
- Idempotent (multiple calls produce same result)
- Not cacheable

**Status Codes**:
- `200 OK`: Update successful, returning resource
- `204 No Content`: Update successful, no response body
- `404 Not Found`: Resource doesn't exist

**Examples**:
```http
# Update user (full replacement)
PUT /api/users/123 HTTP/1.1
Content-Type: application/json

{
  "name": "John Updated",
  "email": "john.updated@example.com",
  "role": "admin"
}

HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "name": "John Updated",
  "email": "john.updated@example.com",
  "role": "admin",
  "updatedAt": "2025-01-15T10:40:00Z"
}

# Idempotent behavior
# First call
PUT /api/users/123 HTTP/1.1
{"name": "John", "email": "john@example.com"}
HTTP/1.1 200 OK

# Second call (same data, same result)
PUT /api/users/123 HTTP/1.1
{"name": "John", "email": "john@example.com"}
HTTP/1.1 200 OK
# Resource state unchanged
```

**Best Practices**:
- Require all fields (or use defaults)
- Return updated resource or 204
- Ensure idempotency
- Validate all fields
- Consider using PATCH for partial updates

### PATCH - Partial Update

**Purpose**: Partially update resource (only changed fields)

**Characteristics**:
- Not safe (modifies state)
- Not idempotent (depends on implementation)
- Not cacheable

**Status Codes**:
- `200 OK`: Update successful
- `204 No Content`: Update successful, no body
- `404 Not Found`: Resource doesn't exist

**Examples**:
```http
# Partial update (only name)
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{
  "name": "John Modified"
}

HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "name": "John Modified",
  "email": "john@example.com",  // Unchanged
  "role": "user",                // Unchanged
  "updatedAt": "2025-01-15T10:45:00Z"
}

# JSON Patch (RFC 6902)
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json-patch+json

[
  { "op": "replace", "path": "/name", "value": "John Patched" },
  { "op": "add", "path": "/phone", "value": "+1234567890" }
]

HTTP/1.1 200 OK
```

**Best Practices**:
- Only update provided fields
- Support JSON Patch for complex updates
- Return updated resource
- Validate partial data
- Document which fields can be patched

### DELETE - Remove Resource

**Purpose**: Remove resource from server

**Characteristics**:
- Not safe (modifies state)
- Idempotent (deleting multiple times has same effect)
- Not cacheable

**Status Codes**:
- `200 OK`: Deleted, returning deleted resource
- `204 No Content`: Deleted, no response body
- `404 Not Found`: Resource doesn't exist

**Examples**:
```http
# Delete user
DELETE /api/users/123 HTTP/1.1

HTTP/1.1 204 No Content

# Delete user (returning deleted resource)
DELETE /api/users/123 HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "name": "John Doe",
  "deleted": true,
  "deletedAt": "2025-01-15T10:50:00Z"
}

# Idempotent behavior
# First delete
DELETE /api/users/123
HTTP/1.1 204 No Content

# Second delete (same result)
DELETE /api/users/123
HTTP/1.1 404 Not Found
# Resource already gone, which is the desired state
```

**Best Practices**:
- Return 204 for successful deletion
- Consider soft deletes for auditing
- Make operation idempotent
- Return 404 on already deleted resource
- Consider cascade delete implications

### HEAD - Retrieve Headers

**Purpose**: Retrieve headers only (no body)

**Characteristics**:
- Safe operation
- Idempotent
- Cacheable

**Use Cases**:
- Check if resource exists
- Get metadata without body
- Verify ETag/Last-Modified
- Check content size

**Example**:
```http
HEAD /api/users/123 HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 256
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
Last-Modified: Wed, 15 Jan 2025 10:30:00 GMT
# No response body
```

### OPTIONS - Describe Communication

**Purpose**: Describe communication options for resource

**Characteristics**:
- Safe operation
- Idempotent

**Use Cases**:
- CORS preflight requests
- Discover allowed methods
- API capabilities discovery

**Example**:
```http
OPTIONS /api/users/123 HTTP/1.1

HTTP/1.1 200 OK
Allow: GET, PUT, PATCH, DELETE, HEAD, OPTIONS
Access-Control-Allow-Methods: GET, PUT, PATCH, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
```

## Resource Naming Conventions

Proper resource naming is crucial for creating intuitive and maintainable APIs.

### General Rules

1. **Use nouns, not verbs**: Resources are things, not actions
   ```
   ✅ /api/users
   ❌ /api/getUsers
   ```

2. **Use plural nouns for collections**:
   ```
   ✅ /api/users
   ❌ /api/user
   ```

3. **Use lowercase letters**:
   ```
   ✅ /api/users
   ❌ /api/Users
   ```

4. **Use hyphens (-) for readability**, not underscores:
   ```
   ✅ /api/user-profiles
   ❌ /api/user_profiles
   ```

5. **Avoid file extensions**:
   ```
   ✅ /api/users
   ❌ /api/users.json
   ```

6. **Use forward slash (/) for hierarchy**:
   ```
   ✅ /api/users/123/orders
   ❌ /api/users-123-orders
   ```

### Resource Hierarchy

Design hierarchical URIs to represent relationships:

```
# Collections
/customers                      # All customers
/products                       # All products
/orders                         # All orders

# Individual resources
/customers/123                  # Specific customer
/products/456                   # Specific product
/orders/789                     # Specific order

# Nested resources (relationships)
/customers/123/orders           # Orders for customer 123
/customers/123/orders/789       # Specific order for customer 123
/products/456/reviews           # Reviews for product 456
/products/456/reviews/101       # Specific review

# Deep nesting (use sparingly)
/customers/123/orders/789/items           # Items in order
/customers/123/orders/789/items/5         # Specific item
```

### Query Parameters vs Path Parameters

**Path Parameters**: Identify specific resources
```
/api/users/123                  # User ID 123
/api/posts/456/comments/789     # Comment ID 789 on post 456
```

**Query Parameters**: Filter, sort, paginate collections
```
/api/users?role=admin&status=active
/api/posts?page=2&limit=20&sort=-createdAt
/api/products?category=electronics&minPrice=100&maxPrice=500
```

### Naming Examples

**Good Examples**:
```
GET    /api/v1/users
GET    /api/v1/users/123
GET    /api/v1/users/123/orders
POST   /api/v1/users
PUT    /api/v1/users/123
PATCH  /api/v1/users/123
DELETE /api/v1/users/123

GET    /api/v1/products?category=electronics&inStock=true
GET    /api/v1/orders?status=pending&page=1&limit=20
```

**Bad Examples**:
```
GET    /api/v1/getUsers                    # Verb in URI
POST   /api/v1/createUser                  # Verb in URI
GET    /api/v1/user/123                    # Singular for collection
GET    /api/v1/users_list                  # Underscore
GET    /api/v1/users.json                  # File extension
GET    /api/v1/Users                       # Uppercase
```

### Special Cases

**Actions/Operations**:
When an action doesn't fit CRUD, use a verb as a resource:
```
POST /api/users/123/activate
POST /api/orders/456/cancel
POST /api/invoices/789/send
POST /api/users/123/password-reset
```

**Searches**:
```
GET /api/search?q=query&type=users
GET /api/users/search?name=john
```

**Bulk Operations**:
```
POST /api/users/bulk-create
PUT  /api/users/bulk-update
DELETE /api/users/bulk-delete
```

## HATEOAS

HATEOAS (Hypermedia as the Engine of Application State) is the highest level of REST maturity. It means responses include links to related resources, allowing clients to navigate the API dynamically.

### Benefits

1. **Self-Descriptive API**: Clients can discover available actions
2. **Reduced Coupling**: Clients don't hardcode URIs
3. **API Evolution**: Server can change URIs without breaking clients
4. **Discoverability**: New capabilities automatically exposed
5. **Simplified Clients**: Follow links instead of constructing URIs

### Implementation Approaches

#### HAL (Hypertext Application Language)

```json
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "_links": {
    "self": {
      "href": "https://api.example.com/users/123"
    },
    "orders": {
      "href": "https://api.example.com/users/123/orders"
    },
    "friends": {
      "href": "https://api.example.com/users/123/friends"
    }
  },
  "_embedded": {
    "recentOrders": [
      {
        "id": 789,
        "total": 99.99,
        "_links": {
          "self": {
            "href": "https://api.example.com/orders/789"
          }
        }
      }
    ]
  }
}
```

#### JSON:API Format

```json
{
  "data": {
    "type": "users",
    "id": "123",
    "attributes": {
      "name": "John Doe",
      "email": "john@example.com"
    },
    "relationships": {
      "orders": {
        "links": {
          "self": "https://api.example.com/users/123/relationships/orders",
          "related": "https://api.example.com/users/123/orders"
        }
      }
    },
    "links": {
      "self": "https://api.example.com/users/123"
    }
  }
}
```

#### Custom Implementation

```json
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "links": {
    "self": {
      "href": "https://api.example.com/users/123",
      "method": "GET"
    },
    "update": {
      "href": "https://api.example.com/users/123",
      "method": "PUT"
    },
    "delete": {
      "href": "https://api.example.com/users/123",
      "method": "DELETE"
    },
    "orders": {
      "href": "https://api.example.com/users/123/orders",
      "method": "GET"
    },
    "createOrder": {
      "href": "https://api.example.com/users/123/orders",
      "method": "POST"
    }
  }
}
```

### Practical Example: E-commerce API

```json
// GET /api/orders/789
{
  "orderId": 789,
  "customerId": 123,
  "status": "pending",
  "total": 199.98,
  "items": [
    {
      "productId": 456,
      "name": "Widget",
      "quantity": 2,
      "price": 99.99
    }
  ],
  "createdAt": "2025-01-15T10:00:00Z",
  "_links": {
    "self": {
      "href": "https://api.example.com/orders/789",
      "method": "GET"
    },
    "customer": {
      "href": "https://api.example.com/customers/123",
      "method": "GET"
    },
    "items": {
      "href": "https://api.example.com/orders/789/items",
      "method": "GET"
    },
    "cancel": {
      "href": "https://api.example.com/orders/789/cancel",
      "method": "POST",
      "description": "Cancel this order"
    },
    "payment": {
      "href": "https://api.example.com/orders/789/payment",
      "method": "POST",
      "description": "Submit payment for order"
    }
  }
}

// After payment, links change
{
  "orderId": 789,
  "status": "paid",
  "total": 199.98,
  "_links": {
    "self": {
      "href": "https://api.example.com/orders/789"
    },
    "customer": {
      "href": "https://api.example.com/customers/123"
    },
    "invoice": {
      "href": "https://api.example.com/orders/789/invoice",
      "method": "GET",
      "description": "Download invoice"
    },
    "track": {
      "href": "https://api.example.com/orders/789/tracking",
      "method": "GET",
      "description": "Track shipment"
    }
    // Note: cancel and payment links removed (no longer available)
  }
}
```

## Best Practices

### 1. Pagination

Always paginate large collections:

```http
GET /api/users?page=1&limit=20 HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 500,
    "pages": 25,
    "prev": null,
    "next": "https://api.example.com/users?page=2&limit=20"
  }
}
```

**Pagination Strategies**:
- **Offset/Limit**: `?page=1&limit=20` (simple, but inefficient for large datasets)
- **Cursor**: `?cursor=abc123&limit=20` (efficient, handles real-time changes)
- **Keyset**: `?after_id=123&limit=20` (efficient for sorted data)

### 2. Filtering

Allow filtering collections:

```http
GET /api/users?role=admin&status=active&department=engineering
GET /api/products?category=electronics&minPrice=100&maxPrice=500&inStock=true
```

### 3. Sorting

Support sorting:

```http
GET /api/users?sort=name           # Ascending
GET /api/users?sort=-createdAt     # Descending (prefix with -)
GET /api/users?sort=name,-age      # Multiple fields
```

### 4. Field Selection (Sparse Fieldsets)

Allow clients to request specific fields:

```http
GET /api/users/123?fields=id,name,email

{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com"
  // Other fields omitted
}
```

### 5. Embedding Related Resources

Allow embedding related resources to reduce requests:

```http
GET /api/users/123?embed=orders,profile

{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "orders": [...],
  "profile": {...}
}
```

### 6. Versioning

Version your API from the start:

```
# URI versioning (most common)
https://api.example.com/v1/users
https://api.example.com/v2/users

# Header versioning
Accept-Version: v1
X-API-Version: 2

# Content negotiation
Accept: application/vnd.example.v1+json
```

### 7. Rate Limiting

Implement and communicate rate limits:

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1705329600

# When rate limited
HTTP/1.1 429 Too Many Requests
Retry-After: 3600
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705329600

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Please try again in 60 minutes."
  }
}
```

### 8. Compression

Enable compression to reduce bandwidth:

```http
GET /api/users HTTP/1.1
Accept-Encoding: gzip, br

HTTP/1.1 200 OK
Content-Encoding: gzip
Content-Type: application/json
```

### 9. CORS

Configure CORS for cross-origin requests:

```http
OPTIONS /api/users HTTP/1.1
Origin: https://example.com

HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 86400
```

### 10. ETags for Concurrency Control

Use ETags to prevent concurrent update conflicts:

```http
# Client gets resource with ETag
GET /api/users/123
HTTP/1.1 200 OK
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

# Client updates with If-Match header
PUT /api/users/123
If-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"
{...}

# Success if ETag matches
HTTP/1.1 200 OK

# Conflict if resource changed
HTTP/1.1 412 Precondition Failed
{
  "error": {
    "code": "PRECONDITION_FAILED",
    "message": "Resource has been modified. Please refresh and try again."
  }
}
```

## Practical Examples

### Complete User Management API

```http
# List users
GET /api/v1/users?page=1&limit=20&role=admin&sort=-createdAt
Authorization: Bearer eyJhbGc...

# Get single user
GET /api/v1/users/123
Authorization: Bearer eyJhbGc...

# Create user
POST /api/v1/users
Authorization: Bearer eyJhbGc...
Content-Type: application/json

{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "role": "user"
}

# Update user (full)
PUT /api/v1/users/123
Authorization: Bearer eyJhbGc...
Content-Type: application/json

{
  "name": "Jane Updated",
  "email": "jane.updated@example.com",
  "role": "admin"
}

# Update user (partial)
PATCH /api/v1/users/123
Authorization: Bearer eyJhbGc...
Content-Type: application/json

{
  "role": "admin"
}

# Delete user
DELETE /api/v1/users/123
Authorization: Bearer eyJhbGc...

# Get user's orders
GET /api/v1/users/123/orders?status=pending
Authorization: Bearer eyJhbGc...

# Search users
GET /api/v1/users/search?q=john&fields=name,email
Authorization: Bearer eyJhbGc...
```

### Response Examples

**Success Response**:
```json
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "admin",
  "status": "active",
  "createdAt": "2025-01-10T10:00:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

**Collection Response with Pagination**:
```json
{
  "data": [
    {
      "id": 123,
      "name": "John Doe",
      "email": "john@example.com"
    },
    {
      "id": 124,
      "name": "Jane Smith",
      "email": "jane@example.com"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 500,
    "pages": 25
  },
  "links": {
    "self": "https://api.example.com/users?page=1&limit=20",
    "first": "https://api.example.com/users?page=1&limit=20",
    "next": "https://api.example.com/users?page=2&limit=20",
    "last": "https://api.example.com/users?page=25&limit=20"
  }
}
```

**Error Response**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Email already exists",
        "code": "DUPLICATE_EMAIL"
      }
    ],
    "timestamp": "2025-01-15T10:30:00Z",
    "path": "/api/v1/users",
    "requestId": "abc-123-def-456"
  }
}
```

## Summary

REST APIs are the foundation of modern web services. Key takeaways:

✅ **Follow REST principles**: Statelessness, uniform interface, cacheability
✅ **Use Richardson Maturity Model**: Aim for Level 2 minimum
✅ **HTTP methods properly**: GET (retrieve), POST (create), PUT (replace), PATCH (update), DELETE (remove)
✅ **Name resources well**: Nouns, plural, lowercase, hyphens
✅ **Consider HATEOAS**: For truly RESTful APIs (Level 3)
✅ **Apply best practices**: Pagination, filtering, versioning, rate limiting
✅ **Return proper status codes**: 2xx success, 4xx client errors, 5xx server errors
✅ **Document thoroughly**: Every endpoint, parameter, and response

REST remains the most popular API style due to its simplicity, scalability, and widespread support. Master these concepts to build robust, maintainable APIs.
