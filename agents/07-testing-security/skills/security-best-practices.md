# Security Best Practices for Backend Development

## Table of Contents
1. [Introduction to Application Security](#introduction-to-application-security)
2. [OWASP Top 10 (2025)](#owasp-top-10-2025)
3. [SQL Injection Prevention](#sql-injection-prevention)
4. [Authentication Best Practices](#authentication-best-practices)
5. [Authorization and Access Control](#authorization-and-access-control)
6. [Data Encryption](#data-encryption)
7. [Secure Coding Practices](#secure-coding-practices)
8. [Security Headers and Configuration](#security-headers-and-configuration)
9. [API Security](#api-security)
10. [Security Checklist](#security-checklist)

---

## Introduction to Application Security

### Why Security Matters

**Cost of Data Breaches (2024 Average)**:
- **Average total cost**: $4.45 million per breach
- **Per record cost**: $165
- **Time to identify**: 194 days
- **Time to contain**: 64 days

**Beyond Financial Cost**:
- Loss of customer trust
- Regulatory fines (GDPR: up to 4% of global revenue)
- Legal liabilities
- Brand reputation damage
- Business disruption

### Security Principles

#### CIA Triad
1. **Confidentiality**: Protect data from unauthorized access
2. **Integrity**: Ensure data hasn't been tampered with
3. **Availability**: Keep systems accessible to authorized users

#### Defense in Depth
Multiple layers of security controls:
```
┌─────────────────────────────────────┐
│   User Education & Awareness        │  Layer 7
├─────────────────────────────────────┤
│   Application Security              │  Layer 6
├─────────────────────────────────────┤
│   Data Security (Encryption)        │  Layer 5
├─────────────────────────────────────┤
│   Endpoint Security                 │  Layer 4
├─────────────────────────────────────┤
│   Network Security (Firewalls)      │  Layer 3
├─────────────────────────────────────┤
│   Physical Security                 │  Layer 2
├─────────────────────────────────────┤
│   Policies & Procedures             │  Layer 1
└─────────────────────────────────────┘
```

#### Principle of Least Privilege
- Grant minimum necessary permissions
- Default deny approach
- Time-limited access when possible
- Regular permission audits

---

## OWASP Top 10 (2025)

### 1. Broken Access Control

**Statistics**: 3.73% of applications tested have this vulnerability

**Description**: Failures in enforcing proper access restrictions allow users to act outside their intended permissions.

**Common Vulnerabilities**:
- URL manipulation to access other users' data
- Missing function-level access control
- Insecure direct object references (IDOR)
- API access control failures
- Elevation of privilege

**Example Vulnerability**:
```javascript
// Vulnerable Code - No authorization check
app.get('/api/users/:id', async (req, res) => {
  const user = await db.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
  res.json(user); // Anyone can access any user's data!
});
```

**Secure Implementation**:
```javascript
// Secure Code - Authorization check
app.get('/api/users/:id', authenticateToken, async (req, res) => {
  const requestedId = parseInt(req.params.id);
  const currentUserId = req.user.id;

  // Users can only access their own data
  if (requestedId !== currentUserId && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Access denied' });
  }

  const user = await db.query('SELECT * FROM users WHERE id = ?', [requestedId]);
  res.json(user);
});
```

**Prevention**:
```javascript
// Middleware for authorization
function authorize(allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
}

// Usage
app.delete('/api/users/:id',
  authenticateToken,
  authorize(['admin']),  // Only admins can delete users
  async (req, res) => {
    // Delete user logic
  }
);
```

### 2. Cryptographic Failures

**Description**: Failures related to cryptography leading to sensitive data exposure.

**Common Issues**:
- Transmitting data in clear text (HTTP instead of HTTPS)
- Using weak cryptographic algorithms (MD5, SHA1)
- Improper key management
- Not encrypting sensitive data at rest

**Vulnerable Code**:
```javascript
// BAD - Storing plain text password
const user = {
  email: 'user@example.com',
  password: 'MyPassword123' // NEVER DO THIS!
};
await db.insert('users', user);
```

**Secure Implementation**:
```javascript
// GOOD - Hashing password with bcrypt
const bcrypt = require('bcrypt');

async function createUser(userData) {
  const saltRounds = 12;
  const hashedPassword = await bcrypt.hash(userData.password, saltRounds);

  const user = {
    email: userData.email,
    password: hashedPassword
  };

  return await db.insert('users', user);
}

// Verifying password
async function verifyPassword(plainPassword, hashedPassword) {
  return await bcrypt.compare(plainPassword, hashedPassword);
}
```

**Encryption at Rest**:
```javascript
// Using crypto for sensitive data
const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';
const SECRET_KEY = process.env.ENCRYPTION_KEY; // 32-byte key from environment

function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, Buffer.from(SECRET_KEY), iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  const authTag = cipher.getAuthTag();

  return {
    iv: iv.toString('hex'),
    encryptedData: encrypted,
    authTag: authTag.toString('hex')
  };
}

function decrypt(encryptedObject) {
  const decipher = crypto.createDecipheriv(
    ALGORITHM,
    Buffer.from(SECRET_KEY),
    Buffer.from(encryptedObject.iv, 'hex')
  );

  decipher.setAuthTag(Buffer.from(encryptedObject.authTag, 'hex'));

  let decrypted = decipher.update(encryptedObject.encryptedData, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
}

// Usage for storing SSN
const ssn = '123-45-6789';
const encrypted = encrypt(ssn);
await db.query('UPDATE users SET ssn_encrypted = ? WHERE id = ?', [JSON.stringify(encrypted), userId]);
```

### 3. Injection

**Description**: Injection flaws occur when untrusted data is sent to an interpreter as part of a command or query.

**Types**:
- SQL Injection
- NoSQL Injection
- OS Command Injection
- LDAP Injection
- XML Injection

**Prevention**: See detailed SQL Injection Prevention section below.

### 7. Identification and Authentication Failures

**Common Weaknesses**:
- Weak password requirements
- Credential stuffing attacks
- Missing or ineffective multi-factor authentication
- Session fixation attacks
- Exposing session IDs in URLs

**Secure Password Policy**:
```javascript
function validatePassword(password) {
  const errors = [];

  if (password.length < 12) {
    errors.push('Password must be at least 12 characters');
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

  // Check against common passwords
  if (COMMON_PASSWORDS.includes(password.toLowerCase())) {
    errors.push('Password is too common');
  }

  return {
    valid: errors.length === 0,
    errors
  };
}
```

**Account Lockout**:
```javascript
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION = 15 * 60 * 1000; // 15 minutes

async function handleFailedLogin(email) {
  const user = await db.findUserByEmail(email);

  if (!user) return;

  user.failedAttempts = (user.failedAttempts || 0) + 1;
  user.lastFailedAttempt = new Date();

  if (user.failedAttempts >= MAX_FAILED_ATTEMPTS) {
    user.lockedUntil = new Date(Date.now() + LOCKOUT_DURATION);
  }

  await db.updateUser(user);
}

async function checkAccountLocked(email) {
  const user = await db.findUserByEmail(email);

  if (!user) return false;

  if (user.lockedUntil && user.lockedUntil > new Date()) {
    return true;
  }

  return false;
}

// On successful login
async function resetFailedAttempts(userId) {
  await db.query(
    'UPDATE users SET failed_attempts = 0, locked_until = NULL WHERE id = ?',
    [userId]
  );
}
```

### Other OWASP Top 10 Risks

4. **Insecure Design**: Lack of security design and architecture
5. **Security Misconfiguration**: Insecure default configurations, verbose error messages
6. **Vulnerable and Outdated Components**: Using libraries with known vulnerabilities
8. **Software and Data Integrity Failures**: Insecure CI/CD pipelines, unsigned updates
9. **Security Logging and Monitoring Failures**: Insufficient logging and monitoring
10. **Server-Side Request Forgery (SSRF)**: Application fetches remote resources without validating URLs

---

## SQL Injection Prevention

### What is SQL Injection?

**Example Attack**:
```javascript
// Vulnerable code
const email = req.body.email; // User input: ' OR '1'='1
const query = `SELECT * FROM users WHERE email = '${email}'`;
// Resulting query: SELECT * FROM users WHERE email = '' OR '1'='1'
// Returns ALL users!
```

### Prevention Method 1: Parameterized Queries (Recommended)

**Node.js (mysql2)**:
```javascript
// GOOD - Parameterized query
const mysql = require('mysql2/promise');

async function findUserByEmail(email) {
  const [rows] = await db.query(
    'SELECT * FROM users WHERE email = ?',
    [email] // Parameter is safely escaped
  );
  return rows[0];
}

// Multiple parameters
async function createUser(email, name, age) {
  const [result] = await db.query(
    'INSERT INTO users (email, name, age) VALUES (?, ?, ?)',
    [email, name, age]
  );
  return result.insertId;
}
```

**Python (psycopg2)**:
```python
import psycopg2

def find_user_by_email(email):
    conn = psycopg2.connect(DATABASE_URL)
    cursor = conn.cursor()

    # GOOD - Parameterized query
    cursor.execute(
        "SELECT * FROM users WHERE email = %s",
        (email,)  # Tuple of parameters
    )

    user = cursor.fetchone()
    cursor.close()
    conn.close()

    return user
```

**Java (JDBC)**:
```java
public User findUserByEmail(String email) throws SQLException {
    String sql = "SELECT * FROM users WHERE email = ?";

    try (PreparedStatement stmt = connection.prepareStatement(sql)) {
        stmt.setString(1, email);  // Parameter index starts at 1

        try (ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                return new User(
                    rs.getInt("id"),
                    rs.getString("email"),
                    rs.getString("name")
                );
            }
        }
    }

    return null;
}
```

### Prevention Method 2: ORM with Parameterization

**Sequelize (Node.js)**:
```javascript
const { Sequelize, Model, DataTypes } = require('sequelize');

// Define model
class User extends Model {}

User.init({
  email: DataTypes.STRING,
  name: DataTypes.STRING
}, { sequelize, modelName: 'user' });

// Safe queries
async function findUserByEmail(email) {
  // Sequelize automatically parameterizes
  return await User.findOne({
    where: { email: email }
  });
}

// Dynamic where clauses - still safe
async function searchUsers(searchTerm) {
  return await User.findAll({
    where: {
      name: {
        [Sequelize.Op.like]: `%${searchTerm}%` // Safely escaped
      }
    }
  });
}
```

**SQLAlchemy (Python)**:
```python
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    email = Column(String)
    name = Column(String)

engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)

def find_user_by_email(email):
    session = Session()
    # SQLAlchemy automatically parameterizes
    user = session.query(User).filter(User.email == email).first()
    session.close()
    return user
```

### Prevention Method 3: Stored Procedures (When Properly Parameterized)

```sql
-- Create stored procedure
CREATE PROCEDURE GetUserByEmail(IN email_param VARCHAR(255))
BEGIN
    SELECT * FROM users WHERE email = email_param;
END;
```

```javascript
// Call stored procedure
async function findUserByEmail(email) {
  const [rows] = await db.query('CALL GetUserByEmail(?)', [email]);
  return rows[0][0];
}
```

### Input Validation (Defense in Depth)

```javascript
function validateEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!emailRegex.test(email)) {
    throw new Error('Invalid email format');
  }

  if (email.length > 255) {
    throw new Error('Email too long');
  }

  return email.trim().toLowerCase();
}

// Use before database query
async function findUserByEmail(email) {
  const validEmail = validateEmail(email); // Validate first
  const [rows] = await db.query(
    'SELECT * FROM users WHERE email = ?',
    [validEmail]
  );
  return rows[0];
}
```

### NoSQL Injection Prevention

**MongoDB Injection Example**:
```javascript
// Vulnerable
const email = req.body.email; // Attacker sends: { "$ne": null }
const user = await db.collection('users').findOne({ email: email });
// Matches ANY user where email is not null!
```

**Secure Implementation**:
```javascript
// GOOD - Validate input type
function sanitizeMongoInput(input) {
  if (typeof input !== 'string') {
    throw new Error('Invalid input type');
  }
  return input;
}

const email = sanitizeMongoInput(req.body.email);
const user = await db.collection('users').findOne({ email: email });

// Or use Mongoose schema validation
const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    validate: {
      validator: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
      message: 'Invalid email format'
    }
  }
});
```

---

## Authentication Best Practices

### JWT (JSON Web Tokens)

**JWT Structure**:
```
header.payload.signature

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.  <- Header (algorithm, type)
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6I.  <- Payload (claims)
UpIYXRlIjoxNTE2MjM5MDIyfQ.               <- Signature
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Secure JWT Implementation**:

```javascript
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET; // Store in environment variable
const JWT_EXPIRES_IN = '15m'; // Short-lived access token
const REFRESH_TOKEN_EXPIRES_IN = '7d';

// Generate tokens
function generateTokens(user) {
  const accessToken = jwt.sign(
    {
      userId: user.id,
      email: user.email,
      role: user.role
    },
    JWT_SECRET,
    {
      expiresIn: JWT_EXPIRES_IN,
      algorithm: 'HS256',
      issuer: 'your-app-name',
      audience: 'your-app-users'
    }
  );

  const refreshToken = jwt.sign(
    { userId: user.id },
    process.env.REFRESH_TOKEN_SECRET,
    {
      expiresIn: REFRESH_TOKEN_EXPIRES_IN,
      algorithm: 'HS256'
    }
  );

  return { accessToken, refreshToken };
}

// Verify and decode token
function verifyToken(token) {
  try {
    const decoded = jwt.verify(token, JWT_SECRET, {
      algorithms: ['HS256'],
      issuer: 'your-app-name',
      audience: 'your-app-users'
    });
    return decoded;
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Token expired');
    }
    if (error.name === 'JsonWebTokenError') {
      throw new Error('Invalid token');
    }
    throw error;
  }
}

// Authentication middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const user = verifyToken(token);
    req.user = user;
    next();
  } catch (error) {
    return res.status(403).json({ error: error.message });
  }
}
```

**Token Refresh Flow**:
```javascript
// Store refresh tokens in database
const refreshTokenSchema = new mongoose.Schema({
  token: { type: String, required: true, unique: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  expiresAt: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now }
});

// Refresh endpoint
app.post('/api/auth/refresh', async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(401).json({ error: 'Refresh token required' });
  }

  try {
    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);

    // Check if refresh token exists in database
    const storedToken = await RefreshToken.findOne({ token: refreshToken });

    if (!storedToken) {
      return res.status(403).json({ error: 'Invalid refresh token' });
    }

    // Generate new access token
    const user = await User.findById(decoded.userId);
    const { accessToken } = generateTokens(user);

    res.json({ accessToken });
  } catch (error) {
    res.status(403).json({ error: 'Invalid or expired refresh token' });
  }
});

// Logout - invalidate refresh token
app.post('/api/auth/logout', authenticateToken, async (req, res) => {
  const { refreshToken } = req.body;

  await RefreshToken.deleteOne({ token: refreshToken });

  res.json({ message: 'Logged out successfully' });
});
```

### Password Hashing with Argon2 (Recommended 2025)

```javascript
const argon2 = require('argon2');

async function hashPassword(plainPassword) {
  try {
    // Argon2id is recommended (hybrid of Argon2i and Argon2d)
    const hash = await argon2.hash(plainPassword, {
      type: argon2.argon2id,
      memoryCost: 65536,  // 64 MB
      timeCost: 3,        // Number of iterations
      parallelism: 4      // Number of threads
    });
    return hash;
  } catch (error) {
    throw new Error('Password hashing failed');
  }
}

async function verifyPassword(plainPassword, hashedPassword) {
  try {
    return await argon2.verify(hashedPassword, plainPassword);
  } catch (error) {
    return false;
  }
}

// Usage in registration
app.post('/api/auth/register', async (req, res) => {
  const { email, password } = req.body;

  // Validate password strength
  const validation = validatePassword(password);
  if (!validation.valid) {
    return res.status(400).json({ errors: validation.errors });
  }

  // Hash password
  const hashedPassword = await hashPassword(password);

  // Create user
  const user = await User.create({
    email,
    password: hashedPassword
  });

  res.status(201).json({ id: user.id, email: user.email });
});

// Usage in login
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email });

  if (!user) {
    // Don't reveal whether user exists
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const isValid = await verifyPassword(password, user.password);

  if (!isValid) {
    await handleFailedLogin(email);
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const tokens = generateTokens(user);
  res.json(tokens);
});
```

### Multi-Factor Authentication (MFA)

**TOTP (Time-Based One-Time Password)**:

```javascript
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');

// Generate MFA secret for user
async function setupMFA(userId) {
  const secret = speakeasy.generateSecret({
    name: `YourApp (${userId})`,
    length: 32
  });

  // Generate QR code for user to scan
  const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

  // Store secret in database (encrypted!)
  await User.findByIdAndUpdate(userId, {
    mfaSecret: encrypt(secret.base32),
    mfaEnabled: false // User must verify first
  });

  return {
    secret: secret.base32,
    qrCode: qrCodeUrl
  };
}

// Verify MFA token
function verifyMFAToken(secret, token) {
  return speakeasy.totp.verify({
    secret: secret,
    encoding: 'base32',
    token: token,
    window: 1 // Allow 1 step before/after for clock skew
  });
}

// Login with MFA
app.post('/api/auth/login-mfa', async (req, res) => {
  const { email, password, mfaToken } = req.body;

  const user = await User.findOne({ email });

  if (!user || !(await verifyPassword(password, user.password))) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // Check if MFA is enabled
  if (user.mfaEnabled) {
    if (!mfaToken) {
      return res.status(403).json({ error: 'MFA token required' });
    }

    const decryptedSecret = decrypt(user.mfaSecret);
    const isValidMFA = verifyMFAToken(decryptedSecret, mfaToken);

    if (!isValidMFA) {
      return res.status(403).json({ error: 'Invalid MFA token' });
    }
  }

  const tokens = generateTokens(user);
  res.json(tokens);
});
```

### OAuth 2.0 / OpenID Connect

**Google OAuth Example**:

```javascript
const { OAuth2Client } = require('google-auth-library');

const client = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  process.env.GOOGLE_REDIRECT_URI
);

// Step 1: Redirect user to Google
app.get('/api/auth/google', (req, res) => {
  const url = client.generateAuthUrl({
    access_type: 'offline',
    scope: ['profile', 'email']
  });
  res.redirect(url);
});

// Step 2: Handle callback
app.get('/api/auth/google/callback', async (req, res) => {
  const { code } = req.query;

  try {
    // Exchange code for tokens
    const { tokens } = await client.getToken(code);
    client.setCredentials(tokens);

    // Verify ID token
    const ticket = await client.verifyIdToken({
      idToken: tokens.id_token,
      audience: process.env.GOOGLE_CLIENT_ID
    });

    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture } = payload;

    // Find or create user
    let user = await User.findOne({ googleId });

    if (!user) {
      user = await User.create({
        googleId,
        email,
        name,
        picture,
        authProvider: 'google'
      });
    }

    // Generate our own JWT
    const appTokens = generateTokens(user);

    res.json(appTokens);
  } catch (error) {
    res.status(401).json({ error: 'Google authentication failed' });
  }
});
```

---

## Authorization and Access Control

### Role-Based Access Control (RBAC)

**Define Roles and Permissions**:

```javascript
const PERMISSIONS = {
  // Users
  'users:read': 'Read user data',
  'users:write': 'Create/update users',
  'users:delete': 'Delete users',

  // Posts
  'posts:read': 'Read posts',
  'posts:write': 'Create/update posts',
  'posts:delete': 'Delete posts',

  // Admin
  'admin:access': 'Access admin panel',
  'admin:settings': 'Modify system settings'
};

