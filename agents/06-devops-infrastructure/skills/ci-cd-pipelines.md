# Skill: CI/CD Pipelines & Automation

## Objective
Master continuous integration and continuous deployment practices, implement automated pipelines across multiple platforms, and deploy applications with zero downtime using modern deployment strategies.

---

## Part 1: CI/CD Fundamentals

### What is CI/CD?

**Continuous Integration (CI)**
- Automatically build and test code on every commit
- Detect integration issues early
- Maintain code quality through automated checks
- Fast feedback to developers

**Continuous Delivery (CD)**
- Automatically prepare code for release
- Deploy to staging environments automatically
- Manual approval for production deployment
- Ensures code is always in deployable state

**Continuous Deployment**
- Automatically deploy to production
- No manual intervention required
- Every change that passes tests goes to production
- Requires high confidence in testing

### CI/CD Pipeline Stages

```
┌──────────────┐
│ Source Code  │
│   Commit     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│    Build     │  ← Compile code, install dependencies
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     Test     │  ← Unit, integration, security tests
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Package    │  ← Create artifacts, Docker images
└──────┬───────┘
       │
       ▼
┌──────────────┐
│    Deploy    │  ← Deploy to staging/production
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Monitor    │  ← Monitor application health
└──────────────┘
```

### Benefits of CI/CD

- **Faster Time to Market**: Deploy features quickly
- **Reduced Risk**: Small, incremental changes
- **Better Quality**: Automated testing catches bugs early
- **Increased Confidence**: Consistent deployment process
- **Developer Productivity**: Automate repetitive tasks
- **Better Collaboration**: Shared responsibility for quality

---

## Part 2: GitHub Actions

### GitHub Actions Basics

**Workflow Structure**
```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  NODE_VERSION: '18'

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Build application
        run: npm run build

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: dist/
```

### Complete CI/CD Pipeline with GitHub Actions

```yaml
# .github/workflows/cicd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Job 1: Code Quality Checks
  quality:
    name: Code Quality
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for better analysis

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run Prettier check
        run: npm run format:check

      - name: Run TypeScript type checking
        run: npm run type-check

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  # Job 2: Security Scanning
  security:
    name: Security Scan
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Run npm audit
        run: npm audit --audit-level=moderate

      - name: Check for secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD

  # Job 3: Unit and Integration Tests
  test:
    name: Test
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests
        run: npm run test:unit
        env:
          DATABASE_URL: postgresql://testuser:testpass@localhost:5432/testdb
          REDIS_URL: redis://localhost:6379

      - name: Run integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://testuser:testpass@localhost:5432/testdb
          REDIS_URL: redis://localhost:6379

      - name: Generate coverage report
        run: npm run test:coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
          flags: unittests
          name: codecov-umbrella

  # Job 4: Build Docker Image
  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [quality, security, test]
    if: github.event_name != 'pull_request'

    permissions:
      contents: read
      packages: write

    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-

      - name: Build and push Docker image
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan image for vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-image-results.sarif'

  # Job 5: Deploy to Staging
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'

    environment:
      name: staging
      url: https://staging.example.com

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster staging-cluster \
            --service backend-service \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services backend-service

      - name: Run smoke tests
        run: |
          curl -f https://staging.example.com/health || exit 1

  # Job 6: Deploy to Production
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'

    environment:
      name: production
      url: https://example.com

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy with blue-green strategy
        run: |
          # Update task definition with new image
          NEW_TASK_DEF=$(aws ecs describe-task-definition \
            --task-definition prod-app \
            --query 'taskDefinition' | \
            jq --arg IMAGE "${{ needs.build.outputs.image-tag }}" \
            '.containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')

          # Register new task definition
          NEW_TASK_INFO=$(aws ecs register-task-definition --cli-input-json "$NEW_TASK_DEF")
          NEW_REVISION=$(echo $NEW_TASK_INFO | jq -r '.taskDefinition.revision')

          # Update service to use new task definition
          aws ecs update-service \
            --cluster production-cluster \
            --service backend-service \
            --task-definition prod-app:$NEW_REVISION

          # Wait for deployment to complete
          aws ecs wait services-stable \
            --cluster production-cluster \
            --services backend-service

      - name: Run production smoke tests
        run: |
          curl -f https://example.com/health || exit 1
          curl -f https://example.com/api/status || exit 1

      - name: Notify deployment
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Production deployment completed!'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### GitHub Actions with Kubernetes

```yaml
# .github/workflows/k8s-deploy.yml
name: Deploy to Kubernetes

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build Docker image
        run: |
          docker build -t myapp:${{ github.sha }} .

      - name: Push to Docker Hub
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker tag myapp:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/myapp:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USERNAME }}/myapp:${{ github.sha }}

      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'

      - name: Configure kubectl
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig

      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/backend \
            backend=${{ secrets.DOCKER_USERNAME }}/myapp:${{ github.sha }} \
            --namespace=production

          kubectl rollout status deployment/backend --namespace=production

      - name: Verify deployment
        run: |
          kubectl get pods --namespace=production
          kubectl get services --namespace=production
