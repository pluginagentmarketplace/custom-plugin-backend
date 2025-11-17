# Authentication & Authorization: Comprehensive Guide

## Table of Contents
1. [Introduction](#introduction)
2. [JWT (JSON Web Tokens)](#jwt-json-web-tokens)
3. [OAuth 2.0](#oauth-20)
4. [API Keys](#api-keys)
5. [Session-Based Authentication](#session-based-authentication)
6. [Basic Authentication & mTLS](#basic-authentication--mtls)
7. [RBAC (Role-Based Access Control)](#rbac-role-based-access-control)
8. [ABAC (Attribute-Based Access Control)](#abac-attribute-based-access-control)
9. [Scopes & Permissions](#scopes--permissions)
10. [Comparison & Best Practices](#comparison--best-practices)

---

## Introduction

### Authentication vs Authorization

**Authentication**: Verifying **who** the user is
- "Are you really John Doe?"
- Proves identity
- Examples: Login with username/password, OAuth, API keys

**Authorization**: Verifying **what** the user can do
- "Can John Doe access this resource?"
- Grants permissions
- Examples: RBAC, ABAC, scopes

### Security Flow

```
1. Client requests protected resource
2. Server checks authentication (who are you?)
3. Server checks authorization (what can you do?)
4. Server returns resource or error
```

---

## JWT (JSON Web Tokens)

JWT is a compact, URL-safe token format for securely transmitting information between parties as a JSON object.

### JWT Structure

A JWT consists of three parts separated by dots (`.`):

```
header.payload.signature
```

#### 1. Header

Contains token type and signing algorithm:

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

Base64Url encoded: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`

#### 2. Payload (Claims)

Contains claims (statements about entity):

```json
{
  "sub": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "roles": ["admin", "editor"],
  "iat": 1705329600,
  "exp": 1705333200,
  "iss": "https://api.example.com",
  "aud": "https://example.com"
}
```

Base64Url encoded: `eyJzdWIiOiJ1c2VyMTIzIiwibmFtZSI6IkpvaG4gRG9lIiwi...`

**Standard Claims**:
- `iss` (Issuer): Who issued the token
- `sub` (Subject): Who the token is about
- `aud` (Audience): Who the token is intended for
- `exp` (Expiration): When token expires (Unix timestamp)
- `nbf` (Not Before): Token not valid before this time
- `iat` (Issued At): When token was issued
- `jti` (JWT ID): Unique identifier for token

**Custom Claims**:
- `userId`, `roles`, `permissions`, `email`, etc.

#### 3. Signature

Ensures token hasn't been altered:

```
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

### Complete JWT Example

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwibmFtZSI6IkpvaG4gRG9lIiwiZW1haWwiOiJqb2huQGV4YW1wbGUuY29tIiwicm9sZXMiOlsiYWRtaW4iXSwiaWF0IjoxNzA1MzI5NjAwLCJleHAiOjE3MDUzMzMyMDB9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

### JWT Flow

```
1. User submits credentials
   POST /auth/login
   {"email": "john@example.com", "password": "secret"}

2. Server validates credentials
   ✓ Email exists
   ✓ Password matches (bcrypt)

3. Server generates JWT
   header = {"alg": "HS256", "typ": "JWT"}
   payload = {"sub": "user123", "roles": ["admin"], ...}
   signature = HMACSHA256(header.payload, secret)

4. Server returns JWT
   {"accessToken": "eyJhbGc...", "expiresIn": 3600}

5. Client stores JWT (localStorage, sessionStorage, cookie)

6. Client includes JWT in subsequent requests
   Authorization: Bearer eyJhbGc...

7. Server validates JWT
   ✓ Signature valid (not tampered)
   ✓ Not expired (exp > now)
   ✓ Issuer correct (iss matches)
   ✓ Audience correct (aud matches)

8. Server grants or denies access
```

### Implementation Examples

#### Node.js (Express + jsonwebtoken)

```javascript
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const SECRET_KEY = process.env.JWT_SECRET;
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

// Login endpoint
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;

  // Validate credentials
  const user = await db.users.findOne({ email });
  if (!user || !await bcrypt.compare(password, user.password)) {
    return res.status(401).json({
      error: {
        code: 'AUTH_INVALID_CREDENTIALS',
        message: 'Invalid email or password'
      }
    });
  }

  // Generate access token (short-lived)
  const accessToken = jwt.sign(
    {
      sub: user.id,
      email: user.email,
      roles: user.roles,
      iss: 'https://api.example.com',
      aud: 'https://example.com'
    },
    SECRET_KEY,
    { expiresIn: '15m' }  // 15 minutes
  );

  // Generate refresh token (long-lived)
  const refreshToken = jwt.sign(
    { sub: user.id },
    REFRESH_SECRET,
    { expiresIn: '7d' }  // 7 days
  );

  // Store refresh token in database
  await db.refreshTokens.create({
    userId: user.id,
    token: refreshToken,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
  });

  res.json({
    accessToken,
    refreshToken,
    expiresIn: 900,  // 15 minutes in seconds
    tokenType: 'Bearer'
  });
});

// Middleware to verify JWT
function authenticateJWT(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      error: {
        code: 'AUTH_TOKEN_MISSING',
        message: 'No authorization token provided'
      }
    });
  }

  const token = authHeader.split(' ')[1];  // Bearer TOKEN

  try {
    const decoded = jwt.verify(token, SECRET_KEY);

    // Attach user info to request
    req.user = {
      id: decoded.sub,
      email: decoded.email,
      roles: decoded.roles
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: {
          code: 'AUTH_TOKEN_EXPIRED',
          message: 'Token has expired'
        }
      });
    }

    return res.status(401).json({
      error: {
        code: 'AUTH_INVALID_TOKEN',
        message: 'Invalid token'
      }
    });
  }
}

// Refresh token endpoint
app.post('/auth/refresh', async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(401).json({
      error: {
        code: 'AUTH_REFRESH_TOKEN_MISSING',
        message: 'No refresh token provided'
      }
    });
  }

  try {
    // Verify refresh token
    const decoded = jwt.verify(refreshToken, REFRESH_SECRET);

    // Check if refresh token exists in database
    const storedToken = await db.refreshTokens.findOne({
      userId: decoded.sub,
      token: refreshToken
    });

    if (!storedToken) {
      return res.status(401).json({
        error: {
          code: 'AUTH_INVALID_REFRESH_TOKEN',
          message: 'Invalid refresh token'
        }
      });
    }

    // Get user
    const user = await db.users.findById(decoded.sub);

    // Generate new access token
    const accessToken = jwt.sign(
      {
        sub: user.id,
        email: user.email,
        roles: user.roles
      },
      SECRET_KEY,
      { expiresIn: '15m' }
    );

    res.json({
      accessToken,
      expiresIn: 900,
      tokenType: 'Bearer'
    });
  } catch (err) {
    return res.status(401).json({
      error: {
        code: 'AUTH_INVALID_REFRESH_TOKEN',
        message: 'Invalid or expired refresh token'
      }
    });
  }
});

// Protected endpoint
app.get('/api/profile', authenticateJWT, async (req, res) => {
  const user = await db.users.findById(req.user.id);
  res.json(user);
});

// Logout endpoint
app.post('/auth/logout', authenticateJWT, async (req, res) => {
  const { refreshToken } = req.body;

  // Remove refresh token from database
  await db.refreshTokens.deleteOne({
    userId: req.user.id,
    token: refreshToken
  });

  res.json({ message: 'Logged out successfully' });
});
```

#### Python (FastAPI + python-jose)

```python
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from pydantic import BaseModel

app = FastAPI()
security = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"])

SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15

class LoginRequest(BaseModel):
    email: str
    password: str

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire, "iat": datetime.utcnow()})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(
            credentials.credentials,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

@app.post("/auth/login")
async def login(request: LoginRequest):
    # Validate credentials
    user = db.get_user_by_email(request.email)
    if not user or not pwd_context.verify(request.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )

    # Create token
    access_token = create_access_token(
        data={"sub": user.id, "email": user.email, "roles": user.roles}
    )

    return {
        "accessToken": access_token,
        "tokenType": "bearer",
        "expiresIn": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@app.get("/api/profile")
async def get_profile(token: dict = Depends(verify_token)):
    user_id = token.get("sub")
    user = db.get_user(user_id)
    return user
```

### JWT Best Practices

✅ **Security**:
- Use strong signing algorithms (RS256 for production, not HS256)
- Keep tokens short-lived (15-60 minutes for access tokens)
- Use refresh tokens for long sessions
- Store tokens securely (httpOnly cookies or secure storage)
- Never store sensitive data in payload (it's base64 encoded, not encrypted)

✅ **Validation**:
- Validate all claims (iss, aud, exp, nbf)
- Always use HTTPS
- Implement token revocation mechanism (blacklist or database)
- Rotate signing keys regularly

✅ **Token Management**:
- Implement refresh token rotation
- Set appropriate expiration times
- Log authentication events
- Monitor for suspicious activity

### JWT Advantages

✅ Stateless (no server-side session storage)
✅ Scalable across multiple servers
✅ Works well with mobile applications
✅ Cross-domain authentication
✅ Contains user information
✅ Can be used with OAuth2

### JWT Disadvantages

❌ Cannot be revoked until expiration (without additional infrastructure)
❌ Size larger than session IDs
❌ Vulnerable if secret is compromised
❌ No built-in refresh mechanism
❌ Payload visible (only signed, not encrypted)

---

## OAuth 2.0

OAuth 2.0 is an industry-standard authorization framework that enables applications to obtain limited access to user accounts.

### OAuth 2.0 Roles

1. **Resource Owner**: User who authorizes application to access their account
2. **Client**: Application requesting access to user's account
3. **Authorization Server**: Server that authenticates user and issues access tokens
4. **Resource Server**: Server hosting protected resources, accepts access tokens

### OAuth 2.0 Grant Types

#### 1. Authorization Code Flow

**Most secure** flow for server-side applications with confidential clients.

```
┌──────────┐                                      ┌─────────────────┐
│          │                                      │  Authorization  │
│  Client  │                                      │     Server      │
│          │                                      │                 │
└─────┬────┘                                      └────────┬────────┘
      │                                                    │
      │ 1. Redirect to /authorize with                    │
      │    - client_id                                    │
      │    - redirect_uri                                 │
      │    - response_type=code                           │
      │    - scope                                        │
      │    - state (CSRF protection)                      │
      ├──────────────────────────────────────────────────>│
      │                                                    │
      │                   2. User authenticates           │
      │                      and grants permission        │
      │                                                    │
      │ 3. Redirect back with                             │
      │    authorization code                             │
      │<──────────────────────────────────────────────────┤
      │    http://client.com/callback?code=ABC&state=XYZ  │
      │                                                    │
      │ 4. Exchange code for token                        │
      │    POST /token                                    │
      │    - code=ABC                                     │
      │    - client_id                                    │
      │    - client_secret                                │
      │    - redirect_uri                                 │
      │    - grant_type=authorization_code                │
      ├──────────────────────────────────────────────────>│
      │                                                    │
      │ 5. Return access token                            │
      │<──────────────────────────────────────────────────┤
      │    {                                              │
      │      "access_token": "...",                       │
      │      "token_type": "Bearer",                      │
      │      "expires_in": 3600,                          │
      │      "refresh_token": "...",                      │
      │      "scope": "read write"                        │
      │    }                                              │
      │                                                    │
```

**Implementation Example**:

```javascript
// Step 1: Redirect to authorization server
app.get('/auth/oauth', (req, res) => {
  const authUrl = new URL('https://auth.example.com/authorize');
  authUrl.searchParams.append('client_id', process.env.CLIENT_ID);
  authUrl.searchParams.append('redirect_uri', 'http://localhost:3000/auth/callback');
  authUrl.searchParams.append('response_type', 'code');
  authUrl.searchParams.append('scope', 'read write');
  authUrl.searchParams.append('state', generateRandomState());

  res.redirect(authUrl.toString());
});

// Step 3 & 4: Handle callback and exchange code
app.get('/auth/callback', async (req, res) => {
  const { code, state } = req.query;

  // Verify state (CSRF protection)
  if (!verifyState(state)) {
    return res.status(400).json({ error: 'Invalid state' });
  }

  try {
    // Exchange code for token
    const response = await fetch('https://auth.example.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        client_id: process.env.CLIENT_ID,
        client_secret: process.env.CLIENT_SECRET,
        redirect_uri: 'http://localhost:3000/auth/callback'
      })
    });

    const tokens = await response.json();
    // Store tokens securely
    // { access_token, refresh_token, expires_in, token_type }

    res.json(tokens);
  } catch (err) {
    res.status(500).json({ error: 'Token exchange failed' });
  }
});
```

#### 2. Authorization Code with PKCE

**Most secure** for mobile and SPAs. Adds extra security without client secret.

PKCE (Proof Key for Code Exchange) prevents authorization code interception attacks.

```
1. Client generates code_verifier (random string)
   code_verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"

2. Client creates code_challenge
   code_challenge = BASE64URL(SHA256(code_verifier))
   code_challenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

3. Authorization request includes code_challenge
   /authorize?
     client_id=...
     &redirect_uri=...
     &response_type=code
     &code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
     &code_challenge_method=S256

4. Token request includes code_verifier
   POST /token
   grant_type=authorization_code
   &code=ABC
   &code_verifier=dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
   &client_id=...
   &redirect_uri=...

5. Server verifies: SHA256(code_verifier) === code_challenge
```

#### 3. Client Credentials Flow

**Machine-to-machine** authentication where client is also the resource owner.

```
┌──────────┐                                      ┌─────────────────┐
│  Client  │                                      │  Authorization  │
│          │                                      │     Server      │
└─────┬────┘                                      └────────┬────────┘
      │                                                    │
      │ POST /token                                       │
      │ - grant_type=client_credentials                   │
      │ - client_id                                       │
      │ - client_secret                                   │
      │ - scope                                           │
      ├──────────────────────────────────────────────────>│
      │                                                    │
      │ Return access token                               │
      │<──────────────────────────────────────────────────┤
      │ {                                                 │
      │   "access_token": "...",                          │
      │   "token_type": "Bearer",                         │
      │   "expires_in": 3600                              │
      │ }                                                 │
```

**Implementation**:

```javascript
// Client requests token
const response = await fetch('https://auth.example.com/token', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': `Basic ${btoa(`${CLIENT_ID}:${CLIENT_SECRET}`)}`
  },
  body: new URLSearchParams({
    grant_type: 'client_credentials',
    scope: 'api:read api:write'
  })
});

const { access_token } = await response.json();

// Use token to access API
const apiResponse = await fetch('https://api.example.com/data', {
  headers: {
    'Authorization': `Bearer ${access_token}`
  }
});
```

**Use Cases**:
- Service-to-service communication
- Backend APIs
- Microservices
- CLI tools

#### 4. Refresh Token Flow

Obtain new access token using refresh token.

```javascript
app.post('/auth/refresh', async (req, res) => {
  const { refresh_token } = req.body;

  try {
    const response = await fetch('https://auth.example.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token,
        client_id: process.env.CLIENT_ID,
        client_secret: process.env.CLIENT_SECRET
      })
    });

    const tokens = await response.json();
    // { access_token, refresh_token (optional), expires_in }

    res.json(tokens);
  } catch (err) {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});
```

#### 5. Deprecated/Discouraged Flows

**Implicit Flow** (Deprecated in OAuth 2.1):
- Token returned directly in URL fragment
- No refresh token
- Less secure
- **Use Authorization Code with PKCE instead**

**Resource Owner Password Credentials** (Discouraged):
- User provides credentials directly to client
- Only for highly trusted applications
- **Avoid when possible**

### OAuth 2.0 Tokens

#### Access Token
- Short-lived (15 minutes to 1 hour)
- Used to access protected resources
- Can be JWT or opaque token
- Include in Authorization header: `Bearer {token}`

#### Refresh Token
- Long-lived (days to months)
- Used to obtain new access tokens
- Opaque token
- Must be stored securely
- Can be revoked

#### ID Token (OpenID Connect)
- JWT containing user identity information
- Always JWT format
- Used for authentication, not authorization

### Scopes

Scopes limit application's access to user's account.

```javascript
// Request specific scopes
const authUrl = new URL('https://auth.example.com/authorize');
authUrl.searchParams.append('scope', 'read:users write:posts admin:all');

// Server validates scopes
function requireScope(...requiredScopes) {
  return (req, res, next) => {
    const tokenScopes = req.token.scope.split(' ');

    const hasScope = requiredScopes.every(scope =>
      tokenScopes.includes(scope)
    );

    if (!hasScope) {
      return res.status(403).json({
        error: {
          code: 'INSUFFICIENT_SCOPE',
          message: 'Token does not have required scope',
          required: requiredScopes,
          provided: tokenScopes
        }
      });
    }

    next();
  };
}

// Protected endpoint with scope requirement
app.delete('/api/users/:id',
  authenticateJWT,
  requireScope('admin:all'),
  async (req, res) => {
    // Delete user
  }
);
```

### OAuth 2.0 Best Practices

✅ Use Authorization Code with PKCE for SPAs and mobile apps
✅ Always use HTTPS
✅ Validate redirect URIs strictly
✅ Use state parameter to prevent CSRF
✅ Implement proper token storage
✅ Set appropriate token expiration
✅ Implement token revocation
✅ Use refresh token rotation
✅ Validate all tokens server-side
✅ Log authentication events

---

## API Keys

Simple authentication method using a unique key/token to identify the application or user.

### Implementation

#### Generating API Keys

```javascript
const crypto = require('crypto');

// Generate cryptographically secure random key
function generateApiKey() {
  return crypto.randomBytes(32).toString('hex');
  // Output: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2"
}

// Hash key before storing (like passwords)
async function hashApiKey(key) {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(key, salt);
}

// Create API key for user
app.post('/api/keys', authenticateJWT, async (req, res) => {
  const { name, scopes } = req.body;

  // Generate key
  const key = generateApiKey();
  const hashedKey = await hashApiKey(key);

  // Store in database
  const apiKey = await db.apiKeys.create({
    userId: req.user.id,
    name,
    key: hashedKey,
    scopes,
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)  // 1 year
  });

  // Return unhashed key (only time user sees it)
  res.json({
    id: apiKey.id,
    name,
    key,  // Show once, then never again
    scopes,
    createdAt: apiKey.createdAt,
    expiresAt: apiKey.expiresAt
  });
});
```

#### Using API Keys

**Method 1: Custom Header** (Recommended)
```http
GET /api/users HTTP/1.1
X-API-Key: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**Method 2: Authorization Header**
```http
GET /api/users HTTP/1.1
Authorization: ApiKey a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**Method 3: Query Parameter** (Not Recommended - logged in server logs)
```http
GET /api/users?api_key=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6 HTTP/1.1
```

#### Validating API Keys

```javascript
async function authenticateApiKey(req, res, next) {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey) {
    return res.status(401).json({
      error: {
        code: 'API_KEY_MISSING',
        message: 'API key is required'
      }
    });
  }

  try {
    // Find all keys for potential match (could optimize with indexing)
    const keys = await db.apiKeys.find({
      expiresAt: { $gt: new Date() }
    });

    let matchedKey = null;
    for (const key of keys) {
      if (await bcrypt.compare(apiKey, key.key)) {
        matchedKey = key;
        break;
      }
    }

    if (!matchedKey) {
      return res.status(401).json({
        error: {
          code: 'API_KEY_INVALID',
          message: 'Invalid API key'
        }
      });
    }

    // Update last used timestamp
    await db.apiKeys.update(matchedKey.id, {
      lastUsedAt: new Date()
    });

    // Attach to request
    req.apiKey = matchedKey;
    req.user = await db.users.findById(matchedKey.userId);

    next();
  } catch (err) {
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Internal server error'
      }
    });
  }
}

// Protected endpoint
app.get('/api/users', authenticateApiKey, async (req, res) => {
  // Check scopes
  if (!req.apiKey.scopes.includes('read:users')) {
    return res.status(403).json({
      error: {
        code: 'INSUFFICIENT_PERMISSIONS',
        message: 'API key does not have required permissions'
      }
    });
  }

  const users = await db.users.find();
  res.json(users);
});
```

#### Rate Limiting by API Key

```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

const apiKeyLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:apikey:'
  }),
  windowMs: 60 * 1000,  // 1 minute
  max: async (req) => {
    // Different limits based on API key tier
    const tier = req.apiKey.tier || 'free';
    const limits = {
      free: 60,      // 60 requests per minute
      basic: 300,    // 300 requests per minute
      premium: 1000  // 1000 requests per minute
    };
    return limits[tier];
  },
  keyGenerator: (req) => req.apiKey.id,
  handler: (req, res) => {
    res.status(429).json({
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Rate limit exceeded for API key',
        retryAfter: Math.ceil(req.rateLimit.resetTime / 1000)
      }
    });
  }
});

app.use('/api', authenticateApiKey, apiKeyLimiter);
```

### API Key Best Practices

✅ Generate cryptographically secure random keys (minimum 32 characters)
✅ Hash keys before storing in database (like passwords)
✅ Use HTTPS only
✅ Implement rate limiting per key
✅ Allow key rotation (users can regenerate keys)
✅ Support multiple keys per user
✅ Set expiration dates
✅ Log usage per key
✅ Allow key revocation
✅ Don't expose keys in client-side code
✅ Use custom header (X-API-Key), not query parameters

### API Key Advantages

✅ Simple to implement
✅ Easy for developers to use
✅ Stateless
✅ Good for server-to-server communication
✅ Easy to revoke

### API Key Disadvantages

❌ No user context
❌ Can be intercepted if not using HTTPS
❌ Difficult to implement fine-grained permissions
❌ Hard to rotate without breaking clients
❌ No built-in expiration

---

## Session-Based Authentication

Traditional authentication where server maintains session state.

### Flow

```
1. User submits credentials
   POST /auth/login
   {"email": "john@example.com", "password": "secret"}

2. Server validates credentials

3. Server creates session
   sessionId = generateRandomId()
   sessions[sessionId] = {
     userId: 123,
     email: "john@example.com",
     createdAt: Date.now()
   }

4. Server returns session ID in cookie
   Set-Cookie: sessionId=abc123; HttpOnly; Secure; SameSite=Strict

5. Client includes cookie in subsequent requests
   Cookie: sessionId=abc123

6. Server validates session
   session = sessions[req.cookies.sessionId]
   if (session && session.userId) {
     // Grant access
   }
```

### Implementation

```javascript
const session = require('express-session');
const RedisStore = require('connect-redis')(session);
const redis = require('redis');

const redisClient = redis.createClient();

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,      // HTTPS only
    httpOnly: true,    // No JavaScript access
    sameSite: 'strict',// CSRF protection
    maxAge: 24 * 60 * 60 * 1000  // 24 hours
  }
}));

// Login endpoint
app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;

  // Validate credentials
  const user = await db.users.findOne({ email });
  if (!user || !await bcrypt.compare(password, user.password)) {
    return res.status(401).json({
      error: 'Invalid credentials'
    });
  }

  // Regenerate session ID (prevent session fixation)
  req.session.regenerate((err) => {
    if (err) {
      return res.status(500).json({ error: 'Session error' });
    }

    // Store user info in session
    req.session.userId = user.id;
    req.session.email = user.email;
    req.session.roles = user.roles;

    res.json({
      message: 'Logged in successfully',
      user: {
        id: user.id,
        email: user.email,
        roles: user.roles
      }
    });
  });
});

// Middleware to check authentication
function requireAuth(req, res, next) {
  if (!req.session.userId) {
    return res.status(401).json({
      error: {
        code: 'AUTH_REQUIRED',
        message: 'Authentication required'
      }
    });
  }
  next();
}

// Protected endpoint
app.get('/api/profile', requireAuth, async (req, res) => {
  const user = await db.users.findById(req.session.userId);
  res.json(user);
});

// Logout endpoint
app.post('/auth/logout', requireAuth, (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ error: 'Logout failed' });
    }
    res.clearCookie('sessionId');
    res.json({ message: 'Logged out successfully' });
  });
});
```

### Session Storage Options

1. **In-Memory** (default, not scalable)
2. **Redis** (recommended for distributed systems)
3. **Database** (MySQL, PostgreSQL, MongoDB)
4. **Memcached**

### Cookie Settings

```javascript
{
  httpOnly: true,        // Prevents JavaScript access (XSS protection)
  secure: true,          // HTTPS only
  sameSite: 'strict',    // CSRF protection
  maxAge: 86400000,      // 24 hours in milliseconds
  domain: '.example.com',// Cookie scope
  path: '/'              // Cookie path
}
```

### Session Best Practices

✅ Regenerate session ID after login
✅ Set appropriate session timeout
✅ Use secure, httpOnly cookies
✅ Implement proper session cleanup
✅ Use CSRF tokens
✅ Store minimal data in session
✅ Use secure session storage (Redis recommended)
✅ Implement session hijacking detection

### Session Advantages

✅ Server has full control over sessions
✅ Easy to revoke access
✅ Can store arbitrary session data
✅ Well-understood pattern
✅ Built-in CSRF protection with proper setup

### Session Disadvantages

❌ Requires server-side storage
❌ Difficult to scale horizontally
❌ Not suitable for mobile apps
❌ CORS complications
❌ Session fixation vulnerabilities if not implemented correctly

---

## Basic Authentication & mTLS

### Basic Authentication

Simple HTTP authentication scheme using base64-encoded credentials.

```http
# Request
GET /api/users HTTP/1.1
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=

# dXNlcm5hbWU6cGFzc3dvcmQ= is base64("username:password")
```

**Implementation**:

```javascript
function basicAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Basic ')) {
    res.setHeader('WWW-Authenticate', 'Basic realm="API"');
    return res.status(401).json({ error: 'Authentication required' });
  }

  // Decode credentials
  const base64Credentials = authHeader.split(' ')[1];
  const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
  const [username, password] = credentials.split(':');

  // Validate credentials
  const user = db.users.findOne({ username });
  if (!user || !bcrypt.compareSync(password, user.password)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  req.user = user;
  next();
}

app.get('/api/users', basicAuth, (req, res) => {
  // Return users
});
```

**Security Concerns**:
- Credentials sent with every request
- Base64 is encoding, not encryption
- Must use HTTPS
- No logout mechanism
- Vulnerable to replay attacks

**Use Cases**:
- Internal tools
- Development/testing
- Simple authentication requirements
- Legacy system support

### Mutual TLS (mTLS)

Both client and server authenticate each other using X.509 certificates.

**Characteristics**:
- Cryptographically strong authentication
- No passwords to manage
- Suitable for machine-to-machine communication
- Built into TLS protocol

**Use Cases**:
- Microservices authentication
- High-security environments
- Banking and financial systems
- Healthcare systems
- Government applications
- IoT device authentication

---

## RBAC (Role-Based Access Control)

Access decisions based on roles assigned to users.

### Components

1. **Users**: Individuals or services that need access
2. **Roles**: Named job functions (Admin, Editor, Viewer)
3. **Permissions**: Specific actions (read, write, delete)
4. **Resources**: Objects being accessed

### RBAC Model

```
User → has → Roles → have → Permissions → on → Resources

Example:
john@example.com → [Admin, Editor] → [users:*, posts:*] → Users, Posts
```

### Implementation

```javascript
// Define roles and permissions
const roles = {
  admin: [
    'users:read',
    'users:write',
    'users:delete',
    'posts:read',
    'posts:write',
    'posts:delete',
    'settings:read',
    'settings:write'
  ],
  editor: [
    'posts:read',
    'posts:write',
    'posts:delete'
  ],
  viewer: [
    'posts:read'
  ]
};

// Middleware to check permission
function requirePermission(...requiredPermissions) {
  return async (req, res, next) => {
    // Get user roles
    const user = await db.users.findById(req.user.id);
    const userRoles = user.roles || [];

    // Get all permissions for user's roles
    const userPermissions = new Set();
    userRoles.forEach(role => {
      if (roles[role]) {
        roles[role].forEach(perm => userPermissions.add(perm));
      }
    });

    // Check if user has required permissions
    const hasPermission = requiredPermissions.every(perm =>
      userPermissions.has(perm) || userPermissions.has('*')
    );

    if (!hasPermission) {
      return res.status(403).json({
        error: {
          code: 'INSUFFICIENT_PERMISSIONS',
          message: 'You do not have permission to perform this action',
          required: requiredPermissions,
          provided: Array.from(userPermissions)
        }
      });
    }

    next();
  };
}

// Protected endpoints
app.get('/api/users',
  authenticateJWT,
  requirePermission('users:read'),
  async (req, res) => {
    const users = await db.users.find();
    res.json(users);
  }
);

app.delete('/api/users/:id',
  authenticateJWT,
  requirePermission('users:delete'),
  async (req, res) => {
    await db.users.delete(req.params.id);
    res.json({ message: 'User deleted' });
  }
);

app.post('/api/posts',
  authenticateJWT,
  requirePermission('posts:write'),
  async (req, res) => {
    const post = await db.posts.create(req.body);
    res.status(201).json(post);
  }
);
```

### Hierarchical Roles

```javascript
const roleHierarchy = {
  admin: {
    inherits: ['editor', 'viewer'],
    permissions: ['settings:*', 'users:*']
  },
  editor: {
    inherits: ['viewer'],
    permissions: ['posts:write', 'posts:delete']
  },
  viewer: {
    permissions: ['posts:read']
  }
};

function getRolePermissions(role) {
  const permissions = new Set(roleHierarchy[role].permissions);

  // Add inherited permissions
  const inherits = roleHierarchy[role].inherits || [];
  inherits.forEach(inheritedRole => {
    getRolePermissions(inheritedRole).forEach(perm =>
      permissions.add(perm)
    );
  });

  return Array.from(permissions);
}
```

### JWT with RBAC

Store roles in JWT claims:

```json
{
  "sub": "user123",
  "email": "john@example.com",
  "roles": ["admin", "editor"],
  "iat": 1705329600,
  "exp": 1705333200
}
```

### RBAC Best Practices

✅ Define roles based on job functions
✅ Keep number of roles manageable
✅ Regular role audits
✅ Implement least privilege principle
✅ Document role permissions clearly
✅ Use role hierarchies when appropriate
✅ Implement role mining for large organizations

### RBAC Advantages

✅ Simple to understand and implement
✅ Easy to manage for small to medium organizations
✅ Clear separation of duties
✅ Scalable for defined roles
✅ Widely supported
✅ Reduces administrative overhead

### RBAC Disadvantages

❌ Role explosion as organization grows
❌ Inflexible for dynamic scenarios
❌ Difficult to handle exceptions
❌ Can't easily handle context-based access
❌ May require many roles for complex scenarios

---

## ABAC (Attribute-Based Access Control)

Access decisions based on attributes of users, resources, actions, and environment.

### Attributes

1. **Subject Attributes**: User role, department, clearance level, location
2. **Resource Attributes**: Owner, classification, creation date, sensitivity
3. **Action Attributes**: Read, write, delete, approve, share
4. **Environment Attributes**: Current time, day of week, location, network

### ABAC Policy Example

```
Allow user to read document IF:
  - user.department == document.department
  AND user.clearanceLevel >= document.classificationLevel
  AND currentTime.withinBusinessHours
  AND user.location == "office"
```

### Implementation with Open Policy Agent (OPA)

**Policy (Rego)**:

```rego
package authz

# Allow read access to documents
allow {
  input.action == "read"
  input.resource.type == "document"

  # User in same department
  input.user.department == input.resource.department

  # User has sufficient clearance
  input.user.clearanceLevel >= input.resource.classificationLevel

  # Within business hours
  is_business_hours
}

is_business_hours {
  hour := time.clock(time.now_ns())[0]
  hour >= 9
  hour < 17
}

# Allow write access if user is owner
allow {
  input.action == "write"
  input.resource.owner == input.user.id
}

# Admins can do anything
allow {
  input.user.role == "admin"
}
```

**Integration**:

```javascript
const { OPA } = require('@open-policy-agent/opa-wasm');

let opa;

async function initOPA() {
  opa = await OPA.load('policy.wasm');
}

async function checkPermission(user, resource, action) {
  const input = {
    user: {
      id: user.id,
      department: user.department,
      clearanceLevel: user.clearanceLevel,
      role: user.role,
      location: user.location
    },
    resource: {
      type: resource.type,
      owner: resource.owner,
      department: resource.department,
      classificationLevel: resource.classificationLevel
    },
    action,
    environment: {
      time: new Date().toISOString()
    }
  };

  const result = await opa.evaluate(input, 'authz/allow');
  return result[0].result;
}

// Middleware
function requireABACPermission(action) {
  return async (req, res, next) => {
    const resource = await getResource(req);
    const allowed = await checkPermission(req.user, resource, action);

    if (!allowed) {
      return res.status(403).json({
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied by policy'
        }
      });
    }

    next();
  };
}

// Usage
app.get('/api/documents/:id',
  authenticateJWT,
  requireABACPermission('read'),
  async (req, res) => {
    const document = await db.documents.findById(req.params.id);
    res.json(document);
  }
);
```

### ABAC Advantages

✅ Highly flexible and granular
✅ Context-aware access decisions
✅ Fewer policies needed than RBAC roles
✅ Handles complex scenarios
✅ Dynamic policy evaluation
✅ Scalable for large organizations
✅ Supports compliance requirements

### ABAC Disadvantages

❌ More complex to implement
❌ Harder to understand and debug
❌ Performance overhead for policy evaluation
❌ Requires comprehensive attribute management
❌ Policy authoring can be complex
❌ Testing policies is challenging

### ABAC Use Cases

✅ Large organizations with complex access requirements
✅ Healthcare (HIPAA compliance)
✅ Finance (sensitive data access)
✅ Government (classified information)
✅ Multi-tenant applications
✅ Dynamic access requirements
✅ Compliance-heavy industries

---

## Scopes & Permissions

### OAuth 2.0 Scopes

```javascript
// Define scopes
const scopes = {
  'read:users': 'Read user information',
  'write:users': 'Create and update users',
  'delete:users': 'Delete users',
  'read:posts': 'Read posts',
  'write:posts': 'Create and update posts',
  'admin:all': 'Full administrative access'
};

// Scope middleware
function requireScopes(...requiredScopes) {
  return (req, res, next) => {
    const tokenScopes = req.token.scope.split(' ');

    const hasAllScopes = requiredScopes.every(scope =>
      tokenScopes.includes(scope)
    );

    if (!hasAllScopes) {
      return res.status(403).json({
        error: {
          code: 'INSUFFICIENT_SCOPE',
          message: 'Token lacks required scopes',
          required: requiredScopes,
          provided: tokenScopes
        }
      });
    }

    next();
  };
}

// Usage
app.get('/api/users',
  authenticateJWT,
  requireScopes('read:users'),
  async (req, res) => {
    // Return users
  }
);

app.delete('/api/users/:id',
  authenticateJWT,
  requireScopes('delete:users', 'admin:all'),  // Requires both scopes
  async (req, res) => {
    // Delete user
  }
);
```

### Hierarchical Scopes

```javascript
const scopeHierarchy = {
  'admin:all': ['read:*', 'write:*', 'delete:*'],
  'write:users': ['read:users'],
  'write:posts': ['read:posts']
};

function hasScope(userScopes, requiredScope) {
  // Check direct match
  if (userScopes.includes(requiredScope)) {
    return true;
  }

  // Check wildcard
  const [resource, action] = requiredScope.split(':');
  if (userScopes.includes(`${resource}:*`) || userScopes.includes('*:*')) {
    return true;
  }

  // Check hierarchy
  for (const scope of userScopes) {
    if (scopeHierarchy[scope]?.includes(requiredScope)) {
      return true;
    }
  }

  return false;
}
```

---

## Comparison & Best Practices

### Authentication Methods Comparison

| Method | Complexity | Stateless | Mobile-Friendly | Scalability | Security | Use Case |
|--------|------------|-----------|-----------------|-------------|----------|----------|
| **JWT** | Medium | Yes | Yes | High | Medium-High | Modern APIs, SPAs |
| **OAuth 2.0** | High | Yes | Yes | High | High | Third-party access |
| **API Keys** | Low | Yes | Yes | High | Medium | Server-to-server |
| **Sessions** | Low | No | Poor | Low | Medium | Traditional web apps |
| **Basic Auth** | Very Low | Yes | Yes | High | Low | Internal tools |

### Authorization Methods Comparison

| Method | Complexity | Flexibility | Scalability | Use Case |
|--------|------------|-------------|-------------|----------|
| **RBAC** | Low | Low | Medium | Small-medium orgs |
| **ABAC** | High | High | High | Large orgs, compliance |
| **Scopes** | Medium | Medium | High | API access control |

### Best Practices Summary

**Authentication**:
✅ Use HTTPS everywhere
✅ Implement rate limiting
✅ Hash sensitive data (passwords, API keys)
✅ Use secure session storage (Redis)
✅ Implement token refresh mechanism
✅ Log all authentication events
✅ Monitor for suspicious activity

**Authorization**:
✅ Implement least privilege principle
✅ Separate authentication from authorization
✅ Centralize authorization logic
✅ Log all authorization decisions
✅ Regular access reviews
✅ Fail-secure (deny by default)

**General Security**:
✅ Never store credentials in code
✅ Use environment variables for secrets
✅ Rotate secrets regularly
✅ Implement CSRF protection
✅ Validate all inputs
✅ Use security headers (CSP, HSTS, etc.)
✅ Regular security audits
✅ Keep dependencies updated

## Summary

Authentication and authorization are critical components of API security. Choose the right method based on your use case:

- **JWT**: Modern, stateless authentication for APIs
- **OAuth 2.0**: Third-party authorization and social login
- **API Keys**: Simple, server-to-server authentication
- **Sessions**: Traditional web application authentication
- **RBAC**: Simple, role-based authorization
- **ABAC**: Complex, attribute-based authorization
- **Scopes**: Fine-grained API access control

Always prioritize security, follow best practices, and regularly audit your authentication and authorization implementation.