const ROLES = {
  guest: [],
  user: ['users:read', 'posts:read', 'posts:write'],
  moderator: ['users:read', 'posts:read', 'posts:write', 'posts:delete'],
  admin: Object.keys(PERMISSIONS) // All permissions
};

// Check permission
function hasPermission(userRole, permission) {
  const rolePermissions = ROLES[userRole] || [];
  return rolePermissions.includes(permission);
}

// Authorization middleware
function requirePermission(permission) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (!hasPermission(req.user.role, permission)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
}

// Usage
app.delete('/api/users/:id',
  authenticateToken,
  requirePermission('users:delete'),
  async (req, res) => {
    // Only users with 'users:delete' permission can access
    await User.deleteOne({ _id: req.params.id });
    res.json({ message: 'User deleted' });
  }
);
```

### Resource-Level Authorization

**Check Ownership**:

```javascript
// Middleware to check resource ownership
async function checkResourceOwnership(req, res, next) {
  const resourceId = req.params.id;
  const userId = req.user.id;

  const resource = await Post.findById(resourceId);

  if (!resource) {
    return res.status(404).json({ error: 'Resource not found' });
  }

  // Allow if owner or admin
  if (resource.authorId.toString() !== userId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Access denied' });
  }

  req.resource = resource; // Attach to request for use in handler
  next();
}