```

### Reusable Workflows

```yaml
# .github/workflows/reusable-build.yml
name: Reusable Build Workflow

on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
      environment:
        required: true
        type: string
    outputs:
      image-tag:
        description: "Docker image tag"
        value: ${{ jobs.build.outputs.image-tag }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}

      - name: Build
        run: |
          npm ci
          npm run build
```

```yaml
# .github/workflows/main.yml
name: Main Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build:
    uses: ./.github/workflows/reusable-build.yml
    with:
      node-version: '18'
      environment: 'production'

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying ${{ needs.build.outputs.image-tag }}"
```

---

## Part 3: GitLab CI/CD

### GitLab CI Basics

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - package
  - deploy

variables:
  NODE_VERSION: "18"
  DOCKER_DRIVER: overlay2

# Build stage
build:
  stage: build
  image: node:${NODE_VERSION}
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

# Test stages
lint:
  stage: test
  image: node:${NODE_VERSION}
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run lint

unit-test:
  stage: test
  image: node:${NODE_VERSION}
  services:
    - postgres:15
    - redis:7
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    DATABASE_URL: "postgresql://testuser:testpass@postgres:5432/testdb"
    REDIS_URL: "redis://redis:6379"
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run test:unit
    - npm run test:integration
  coverage: '/Statements\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

security-scan:
  stage: test
  image: aquasec/trivy:latest
  script:
    - trivy fs --security-checks vuln,config .
  allow_failure: true

# Package stage
docker-build:
  stage: package
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
    - develop

# Deploy stages
deploy-staging:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - curl -X POST $STAGING_WEBHOOK_URL
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop

deploy-production:
  stage: deploy
  image: bitnami/kubectl:latest
  before_script:
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig
    - export KUBECONFIG=kubeconfig
  script:
    - kubectl set image deployment/backend backend=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -n production
    - kubectl rollout status deployment/backend -n production
  environment:
    name: production
    url: https://example.com
  when: manual
  only:
    - main
```

### Complete GitLab CI/CD Pipeline

