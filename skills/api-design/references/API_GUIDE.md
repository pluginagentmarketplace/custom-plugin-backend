# API Design Best Practices

## REST API Conventions

### HTTP Methods
| Method | Purpose | Idempotent |
|--------|---------|------------|
| GET | Retrieve resource | Yes |
| POST | Create resource | No |
| PUT | Replace resource | Yes |
| PATCH | Update resource | No |
| DELETE | Remove resource | Yes |

### Status Codes
| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful GET/PUT/PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Missing/invalid auth |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Server Error | Internal error |

## Authentication Patterns

### JWT Best Practices
1. Short access token lifetime (15-30 min)
2. Longer refresh token lifetime (7-30 days)
3. Store refresh token securely (httpOnly cookie)
4. Rotate refresh tokens on use
5. Implement token blacklisting for logout

## Rate Limiting

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```