// Usage
app.put('/api/posts/:id',
  authenticateToken,
  checkResourceOwnership,
  async (req, res) => {
    // User can only edit their own posts (or admin can edit any)
    const { title, content } = req.body;

    req.resource.title = title;
    req.resource.content = content;
    await req.resource.save();

    res.json(req.resource);
  }
);
```

### Attribute-Based Access Control (ABAC)

**Policy-Based Authorization**:

```javascript
// Define policies
const policies = {
  canEditPost: (user, post) => {
    // Owner can always edit
    if (post.authorId === user.id) return true;

    // Admins can edit any post
    if (user.role === 'admin') return true;

    // Moderators can edit flagged posts
    if (user.role === 'moderator' && post.flagged) return true;

    return false;
  },

  canDeletePost: (user, post) => {
    // Only owner or admin can delete
    return post.authorId === user.id || user.role === 'admin';
  },

  canViewPost: (user, post) => {
    // Published posts visible to all
    if (post.status === 'published') return true;

    // Drafts only visible to author
    if (post.status === 'draft' && post.authorId === user.id) return true;

    // Admins can see all
    if (user.role === 'admin') return true;

    return false;
  }
};

// Policy enforcement middleware
function enforcePolicy(policyName) {
  return async (req, res, next) => {
    const resource = await getResource(req); // Get resource being accessed

    if (!policies[policyName](req.user, resource)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    req.resource = resource;
    next();
  };
}

// Usage
app.put('/api/posts/:id',
  authenticateToken,
  enforcePolicy('canEditPost'),
  async (req, res) => {
    // Update post logic
  }
);
```

---

## Data Encryption

### Encryption at Rest

**Database Column Encryption**:

```javascript
const crypto = require('crypto');

const ENCRYPTION_KEY = Buffer.from(process.env.ENCRYPTION_KEY, 'hex'); // 32 bytes
const ALGORITHM = 'aes-256-gcm';

class EncryptionService {
  static encrypt(plaintext) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);

    let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
    ciphertext += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return JSON.stringify({
      iv: iv.toString('hex'),
      ciphertext,
      authTag: authTag.toString('hex')
    });
  }

  static decrypt(encryptedData) {
    const { iv, ciphertext, authTag } = JSON.parse(encryptedData);

    const decipher = crypto.createDecipheriv(
      ALGORITHM,
      ENCRYPTION_KEY,
      Buffer.from(iv, 'hex')
    );

    decipher.setAuthTag(Buffer.from(authTag, 'hex'));

    let plaintext = decipher.update(ciphertext, 'hex', 'utf8');
    plaintext += decipher.final('utf8');

    return plaintext;
  }
}