```yaml
# .gitlab-ci.yml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

stages:
  - validate
  - build
  - test
  - security
  - package
  - deploy
  - verify

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  KUBERNETES_VERSION: "1.28"

# Stage 1: Validation
validate:code:
  stage: validate
  image: node:18
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run lint
    - npm run format:check
    - npm run type-check

validate:dockerfile:
  stage: validate
  image: hadolint/hadolint:latest-debian
  script:
    - hadolint Dockerfile

# Stage 2: Build
build:app:
  stage: build
  image: node:18
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
      - node_modules/
    expire_in: 1 day

# Stage 3: Test
test:unit:
  stage: test
  image: node:18
  services:
    - name: postgres:15
      alias: postgres
    - name: redis:7
      alias: redis
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    DATABASE_URL: "postgresql://testuser:testpass@postgres:5432/testdb"
    REDIS_URL: "redis://redis:6379"
  dependencies:
    - build:app
  script:
    - npm run test:unit
    - npm run test:integration
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

test:e2e:
  stage: test
  image: cypress/browsers:node18.12.0-chrome107
  services:
    - name: postgres:15
    - name: redis:7
  dependencies:
    - build:app
  script:
    - npm run start:test &
    - npx wait-on http://localhost:3000
    - npm run test:e2e
  artifacts:
    when: always
    paths:
      - cypress/videos/
      - cypress/screenshots/
    expire_in: 1 week

# Stage 4: Security
security:sast:
  stage: security

security:dependency-scan:
  stage: security

security:container-scan:
  stage: security
  dependencies:
    - package:docker

security:secrets:
  stage: security
  image: trufflesecurity/trufflehog:latest
  script:
    - trufflehog filesystem --directory=.
  allow_failure: true

# Stage 5: Package
package:docker:
  stage: package
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
  script:
    - docker build --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg VCS_REF=$CI_COMMIT_SHORT_SHA -t $IMAGE_TAG .
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:latest
    - docker push $IMAGE_TAG
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
    - develop
    - tags

# Stage 6: Deploy
.deploy_template: &deploy_template
  image: bitnami/kubectl:${KUBERNETES_VERSION}
  before_script:
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig
    - export KUBECONFIG=kubeconfig
    - kubectl version --client

deploy:staging:
  <<: *deploy_template
  stage: deploy
  script:
    - kubectl set image deployment/backend backend=$IMAGE_TAG -n staging
    - kubectl rollout status deployment/backend -n staging --timeout=5m
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop:staging
  only:
    - develop

deploy:production:
  <<: *deploy_template
  stage: deploy
  script:
    # Blue-Green Deployment
    - |
      # Create green deployment
      kubectl apply -f k8s/deployment-green.yaml -n production
      kubectl set image deployment/backend-green backend=$IMAGE_TAG -n production
      kubectl rollout status deployment/backend-green -n production --timeout=5m

      # Run smoke tests on green deployment
      GREEN_POD=$(kubectl get pod -l app=backend,version=green -n production -o jsonpath="{.items[0].metadata.name}")
      kubectl exec $GREEN_POD -n production -- curl -f http://localhost:8000/health

      # Switch traffic to green
      kubectl patch service backend -n production -p '{"spec":{"selector":{"version":"green"}}}'

      # Wait and verify
      sleep 30

      # Scale down blue deployment
      kubectl scale deployment/backend-blue --replicas=0 -n production
  environment:
    name: production
    url: https://example.com
  when: manual
  only:
    - main

# Stage 7: Verify
verify:production:
  stage: verify
  image: curlimages/curl:latest
  dependencies: []
  script:
    - curl -f https://example.com/health
    - curl -f https://example.com/api/status
  only:
    - main

# Rollback job
rollback:production:
  <<: *deploy_template
  stage: deploy
  script:
    - kubectl rollout undo deployment/backend -n production
    - kubectl rollout status deployment/backend -n production
  when: manual
  only:
    - main
```

---

## Part 4: Jenkins

