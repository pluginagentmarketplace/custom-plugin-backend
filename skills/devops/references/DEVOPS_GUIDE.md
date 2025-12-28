# DevOps Best Practices Guide

## Docker Best Practices

1. **Use multi-stage builds** to reduce image size
2. **Run as non-root user** for security
3. **Use .dockerignore** to exclude unnecessary files
4. **Pin base image versions** for reproducibility
5. **Add health checks** for orchestration

## Kubernetes Deployment Checklist

- [ ] Resource limits and requests
- [ ] Liveness and readiness probes
- [ ] Pod disruption budgets
- [ ] Horizontal pod autoscaler
- [ ] Network policies
- [ ] Secrets management

## CI/CD Pipeline Stages

```yaml
stages:
  - lint          # Code quality checks
  - test          # Unit and integration tests
  - build         # Build artifacts/containers
  - security      # Security scanning
  - deploy-staging # Deploy to staging
  - integration   # Integration tests
  - deploy-prod   # Deploy to production
```

## Infrastructure as Code

| Tool | Purpose | State |
|------|---------|-------|
| Terraform | Provisioning | Remote state |
| Ansible | Configuration | Idempotent |
| Helm | K8s packages | Chart values |