// Mongoose virtual field for encryption
const userSchema = new mongoose.Schema({
  email: String,
  _ssn: String, // Stored encrypted
});

// Virtual field for SSN
userSchema.virtual('ssn')
  .get(function() {
    return this._ssn ? EncryptionService.decrypt(this._ssn) : null;
  })
  .set(function(value) {
    this._ssn = EncryptionService.encrypt(value);
  });

// Usage
const user = new User({ email: 'user@example.com' });
user.ssn = '123-45-6789'; // Automatically encrypted
await user.save();

// Reading
const foundUser = await User.findById(userId);
console.log(foundUser.ssn); // Automatically decrypted: '123-45-6789'
```

### Encryption in Transit

**Force HTTPS**:

```javascript
// Express middleware to redirect HTTP to HTTPS
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https' && process.env.NODE_ENV === 'production') {
    res.redirect(`https://${req.header('host')}${req.url}`);
  } else {
    next();
  }
});

// HSTS (HTTP Strict Transport Security)
const helmet = require('helmet');

app.use(helmet.hsts({
  maxAge: 31536000, // 1 year
  includeSubDomains: true,
  preload: true
}));
```

**TLS Configuration (Node.js)**:

```javascript
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('private-key.pem'),
  cert: fs.readFileSync('certificate.pem'),
  ca: fs.readFileSync('ca-certificate.pem'),

  // TLS 1.3 only
  minVersion: 'TLSv1.3',

  // Strong ciphers
  ciphers: [
    'TLS_AES_256_GCM_SHA384',
    'TLS_CHACHA20_POLY1305_SHA256',
    'TLS_AES_128_GCM_SHA256'
  ].join(':')
};