### Jenkins Pipeline (Declarative)

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'myorg/myapp'
        KUBERNETES_NAMESPACE = 'production'
    }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup') {
            steps {
                script {
                    def nodeHome = tool name: 'Node-18', type: 'nodejs'
                    env.PATH = "${nodeHome}/bin:${env.PATH}"
                }
                sh 'node --version'
                sh 'npm --version'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }

        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm run test:unit'
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh 'npm run test:integration'
                    }
                }
            }
            post {
                always {
                    junit 'test-results/**/*.xml'
                    publishHTML([
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh 'npm audit --audit-level=moderate'
                sh 'trivy fs --security-checks vuln,config .'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        def image = docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    kubernetesDeploy(
                        configs: 'k8s/staging/*.yaml',
                        kubeconfigId: 'kubeconfig-staging'
                    )
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                script {
                    kubernetesDeploy(
                        configs: 'k8s/production/*.yaml',
                        kubeconfigId: 'kubeconfig-production'
                    )
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    curl -f https://example.com/health || exit 1
                    echo "Deployment verified!"
                '''
            }
        }
    }

    post {
        success {
            slackSend(
                color: 'good',
                message: "Build Successful: ${env.JOB_NAME} ${env.BUILD_NUMBER}"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "Build Failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}"
            )
        }
        always {
            cleanWs()
        }
    }
}
```

### Jenkins Shared Library

```groovy
// vars/standardPipeline.groovy
def call(Map config) {
    pipeline {
        agent any

        stages {
            stage('Build') {
                steps {
                    script {
                        buildApp(config.language)
                    }
                }
            }

            stage('Test') {
                steps {
                    script {
                        runTests(config.testCommand)
                    }
                }
            }

            stage('Deploy') {
                steps {
                    script {
                        deployApp(config.environment)
                    }
                }
            }
        }
    }
}
```

```groovy
// Jenkinsfile using shared library
@Library('my-shared-library') _

standardPipeline(
    language: 'nodejs',
    testCommand: 'npm test',
    environment: 'production'
)
```

---

## Part 5: GitOps with ArgoCD

### ArgoCD Application Definition

```yaml
# application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/myorg/myapp.git
    targetRevision: HEAD
    path: k8s/overlays/production
    kustomize:
      images:
        - myrepo/myapp:v1.2.3

  destination:
    server: https://kubernetes.default.svc
    namespace: production

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### Kustomize Structure for GitOps

```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── overlays/
    ├── staging/
    │   ├── kustomization.yaml
    │   ├── replicas.yaml
    │   └── namespace.yaml
    └── production/
        ├── kustomization.yaml
        ├── replicas.yaml
        ├── resources.yaml
        └── namespace.yaml
```

```yaml
# k8s/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - ingress.yaml

commonLabels:
  app: backend
```

```yaml
# k8s/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

bases:
  - ../../base

patchesStrategicMerge:
  - replicas.yaml
  - resources.yaml

images:
  - name: myrepo/myapp
    newTag: v1.2.3

configMapGenerator:
  - name: app-config
    literals:
      - ENV=production
      - LOG_LEVEL=info
```

```yaml
# k8s/overlays/production/replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 5
```

### GitOps Workflow with ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Create application
kubectl apply -f application.yaml

# Sync application
argocd app sync backend-app

# View application status
argocd app get backend-app

# Rollback
argocd app rollback backend-app
```

---

## Part 6: Deployment Strategies

### 1. Rolling Update (Default Kubernetes)

```yaml
# rolling-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired count
      maxUnavailable: 1  # Max pods that can be unavailable
  template:
    spec:
      containers:
      - name: backend
        image: myapp:v2.0.0
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 2. Blue-Green Deployment

```yaml
# blue-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-blue
  labels:
    app: backend
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
      version: blue
  template:
    metadata:
      labels:
        app: backend
        version: blue
    spec:
      containers:
      - name: backend
        image: myapp:v1.0.0
        ports:
        - containerPort: 8000
```

```yaml
# green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-green
  labels:
    app: backend
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
      version: green
  template:
    metadata:
      labels:
        app: backend
        version: green
    spec:
      containers:
      - name: backend
        image: myapp:v2.0.0
        ports:
        - containerPort: 8000
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
    version: blue  # Switch to 'green' to cutover
  ports:
  - port: 80
    targetPort: 8000
```

```bash
# Blue-Green Deployment Script
#!/bin/bash

# Deploy green version
kubectl apply -f green-deployment.yaml

# Wait for green pods to be ready
kubectl wait --for=condition=ready pod -l version=green --timeout=300s

# Run smoke tests on green
GREEN_POD=$(kubectl get pod -l version=green -o jsonpath="{.items[0].metadata.name}")
kubectl exec $GREEN_POD -- curl -f http://localhost:8000/health

# Switch traffic to green
kubectl patch service backend -p '{"spec":{"selector":{"version":"green"}}}'

# Monitor for issues
sleep 60

# If all good, scale down blue
kubectl scale deployment backend-blue --replicas=0

# If issues occur, rollback to blue
# kubectl patch service backend -p '{"spec":{"selector":{"version":"blue"}}}'
```

### 3. Canary Deployment

```yaml
# canary-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-canary
spec:
  replicas: 1  # Start with 1 pod (10% of traffic)
  selector:
    matchLabels:
      app: backend
      track: canary
  template:
    metadata:
      labels:
        app: backend
        track: canary
    spec:
      containers:
      - name: backend
        image: myapp:v2.0.0
```

```yaml
# stable-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-stable
spec:
  replicas: 9  # 90% of traffic
  selector:
    matchLabels:
      app: backend
      track: stable
  template:
    metadata:
      labels:
        app: backend
        track: stable
    spec:
      containers:
      - name: backend
        image: myapp:v1.0.0
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend  # Selects both stable and canary
  ports:
  - port: 80
    targetPort: 8000
```

```bash
# Canary Deployment Script
#!/bin/bash

# Deploy canary with 10% traffic
kubectl apply -f canary-deployment.yaml

# Monitor metrics
echo "Monitoring canary metrics..."
sleep 300  # Monitor for 5 minutes

# Check error rate
ERROR_RATE=$(kubectl top pod -l track=canary --no-headers | awk '{print $3}')

if [ "$ERROR_RATE" -lt "5" ]; then
  # Gradually increase canary traffic
  kubectl scale deployment backend-canary --replicas=3  # 30%
  sleep 300

  kubectl scale deployment backend-canary --replicas=5  # 50%
  sleep 300

  # Full rollout
  kubectl scale deployment backend-canary --replicas=10
  kubectl scale deployment backend-stable --replicas=0

  # Promote canary to stable
  kubectl set image deployment/backend-stable backend=myapp:v2.0.0
  kubectl scale deployment backend-stable --replicas=10
  kubectl delete deployment backend-canary
else
  # Rollback canary
  echo "High error rate detected. Rolling back..."
  kubectl delete deployment backend-canary
fi
```

### 4. Advanced Canary with Flagger

```yaml
# flagger-canary.yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: backend
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  service:
    port: 80
    targetPort: 8000
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
      - name: request-success-rate
        thresholdRange:
          min: 99
        interval: 1m
      - name: request-duration
        thresholdRange:
          max: 500
        interval: 1m
  webhooks:
    - name: load-test
      url: http://flagger-loadtester/
      timeout: 5s
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://backend-canary/"
```

---

## Part 7: Pipeline Best Practices

### Security Best Practices

1. **Never Hardcode Secrets**
```yaml
# Bad
env:
  - name: API_KEY
    value: "hardcoded-secret"

# Good
env:
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: api-secrets
        key: api-key
```

2. **Scan for Vulnerabilities**
```yaml
- name: Security scan
  run: |
    trivy image myapp:latest
    npm audit
    snyk test
```

3. **Sign and Verify Images**
```bash
# Sign image with cosign
cosign sign --key cosign.key myrepo/myapp:v1.0.0

# Verify signature
cosign verify --key cosign.pub myrepo/myapp:v1.0.0
```

### Performance Optimization

1. **Cache Dependencies**
```yaml
- name: Cache node modules
  uses: actions/cache@v3
  with:
    path: node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

2. **Parallel Jobs**
```yaml
jobs:
  test-unit:
    runs-on: ubuntu-latest
  test-integration:
    runs-on: ubuntu-latest
  test-e2e:
    runs-on: ubuntu-latest
```

3. **Build Only What Changed**
```yaml
- name: Check changes
  id: changes
  uses: dorny/paths-filter@v2
  with:
    filters: |
      backend:
        - 'backend/**'
      frontend:
        - 'frontend/**'

- name: Build backend
  if: steps.changes.outputs.backend == 'true'
  run: npm run build:backend
```

### Monitoring and Observability

1. **Pipeline Metrics**
- Build duration
- Success/failure rates
- Deployment frequency
- Time to recovery

2. **Notifications**
```yaml
- name: Notify Slack
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Success Indicators

- [ ] Implemented automated CI/CD pipeline
- [ ] All tests run automatically on commits
- [ ] Automated security scanning
- [ ] Zero-downtime deployments
- [ ] Rollback capability implemented
- [ ] Deployment metrics tracked
- [ ] Infrastructure as code versioned
- [ ] GitOps workflow established
- [ ] Multiple deployment strategies mastered
- [ ] Pipeline documentation complete
