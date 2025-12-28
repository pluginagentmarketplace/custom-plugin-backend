---
name: security
description: Secure backend applications against OWASP threats. Implement authentication, encryption, scanning, compliance, and incident response procedures.
sasmp_version: "1.3.0"
bonded_agent: testing-security-agent
bond_type: PRIMARY_BOND
---

# Security Practices Skill

**Bonded to:** `testing-security-agent`

---

## Quick Start

```bash
# Example: Invoke security skill
"Audit my application for OWASP Top 10 vulnerabilities"
```

---

## Instructions

1. **Security Assessment**: Identify vulnerabilities and risks
2. **Implement Auth**: Add authentication and authorization
3. **Encrypt Data**: Protect data at rest and in transit
4. **Set Up Scanning**: Configure SAST, DAST, SCA
5. **Ensure Compliance**: Meet GDPR, HIPAA, PCI-DSS

---

## OWASP Top 10 Quick Reference

| # | Vulnerability | Prevention |
|---|---------------|------------|
| 1 | Broken Access Control | Enforce least privilege |
| 2 | Cryptographic Failures | Use strong encryption |
| 3 | Injection | Parameterized queries |
| 4 | Insecure Design | Threat modeling |
| 5 | Security Misconfiguration | Secure defaults |

---

## Examples

### Example 1: JWT Security
```
Input: "Implement secure JWT authentication"
Output: Short-lived tokens, refresh rotation, secure storage
```

### Example 2: Vulnerability Scan
```
Input: "Set up security scanning pipeline"
Output: Configure Snyk, SonarQube, Trivy in CI/CD
```

---

## References

See `references/` directory for detailed documentation.