https.createServer(options, app).listen(443);
```

### Secret Management

**Using HashiCorp Vault**:

```javascript
const vault = require('node-vault')({
  endpoint: process.env.VAULT_ADDR,
  token: process.env.VAULT_TOKEN
});

async function getSecret(path) {
  try {
    const result = await vault.read(path);
    return result.data;
  } catch (error) {
    throw new Error(`Failed to retrieve secret: ${error.message}`);
  }
}

// Usage
const dbCredentials = await getSecret('secret/database/credentials');
const dbConnection = createConnection({
  host: dbCredentials.host,
  user: dbCredentials.username,
  password: dbCredentials.password
});
```

**Using AWS Secrets Manager**:

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager({ region: 'us-east-1' });

async function getAWSSecret(secretName) {
  try {
    const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();

    if ('SecretString' in data) {
      return JSON.parse(data.SecretString);
    }
  } catch (error) {
    throw new Error(`Failed to retrieve secret: ${error.message}`);
  }
}

// Usage
const apiKeys = await getAWSSecret('prod/api-keys');
```

---

## Secure Coding Practices

### Input Validation

**Comprehensive Validation**:

```javascript
const { body, param, query, validationResult } = require('express-validator');

// Validation rules
const userValidationRules = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .trim()
    .isLength({ max: 255 }),

  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('Name must contain only letters and spaces'),

  body('age')
    .optional()
    .isInt({ min: 18, max: 120 })
    .toInt(),

  body('website')
    .optional()
    .isURL({ protocols: ['http', 'https'], require_protocol: true })
];

// Validation error handler
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  next();
}

// Usage
app.post('/api/users',
  userValidationRules,
  handleValidationErrors,
  async (req, res) => {
    // req.body is now validated and sanitized
    const user = await User.create(req.body);
    res.status(201).json(user);
  }
);
```

