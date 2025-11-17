# Security Scanning & Compliance

## Table of Contents
1. [Introduction to Security Scanning](#introduction-to-security-scanning)
2. [Static Application Security Testing (SAST)](#static-application-security-testing-sast)
3. [Dynamic Application Security Testing (DAST)](#dynamic-application-security-testing-dast)
4. [Software Composition Analysis (SCA)](#software-composition-analysis-sca)
5. [Container Security Scanning](#container-security-scanning)
6. [Infrastructure as Code (IaC) Scanning](#infrastructure-as-code-iac-scanning)
7. [Compliance Frameworks](#compliance-frameworks)
8. [Vulnerability Management](#vulnerability-management)
9. [Security Automation in CI/CD](#security-automation-in-cicd)

---

## Introduction to Security Scanning

### Security Testing Types

```
┌──────────────────────────────────────────────────────────┐
│               Security Testing Spectrum                   │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  SAST          SCA         IAST         DAST      PenTest│
│  (Static) → (Dependencies) → (Runtime) → (Dynamic) → (Manual)│
│                                                           │
│  Code      Open Source   Execution    Running    Real     │
│  Analysis  Scanning      Analysis     App       Attacks   │
│                                                           │
│  ←────────── Shift Left ──────────  Shift Right ────→    │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### When to Use Each Type

| Type | When | What It Finds | Speed | Accuracy |
|------|------|---------------|-------|----------|
| **SAST** | Pre-commit, Build | Code vulnerabilities, logic flaws | Fast | Medium (false positives) |
| **SCA** | Build, PR | Vulnerable dependencies | Fast | High |
| **IAST** | Testing | Runtime vulnerabilities | Medium | High |
| **DAST** | Staging, Production | Running app vulnerabilities | Slow | High |
| **Container** | Build, Registry | Image vulnerabilities | Fast | High |
| **IaC** | Pre-commit, Build | Infrastructure misconfigurations | Fast | High |

---

## Static Application Security Testing (SAST)

### What is SAST?

**Definition**: White-box testing that analyzes source code, bytecode, or binaries for security vulnerabilities without executing the application.

**Benefits**:
- ✅ Find vulnerabilities early (during development)
- ✅ No need for running application
- ✅ Complete code coverage
- ✅ Identify root cause in code

**Limitations**:
- ❌ False positives
- ❌ Can't detect runtime issues
- ❌ May miss business logic flaws
- ❌ Language/framework specific

### SAST Tools

#### SonarQube (Popular Open Source)

**Installation (Docker)**:
```bash
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest
```

**Configuration (sonar-project.properties)**:
```properties
sonar.projectKey=my-backend-api
sonar.projectName=My Backend API
sonar.projectVersion=1.0
sonar.sources=src
sonar.exclusions=**/node_modules/**,**/*.test.js
sonar.tests=tests
sonar.test.inclusions=**/*.test.js

# Language
sonar.language=js

# Code Coverage
sonar.javascript.lcov.reportPaths=coverage/lcov.info

# Security
sonar.security.hotspots.enable=true
```

**CI/CD Integration (GitHub Actions)**:
```yaml
name: SonarQube Scan

on:
  push:
    branches: [main, develop]
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  sonarqube:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for better analysis

      - name: Install dependencies
        run: npm ci

      - name: Run tests with coverage
        run: npm test -- --coverage

      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}

      - name: SonarQube Quality Gate
        uses: SonarSource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

#### Semgrep (Fast, Developer-Friendly)

**Installation**:
```bash
pip install semgrep
```

**Configuration (.semgrep.yml)**:
```yaml
rules:
  - id: sql-injection
    pattern: |
      db.query($SQL, ...)
    message: Potential SQL injection vulnerability
    severity: ERROR
    languages: [javascript]

  - id: hardcoded-secret
    patterns:
      - pattern-regex: (password|secret|api_key)\s*=\s*['"][^'"]+['"]
    message: Hardcoded secret detected
    severity: WARNING
    languages: [javascript, python, java]

  - id: jwt-no-verify
    pattern: jwt.decode($TOKEN, verify=False, ...)
    message: JWT signature verification disabled
    severity: ERROR
    languages: [python]

  - id: unsafe-eval
    pattern: eval(...)
    message: Use of eval() is dangerous
    severity: WARNING
    languages: [javascript]
```

**Run Semgrep**:
```bash
# Scan with default rules
semgrep --config=auto .

# Scan with custom rules
semgrep --config=.semgrep.yml .

# Scan with OWASP Top 10 rules
semgrep --config=p/owasp-top-ten .

# Output as JSON
semgrep --config=auto --json --output=semgrep-results.json .
```

**CI/CD Integration**:
```yaml
- name: Semgrep Scan
  uses: returntocorp/semgrep-action@v1
  with:
    config: >-
      p/security-audit
      p/owasp-top-ten
      p/jwt
```

#### CodeQL (GitHub)

**Configuration (.github/workflows/codeql.yml)**:
```yaml
name: CodeQL Analysis

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 0'  # Weekly scan

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write

    strategy:
      matrix:
        language: ['javascript', 'python']

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v2
        with:
          languages: ${{ matrix.language }}
          queries: security-extended,security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@v2

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v2
```

### SAST Best Practices

**1. Run Early and Often**:
```yaml
# Run on every commit
on: [push, pull_request]

# Also schedule regular scans
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
```

**2. Set Quality Gates**:
```javascript
// sonar-quality-gate.js
const sonarQubeConfig = {
  qualityGate: {
    metrics: {
      'security_rating': { threshold: 'A', operator: 'GT' },
      'security_hotspots_reviewed': { threshold: 100, operator: 'LT' },
      'vulnerabilities': { threshold: 0, operator: 'GT' },
      'bugs': { threshold: 0, operator: 'GT' },
      'code_smells': { threshold: 10, operator: 'GT' }
    }
  }
};
```

**3. Suppress False Positives**:
```javascript
// Inline suppression for false positives
function getUserData(userId) {
  // NOSONAR - userId is validated by middleware
  const query = `SELECT * FROM users WHERE id = ${userId}`;
  return db.query(query);
}

// Or use semgrep nosemgrep comment
function safeDecode(token) {
  // nosemgrep: jwt-no-verify
  // This is a public token, verification not needed
  return jwt.decode(token, { verify: false });
}
```

**4. Prioritize Findings**:
- **Critical/High**: Fix immediately, block deployment
- **Medium**: Fix within sprint, create tickets
- **Low/Info**: Review and address in maintenance cycles

---

## Dynamic Application Security Testing (DAST)

### What is DAST?

**Definition**: Black-box testing that attacks a running application from the outside to identify vulnerabilities.

**Benefits**:
- ✅ Finds runtime vulnerabilities
- ✅ No source code needed
- ✅ Tests actual running environment
- ✅ Low false positive rate

**Limitations**:
- ❌ Requires running application
- ❌ Slower than SAST
- ❌ Can't pinpoint exact code location
- ❌ Limited code coverage

### OWASP ZAP (Zed Attack Proxy)

**Docker Setup**:
```bash
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://api.example.com \
  -r zap-report.html
```

**CI/CD Integration (Full Scan)**:
```yaml
name: DAST Scan

on:
  schedule:
    - cron: '0 3 * * *'  # Daily at 3 AM
  workflow_dispatch:  # Manual trigger

jobs:
  dast:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Deploy to staging
        run: |
          # Deploy application to staging environment
          ./scripts/deploy-staging.sh

      - name: Wait for deployment
        run: sleep 30

      - name: OWASP ZAP Full Scan
        uses: zaproxy/action-full-scan@v0.4.0
        with:
          target: 'https://staging.api.example.com'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: Upload ZAP Report
        uses: actions/upload-artifact@v3
        with:
          name: zap-report
          path: report_html.html
```

**ZAP Configuration (.zap/rules.tsv)**:
```
# Rule ID    Threshold    Ignore
10021        FAIL         # X-Content-Type-Options Missing
10023        FAIL         # CSP Missing
10038        FAIL         # SSL/TLS Misconfiguration
10202        IGNORE       # False positive for specific endpoint
```

**API Scanning with ZAP**:
```yaml
- name: OWASP ZAP API Scan
  run: |
    docker run -v $(pwd):/zap/wrk/:rw \
      -t owasp/zap2docker-stable \
      zap-api-scan.py \
      -t /zap/wrk/openapi.yaml \
      -f openapi \
      -r /zap/wrk/zap-api-report.html
```

### Burp Suite (Commercial)

**Burp Suite CI/CD Integration**:
```bash
# Using Burp Suite Enterprise
curl -X POST https://burp.example.com/api/v1/scan \
  -H "Authorization: Bearer $BURP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "scan_configurations": [{
      "name": "API Security Audit",
      "type": "NamedConfiguration"
    }],
    "urls": ["https://api.example.com"],
    "scan_callback": {
      "url": "https://ci.example.com/webhook/burp"
    }
  }'
```

### DAST Best Practices

**1. Schedule Regular Scans**:
```yaml
# Full scans nightly or weekly (slow)
on:
  schedule:
    - cron: '0 2 * * 0'  # Sunday at 2 AM

# Quick baseline scans on deployments
on:
  deployment:
    environments: [staging]
```

**2. Use Authenticated Scanning**:
```yaml
- name: ZAP Authenticated Scan
  env:
    ZAP_AUTH_HEADER: "Authorization: Bearer ${{ secrets.STAGING_TOKEN }}"
  run: |
    docker run -t owasp/zap2docker-stable \
      zap-full-scan.py \
      -t https://api.example.com \
      -z "-config replacer.full_list(0).description=auth1 \
          -config replacer.full_list(0).enabled=true \
          -config replacer.full_list(0).matchtype=REQ_HEADER \
          -config replacer.full_list(0).matchstr=Authorization \
          -config replacer.full_list(0).replacement=$ZAP_AUTH_HEADER"
```

**3. Scan Staging, Not Production** (unless necessary):
- Lower risk of disruption
- Safe to test aggressive scans
- Can use test data

---

## Software Composition Analysis (SCA)

### What is SCA?

**Definition**: Scanning third-party dependencies and open-source components for known vulnerabilities and license issues.

**Why Important**:
- 80%+ of code in modern apps is from dependencies
- Supply chain attacks increasing (e.g., event-stream, ua-parser-js)
- Legal risks from incompatible licenses

### Snyk (Popular SCA Tool)

**Installation**:
```bash
npm install -g snyk

# Authenticate
snyk auth
```

**Scan for Vulnerabilities**:
```bash
# Test current project
snyk test

# Test and show upgrade path
snyk test --print-deps

# Test Docker image
snyk container test node:18

# Test Infrastructure as Code
snyk iac test terraform/
```

**Fix Vulnerabilities**:
```bash
# Automatic fix (updates package.json)
snyk fix

# Create PRs for fixes
snyk fix --pr
```

**CI/CD Integration**:
```yaml
name: Snyk Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high --fail-on=upgradable

      - name: Upload result to GitHub Code Scanning
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: snyk.sarif
```

**Snyk Configuration (.snyk)**:
```yaml
# Snyk (https://snyk.io) policy file, patches or ignores known vulnerabilities.
version: v1.22.1

# Ignore specific vulnerabilities
ignore:
  SNYK-JS-LODASH-567746:
    - '*':
        reason: False positive - not using affected function
        expires: 2025-12-31T00:00:00.000Z

# Patch specific vulnerabilities
patch:
  'npm:ms:20170412':
    - connect > finalhandler > debug > ms:
        patched: '2024-01-15T10:00:00.000Z'
```

### npm audit (Built-in for Node.js)

**Run Audit**:
```bash
# Check for vulnerabilities
npm audit

# Show detailed report
npm audit --json

# Fix automatically (may have breaking changes!)
npm audit fix

# Fix only production dependencies
npm audit fix --only=prod

# Force fix (may install breaking changes)
npm audit fix --force
```

**CI/CD Integration**:
```yaml
- name: Security Audit
  run: |
    npm audit --audit-level=high
    # Fail if high or critical vulnerabilities found
```

**package.json scripts**:
```json
{
  "scripts": {
    "audit": "npm audit --audit-level=moderate",
    "audit:fix": "npm audit fix",
    "precommit": "npm audit --audit-level=high"
  }
}
```

### Dependabot (GitHub)

**Configuration (.github/dependabot.yml)**:
```yaml
version: 2
updates:
  # Enable version updates for npm
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"
    # Group updates
    groups:
      dev-dependencies:
        dependency-type: "development"
      production-dependencies:
        dependency-type: "production"

  # Security updates only (faster)
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 5
    labels:
      - "security"
      - "critical"
    # Only security updates
    versioning-strategy: increase-if-necessary
```

### OWASP Dependency-Check

**Maven Integration**:
```xml
<plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>8.4.0</version>
    <configuration>
        <failBuildOnCVSS>7</failBuildOnCVSS>
        <suppressionFile>dependency-check-suppressions.xml</suppressionFile>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>check</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

**Gradle Integration**:
```groovy
plugins {
    id 'org.owasp.dependencycheck' version '8.4.0'
}

dependencyCheck {
    failBuildOnCVSS = 7
    suppressionFile = 'dependency-check-suppressions.xml'
}
```

### SCA Best Practices

**1. Automate Dependency Updates**:
```yaml
# Auto-merge low-risk updates
- name: Auto-merge Dependabot PRs
  if: github.actor == 'dependabot[bot]'
  run: gh pr merge --auto --squash "$PR_URL"
  env:
    PR_URL: ${{github.event.pull_request.html_url}}
    GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
```

**2. Pin Dependencies**:
```json
// package.json - Pin exact versions
{
  "dependencies": {
    "express": "4.18.2",      // Not "^4.18.2"
    "mongoose": "7.6.3"       // Not "~7.6.3"
  }
}
```

**3. Use Lock Files**:
```bash
# Commit lock files to version control
git add package-lock.json
git add yarn.lock
git add Gemfile.lock
git add requirements.txt
```

**4. Regular Audits**:
```yaml
# Weekly automated security audit
on:
  schedule:
    - cron: '0 9 * * 1'  # Monday 9 AM

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm audit
      - run: snyk test
```

**5. Software Bill of Materials (SBOM)**:
```bash
# Generate SBOM
npx @cyclonedx/cyclonedx-npm --output-file sbom.json

# CycloneDX format (industry standard)
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "components": [
    {
      "type": "library",
      "name": "express",
      "version": "4.18.2",
      "licenses": [{ "license": { "id": "MIT" } }],
      "purl": "pkg:npm/express@4.18.2"
    }
  ]
}
```

---

## Container Security Scanning

### What is Container Scanning?

**Scanning Targets**:
- Base image vulnerabilities
- Installed packages
- Application dependencies
- Configuration issues
- Secrets in images

### Trivy (Fast, Comprehensive)

**Installation**:
```bash
# Install Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

**Scan Container Image**:
```bash
# Scan image
trivy image node:18

# Scan with severity filter
trivy image --severity HIGH,CRITICAL node:18

# Scan and fail on vulnerabilities
trivy image --exit-code 1 --severity CRITICAL myapp:latest

# Output as JSON
trivy image --format json --output results.json myapp:latest

# Scan filesystem
trivy fs .

# Scan Kubernetes manifests
trivy config kubernetes/
```

**CI/CD Integration**:
```yaml
name: Container Security Scan

on:
  push:
    branches: [main]
  pull_request:

jobs:
  scan:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

**Trivy Configuration (.trivyignore)**:
```
# Ignore specific CVEs
CVE-2023-12345  # False positive in base image
CVE-2023-67890  # Fix not available, mitigated by network policy
```

### Docker Scout

**Scan with Docker Scout**:
```bash
# Enable Docker Scout
docker scout quickview

# Analyze image
docker scout cves myapp:latest

# Compare with base image
docker scout compare --to node:18 myapp:latest

# Get recommendations
docker scout recommendations myapp:latest
```

### Best Practices for Secure Containers

**1. Use Minimal Base Images**:
```dockerfile
# BAD - Full OS image (1 GB+)
FROM ubuntu:22.04

# GOOD - Minimal image (5-50 MB)
FROM node:18-alpine

# BETTER - Distroless (even smaller, no shell)
FROM gcr.io/distroless/nodejs18-debian11
```

**2. Multi-Stage Builds**:
```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app

# Copy only necessary files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./

# Non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**3. Scan in CI/CD**:
```yaml
- name: Build and scan
  run: |
    docker build -t myapp:latest .
    trivy image --exit-code 1 --severity CRITICAL myapp:latest
```

**4. Use .dockerignore**:
```
# .dockerignore
node_modules
npm-debug.log
.env
.env.local
.git
.github
*.md
tests/
coverage/
.vscode/
```

**5. Don't Hardcode Secrets**:
```dockerfile
# BAD - Secret in image
ENV API_KEY=sk_live_abc123

# GOOD - Use build args or runtime env
ARG API_KEY_ARG
ENV API_KEY=${API_KEY_ARG}

# BETTER - Use secrets management
# Pass at runtime: docker run -e API_KEY=$API_KEY myapp
```

---

## Infrastructure as Code (IaC) Scanning

### What is IaC Scanning?

**Scanning Targets**:
- Terraform configurations
- CloudFormation templates
- Kubernetes manifests
- Docker Compose files
- Helm charts

### Checkov (Comprehensive IaC Scanner)

**Installation**:
```bash
pip install checkov
```

**Scan Terraform**:
```bash
# Scan Terraform directory
checkov -d terraform/

# Scan specific file
checkov -f terraform/main.tf

# Skip specific checks
checkov -d terraform/ --skip-check CKV_AWS_19

# Output as JSON
checkov -d terraform/ -o json > checkov-results.json

# Fail on specific severity
checkov -d terraform/ --compact --quiet --framework terraform \
  --soft-fail-on LOW,MEDIUM --hard-fail-on HIGH,CRITICAL
```

**CI/CD Integration**:
```yaml
name: IaC Security Scan

on: [push, pull_request]

jobs:
  checkov:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
          soft_fail: false
          output_format: sarif
          download_external_modules: true

      - name: Upload SARIF file
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: results.sarif
```

**Suppress False Positives**:
```hcl
# terraform/main.tf
resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"

  # checkov:skip=CKV_AWS_18:Logging not required for this bucket
  # checkov:skip=CKV_AWS_21:Versioning disabled intentionally

  tags = {
    Name = "Example Bucket"
  }
}
```

### tfsec (Terraform Security Scanner)

**Installation**:
```bash
# Install tfsec
brew install tfsec

# Or download binary
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
```

**Scan**:
```bash
# Scan Terraform
tfsec .

# Scan with severity filter
tfsec --minimum-severity HIGH .

# Output as JSON
tfsec --format json --out tfsec-results.json .

# Exclude specific rules
tfsec --exclude aws-s3-enable-versioning .
```

**CI/CD Integration**:
```yaml
- name: tfsec
  uses: aquasecurity/tfsec-action@v1.0.0
  with:
    soft_fail: false
```

### Terrascan

**Scan Multiple IaC Types**:
```bash
# Install
brew install terrascan

# Scan Terraform
terrascan scan -t terraform -d terraform/

# Scan Kubernetes
terrascan scan -t k8s -d kubernetes/

# Scan Helm
terrascan scan -t helm -d charts/

# Scan Docker
terrascan scan -t docker -f Dockerfile
```

### Kubernetes Security

**Kubesec** (Kubernetes manifest security):
```bash
# Install kubesec
brew install kubesec

# Scan manifest
kubesec scan deployment.yaml

# Fail if score is low
kubesec scan deployment.yaml --exit-code 10
```

**Example Kubernetes Security Issues**:
```yaml
# BAD Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        securityContext:
          privileged: true          # ❌ Privileged container
          runAsNonRoot: false       # ❌ Running as root
        resources: {}               # ❌ No resource limits

# GOOD Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: myapp:v1.2.3         # ✅ Specific version
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop:
              - ALL
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
```

---

## Compliance Frameworks

### GDPR (General Data Protection Regulation)

**Scope**: EU residents' personal data

**Key Requirements**:

1. **Data Protection by Design**
```javascript
// Implement privacy by design
class UserService {
  async createUser(userData) {
    // Only collect necessary data
    const user = {
      email: userData.email,
      name: userData.name,
      // Don't store unnecessary PII
    };

    // Encrypt sensitive data
    user.dateOfBirth = encryptPII(userData.dateOfBirth);

    // Set data retention
    user.dataRetentionDate = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

    return await User.create(user);
  }
}
```

2. **Consent Management**
```javascript
const consentSchema = new mongoose.Schema({
  userId: { type: ObjectId, required: true },
  purposes: [{
    type: { type: String, enum: ['marketing', 'analytics', 'essential'] },
    granted: Boolean,
    timestamp: Date,
    ipAddress: String
  }],
  version: String  // Track consent policy version
});

// Require explicit consent
app.post('/api/consent', async (req, res) => {
  const { userId, purposes } = req.body;

  await Consent.create({
    userId,
    purposes: purposes.map(p => ({
      ...p,
      timestamp: new Date(),
      ipAddress: req.ip
    })),
    version: CURRENT_CONSENT_VERSION
  });

  res.json({ success: true });
});
```

3. **Right to Access (Data Export)**
```javascript
app.get('/api/users/:id/data-export', authenticateToken, async (req, res) => {
  // Verify user can only export own data
  if (req.user.id !== parseInt(req.params.id)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  // Gather all user data
  const user = await User.findById(req.params.id);
  const posts = await Post.find({ authorId: req.params.id });
  const consents = await Consent.find({ userId: req.params.id });

  const exportData = {
    user: {
      email: user.email,
      name: user.name,
      createdAt: user.createdAt
    },
    posts: posts.map(p => ({ title: p.title, content: p.content })),
    consents: consents
  };

  res.json(exportData);
});
```

4. **Right to Erasure (Right to be Forgotten)**
```javascript
app.delete('/api/users/:id/gdpr-delete', authenticateToken, async (req, res) => {
  const userId = req.params.id;

  // Verify authorization
  if (req.user.id !== parseInt(userId)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  // Delete or anonymize user data
  await User.findByIdAndDelete(userId);
  await Post.updateMany(
    { authorId: userId },
    { $set: { authorId: null, authorName: 'Deleted User' } }
  );
  await Consent.deleteMany({ userId });

  // Log deletion for audit
  await AuditLog.create({
    action: 'GDPR_DELETE',
    userId,
    timestamp: new Date()
  });

  res.json({ success: true });
});
```

5. **Breach Notification (72 hours)**
```javascript
async function handleDataBreach(breachDetails) {
  // Log breach
  await BreachLog.create({
    type: breachDetails.type,
    affectedUsers: breachDetails.affectedUserIds,
    discoveredAt: new Date(),
    severity: breachDetails.severity
  });

  // Notify supervisory authority if 72-hour window
  if (breachDetails.severity === 'high') {
    await notifySupervisoryAuthority(breachDetails);
  }

  // Notify affected users
  for (const userId of breachDetails.affectedUserIds) {
    await notifyUser(userId, breachDetails);
  }

  // Incident response
  await triggerIncidentResponse(breachDetails);
}
```

### HIPAA (Health Insurance Portability and Accountability Act)

**Scope**: Electronic Protected Health Information (ePHI) in US

**Key Requirements**:

1. **Audit Logging**
```javascript
const auditLogSchema = new mongoose.Schema({
  userId: ObjectId,
  action: { type: String, required: true },
  resourceType: String,
  resourceId: String,
  timestamp: { type: Date, default: Date.now },
  ipAddress: String,
  userAgent: String,
  result: { type: String, enum: ['success', 'failure'] }
});

// Middleware to log all ePHI access
function auditMiddleware(req, res, next) {
  const originalSend = res.send;

  res.send = function(data) {
    // Log after response
    AuditLog.create({
      userId: req.user?.id,
      action: `${req.method} ${req.path}`,
      resourceType: req.baseUrl,
      timestamp: new Date(),
      ipAddress: req.ip,
      userAgent: req.get('user-agent'),
      result: res.statusCode < 400 ? 'success' : 'failure'
    });

    originalSend.call(this, data);
  };

  next();
}
```

2. **Encryption Requirements**
```javascript
// All ePHI must be encrypted at rest
const patientSchema = new mongoose.Schema({
  _medicalRecordNumber: String,  // Encrypted
  _diagnosis: String,             // Encrypted
  _medications: String,           // Encrypted
});

// Transparent encryption
patientSchema.virtual('medicalRecordNumber')
  .get(function() { return decrypt(this._medicalRecordNumber); })
  .set(function(v) { this._medicalRecordNumber = encrypt(v); });

// Encryption in transit - TLS 1.2+
const httpsOptions = {
  minVersion: 'TLSv1.2',
  ciphers: 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256'
};
```

3. **Access Controls**
```javascript
// Role-based access for ePHI
const HIPAA_ROLES = {
  physician: ['read:patient', 'write:patient', 'read:medical_records'],
  nurse: ['read:patient', 'write:vitals'],
  admin: ['read:patient'],
  patient: ['read:own_records']
};

function requireHIPAAPermission(permission) {
  return (req, res, next) => {
    const userPermissions = HIPAA_ROLES[req.user.role] || [];

    if (!userPermissions.includes(permission)) {
      // Log access attempt
      AuditLog.create({
        userId: req.user.id,
        action: `DENIED: ${permission}`,
        result: 'failure'
      });

      return res.status(403).json({ error: 'Access denied' });
    }

    next();
  };
}
```

4. **Session Management**
```javascript
// Automatic session timeout (HIPAA requires)
const sessionConfig = {
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,
    httpOnly: true,
    maxAge: 15 * 60 * 1000,  // 15-minute timeout
    sameSite: 'strict'
  }
};

// Idle timeout
app.use((req, res, next) => {
  if (req.session.lastActivity) {
    const idle = Date.now() - req.session.lastActivity;

    if (idle > 15 * 60 * 1000) {  // 15 minutes
      req.session.destroy();
      return res.status(401).json({ error: 'Session expired due to inactivity' });
    }
  }

  req.session.lastActivity = Date.now();
  next();
});
```

### PCI-DSS (Payment Card Industry Data Security Standard)

**Scope**: Systems that store, process, or transmit cardholder data

**12 Requirements**:

**1. Install and maintain network security controls**
```bash
# Firewall rules (AWS Security Group example)
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345 \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0  # HTTPS only

# Deny all other inbound traffic by default
```

**2. Apply secure configurations**
```javascript
// Disable default accounts
// Change default passwords
// Remove unnecessary services

const secureServerConfig = {
  poweredBy: false,  // Don't reveal server type
  etag: false,
  'x-powered-by': false,
  server: false
};

app.use(helmet(secureServerConfig));
```

**3. Protect stored account data**
```javascript
// NEVER store sensitive authentication data after authorization
// - Full track data
// - CAV2/CVC2/CVV2/CID
// - PIN/PIN Block

// If storing PAN (Primary Account Number), it must be encrypted
function tokenizeCard(cardNumber) {
  // Use tokenization service instead of storing real PAN
  return paymentGateway.tokenize(cardNumber);
}

// Store only last 4 digits
function maskCardNumber(cardNumber) {
  return `****-****-****-${cardNumber.slice(-4)}`;
}
```

**4. Protect cardholder data with strong cryptography during transmission**
```javascript
// TLS 1.2+ required
const tlsOptions = {
  minVersion: 'TLSv1.2',
  ciphers: [
    'ECDHE-ECDSA-AES256-GCM-SHA384',
    'ECDHE-RSA-AES256-GCM-SHA384',
    'ECDHE-ECDSA-AES128-GCM-SHA256',
    'ECDHE-RSA-AES128-GCM-SHA256'
  ].join(':')
};
```

**10. Log and monitor all access**
```javascript
// PCI-DSS requires specific audit logging
const pciAuditLog = {
  userId: req.user.id,
  eventType: 'CARDHOLDER_DATA_ACCESS',
  timestamp: new Date(),
  outcome: 'success',
  affectedResource: 'payment_token_12345',
  originatingIP: req.ip,
  userAgent: req.get('user-agent'),
  systemComponent: 'payment-api'
};

// Logs must be retained for 1 year (3 months online)
```

### SOC 2 (Service Organization Control 2)

**Trust Service Criteria**:

1. **Security**: Protection against unauthorized access
2. **Availability**: System is available for operation
3. **Processing Integrity**: Complete, valid, accurate, timely processing
4. **Confidentiality**: Confidential information is protected
5. **Privacy**: Personal information is collected, used, retained, disclosed properly

**Implementation Example**:
```javascript
// Automated compliance checks
const soc2Controls = {
  security: {
    mfaEnforced: checkMFAEnforcement(),
    encryptionAtRest: checkEncryption(),
    accessLogsRetained: checkLogRetention(),
    vulnerabilityScanning: checkSecurityScans()
  },
  availability: {
    uptime: checkUptimeSLA(),  // 99.9% uptime
    backupsAutomated: checkBackups(),
    drPlanTested: checkDisasterRecoveryDrills()
  },
  processingIntegrity: {
    dataValidation: checkInputValidation(),
    errorHandling: checkErrorLogging(),
    dataIntegrityChecks: checkDataChecksums()
  }
};

// Generate compliance report
async function generateSOC2Report() {
  const report = {};

  for (const [criterion, controls] of Object.entries(soc2Controls)) {
    report[criterion] = {};

    for (const [control, checkFn] of Object.entries(controls)) {
      report[criterion][control] = await checkFn();
    }
  }

  return report;
}
```

---

## Vulnerability Management

### Vulnerability Lifecycle

```
1. Discovery → 2. Assessment → 3. Prioritization → 4. Remediation → 5. Verification
```

### CVSS Scoring

**Common Vulnerability Scoring System** (0-10 scale):

- **9.0-10.0**: Critical
- **7.0-8.9**: High
- **4.0-6.9**: Medium
- **0.1-3.9**: Low

### Vulnerability Database Example

```javascript
const vulnerabilitySchema = new mongoose.Schema({
  cveId: { type: String, required: true, unique: true },
  severity: { type: String, enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] },
  cvssScore: Number,
  description: String,
  affectedPackages: [{
    name: String,
    versions: [String]
  }],
  discoveredAt: Date,
  status: {
    type: String,
    enum: ['open', 'in_progress', 'resolved', 'accepted_risk'],
    default: 'open'
  },
  assignedTo: ObjectId,
  dueDate: Date,
  remediation: {
    description: String,
    fixedVersion: String,
    workaround: String
  }
});
```

### Remediation SLAs

| Severity | Response Time | Resolution Time |
|----------|---------------|-----------------|
| Critical | 1 hour | 24 hours |
| High | 4 hours | 7 days |
| Medium | 24 hours | 30 days |
| Low | 7 days | 90 days |

---

## Security Automation in CI/CD

### Complete Security Pipeline

```yaml
name: Security Pipeline

on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest

    steps:
      # 1. Checkout code
      - uses: actions/checkout@v3

      # 2. SAST - Static Analysis
      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: p/security-audit

      # 3. SCA - Dependency Scanning
      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

      # 4. Secret Scanning
      - name: GitGuardian scan
        uses: GitGuardian/ggshield-action@v1
        env:
          GITHUB_PUSH_BEFORE_SHA: ${{ github.event.before }}
          GITHUB_PUSH_BASE_SHA: ${{ github.event.base }}
          GITHUB_PULL_BASE_SHA: ${{ github.event.pull_request.base.sha }}
          GITHUB_DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}
          GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}

      # 5. Build Docker image
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .

      # 6. Container Scanning
      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      # 7. IaC Scanning
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          soft_fail: false

      # 8. Upload results
      - name: Upload to Security tab
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: trivy-results.sarif
```

---

## Summary

Security scanning and compliance are not one-time activities—they're ongoing processes that must be integrated into your development workflow. By automating security scans and implementing compliance controls early, you reduce risk and build trust with users and regulators.

**Key Takeaways**:
1. **Shift Left**: Scan early and often
2. **Automate Everything**: Security in CI/CD pipeline
3. **Fix Quickly**: Prioritize by severity, meet SLAs
4. **Stay Compliant**: Know your regulatory requirements
5. **Defense in Depth**: Multiple scanning types catch different issues

Stay secure and compliant! 🛡️