### Output Encoding (XSS Prevention)

**Sanitize HTML Output**:

```javascript
const DOMPurify = require('isomorphic-dompurify');

function sanitizeHTML(dirty) {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
    ALLOWED_ATTR: ['href']
  });
}

// Usage when storing user-generated HTML
app.post('/api/posts', authenticateToken, async (req, res) => {
  const { title, content } = req.body;

  const post = await Post.create({
    title: sanitizeHTML(title),
    content: sanitizeHTML(content),
    authorId: req.user.id
  });

  res.status(201).json(post);
});
```

### CSRF Protection

```javascript
const csrf = require('csurf');
const cookieParser = require('cookie-parser');

app.use(cookieParser());

const csrfProtection = csrf({
  cookie: {
    httpOnly: true,
    secure: true, // HTTPS only
    sameSite: 'strict'
  }
});

// Get CSRF token
app.get('/api/csrf-token', csrfProtection, (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Protected routes
app.post('/api/posts',
  csrfProtection,
  authenticateToken,
  async (req, res) => {
    // CSRF token verified automatically
    // Process request
  }
);
```

### Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

// General API rate limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Max 100 requests per window
  message: 'Too many requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false
});

// Stricter limit for authentication
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // Max 5 login attempts
  skipSuccessfulRequests: true
});

app.use('/api/', apiLimiter);
app.use('/api/auth/login', authLimiter);

// Per-user rate limiting
const userLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: async (req) => {
    // Different limits based on user tier
    if (req.user && req.user.tier === 'premium') {
      return 1000;
    }
    return 100;
  },
  keyGenerator: (req) => req.user ? req.user.id : req.ip
});
```

### Error Handling (Without Info Disclosure)

```javascript
// Custom error class
class AppError extends Error {
  constructor(message, statusCode, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
  }
}

// Global error handler
app.use((err, req, res, next) => {
  // Log full error internally
  console.error({
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    user: req.user?.id,
    timestamp: new Date().toISOString()
  });

  // Send safe error to client
  if (process.env.NODE_ENV === 'production') {
    // Don't expose internal errors to users
    if (!err.isOperational) {
      return res.status(500).json({
        error: 'Internal server error'
      });
    }

    res.status(err.statusCode || 500).json({
      error: err.message
    });
  } else {
    // Development: send full error
    res.status(err.statusCode || 500).json({
      error: err.message,
      stack: err.stack
    });
  }
});

// Usage
app.get('/api/users/:id', async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    res.json(user);
  } catch (error) {
    next(error);
  }
});
```

---

## Security Headers and Configuration

### Helmet.js (Express)

```javascript
const helmet = require('helmet');

app.use(helmet({
  // Content Security Policy
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },

  // HTTP Strict Transport Security
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },

  // X-Frame-Options
  frameguard: {
    action: 'deny'
  },

  // X-Content-Type-Options
  noSniff: true,

  // Referrer-Policy
  referrerPolicy: {
    policy: 'strict-origin-when-cross-origin'
  },

  // Permissions-Policy
  permissionsPolicy: {
    features: {
      geolocation: ["'self'"],
      microphone: ["'none'"],
      camera: ["'none'"],
    }
  }
}));
```

### CORS Configuration

```javascript
const cors = require('cors');

const corsOptions = {
  origin: (origin, callback) => {
    const allowedOrigins = [
      'https://yourdomain.com',
      'https://app.yourdomain.com'
    ];

    // Allow requests with no origin (mobile apps, Postman)
    if (!origin) return callback(null, true);

    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true, // Allow cookies
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400 // Cache preflight for 24 hours
};

app.use(cors(corsOptions));
```

---

## API Security

### API Key Management

```javascript
// Generate API key
function generateAPIKey() {
  return crypto.randomBytes(32).toString('hex');
}

// Store hashed API key
async function createAPIKey(userId) {
  const apiKey = generateAPIKey();
  const hashedKey = await bcrypt.hash(apiKey, 12);

  await APIKey.create({
    userId,
    keyHash: hashedKey,
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year
  });

  // Return plain key only once
  return apiKey;
}

// Verify API key
async function verifyAPIKey(apiKey) {
  const keys = await APIKey.find();

  for (const key of keys) {
    const isMatch = await bcrypt.compare(apiKey, key.keyHash);

    if (isMatch && key.expiresAt > new Date()) {
      return key;
    }
  }

  return null;
}

// API key authentication middleware
async function authenticateAPIKey(req, res, next) {
  const apiKey = req.header('X-API-Key');

  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }

  const key = await verifyAPIKey(apiKey);

  if (!key) {
    return res.status(403).json({ error: 'Invalid or expired API key' });
  }

  req.apiKey = key;
  req.user = await User.findById(key.userId);

  next();
}
```

### Request Signing (HMAC)

```javascript
const crypto = require('crypto');

// Generate signature
function generateSignature(payload, secret) {
  return crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
}

// Verify signature
function verifySignature(payload, signature, secret) {
  const expectedSignature = generateSignature(payload, secret);

  // Constant-time comparison to prevent timing attacks
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// Middleware
function verifyRequestSignature(req, res, next) {
  const signature = req.header('X-Signature');
  const timestamp = req.header('X-Timestamp');

  // Prevent replay attacks (5 minute window)
  const now = Date.now();
  const requestTime = parseInt(timestamp);

  if (Math.abs(now - requestTime) > 5 * 60 * 1000) {
    return res.status(401).json({ error: 'Request expired' });
  }

  const payload = {
    method: req.method,
    path: req.path,
    body: req.body,
    timestamp
  };

  const secret = process.env.HMAC_SECRET;

  if (!verifySignature(payload, signature, secret)) {
    return res.status(403).json({ error: 'Invalid signature' });
  }

  next();
}
```

---

## Security Checklist

### Authentication & Authorization
- [ ] Passwords hashed with Argon2 or bcrypt (12+ rounds)
- [ ] Password policy enforced (12+ characters, complexity)
- [ ] Account lockout after failed login attempts
- [ ] MFA available for sensitive operations
- [ ] JWT tokens have short expiration (15 min access, 7 day refresh)
- [ ] Refresh tokens stored securely and revocable
- [ ] Session tokens are cryptographically random
- [ ] Authorization checked on every request
- [ ] Resource ownership verified
- [ ] Role-based access control implemented

### Input Validation & Output Encoding
- [ ] All user input validated and sanitized
- [ ] Parameterized queries used for database
- [ ] ORM used correctly (no raw queries with user input)
- [ ] HTML output sanitized to prevent XSS
- [ ] File uploads restricted by type and size
- [ ] User-provided URLs validated

### Encryption
- [ ] All sensitive data encrypted at rest (AES-256)
- [ ] HTTPS enforced everywhere (TLS 1.3)
- [ ] Secrets never in code or version control
- [ ] Environment variables or secret manager used
- [ ] Database connections encrypted
- [ ] HSTS header enabled

### API Security
- [ ] Rate limiting implemented
- [ ] CORS configured properly
- [ ] CSRF protection for state-changing operations
- [ ] API versioning implemented
- [ ] API keys rotated regularly
- [ ] Request/response logging (without sensitive data)

### Headers & Configuration
- [ ] Security headers configured (CSP, X-Frame-Options, etc.)
- [ ] Error messages don't expose system details
- [ ] Debug mode disabled in production
- [ ] Default credentials changed
- [ ] Unnecessary services disabled
- [ ] Directory listing disabled

### Monitoring & Logging
- [ ] Authentication failures logged
- [ ] Authorization failures logged
- [ ] Security events monitored and alerted
- [ ] Logs don't contain sensitive data (passwords, tokens)
- [ ] Log aggregation and analysis in place

### Dependencies & Updates
- [ ] Dependencies scanned for vulnerabilities
- [ ] Regular security updates applied
- [ ] Dependency versions pinned
- [ ] Software bill of materials (SBOM) maintained

### Compliance
- [ ] GDPR compliance (if applicable)
- [ ] HIPAA compliance (if applicable)
- [ ] PCI-DSS compliance (if applicable)
- [ ] Data retention policies implemented
- [ ] Incident response plan documented

---

## Recommended Resources

### Standards & Frameworks
- [OWASP Top 10](https://owasp.org/Top10/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### Tools
- **SAST**: SonarQube, Semgrep, CodeQL
- **DAST**: OWASP ZAP, Burp Suite
- **Dependency**: Snyk, npm audit, Dependabot

### Learning
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [HackTheBox](https://hackthebox.com)
- [TryHackMe](https://tryhackme.com)

---

## Summary

Security is not a feature—it's a fundamental requirement. By following these best practices and staying informed about emerging threats, you can build applications that protect your users and your business.

**Remember**:
1. **Never trust user input** - Validate and sanitize everything
2. **Defense in depth** - Multiple layers of security
3. **Principle of least privilege** - Minimal necessary access
4. **Secure by default** - Security is not optional
5. **Stay updated** - Security is an ongoing process

Stay secure! 🔒
