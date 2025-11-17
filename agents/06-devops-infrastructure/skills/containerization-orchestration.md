# Skill: Containerization & Orchestration

## Objective
Master Docker containerization and Kubernetes orchestration to deploy, manage, and scale containerized applications in production environments.

---

## Part 1: Docker Fundamentals

### What is Containerization?

**Containers** are lightweight, standalone, executable packages that include everything needed to run an application: code, runtime, system tools, libraries, and settings.

**Benefits**:
- **Consistency**: Same environment from development to production
- **Isolation**: Applications run independently without conflicts
- **Portability**: Run anywhere Docker is installed
- **Efficiency**: Share OS kernel, lighter than VMs
- **Scalability**: Easy to replicate and scale

**Docker vs Virtual Machines**:
```
Virtual Machine:
[App A] [App B]
[Bins/Libs] [Bins/Libs]
[Guest OS] [Guest OS]
[Hypervisor]
[Host OS]
[Infrastructure]

Docker Container:
[App A] [App B]
[Bins/Libs] [Bins/Libs]
[Docker Engine]
[Host OS]
[Infrastructure]
```

### Docker Architecture

**Components**:
- **Docker Client**: CLI that communicates with Docker daemon
- **Docker Daemon**: Background service managing containers
- **Docker Registry**: Repository for Docker images (Docker Hub, ECR, GCR)
- **Docker Images**: Read-only templates for creating containers
- **Docker Containers**: Running instances of images

### Essential Docker Commands

```bash
# Image Management
docker pull nginx:latest              # Download image from registry
docker images                         # List all images
docker rmi nginx:latest              # Remove image
docker build -t myapp:1.0 .          # Build image from Dockerfile
docker tag myapp:1.0 myrepo/myapp:1.0  # Tag image

# Container Lifecycle
docker run -d -p 8080:80 --name web nginx  # Run container
docker ps                             # List running containers
docker ps -a                         # List all containers
docker stop web                      # Stop container
docker start web                     # Start stopped container
docker restart web                   # Restart container
docker rm web                        # Remove container
docker rm -f web                     # Force remove running container

# Container Inspection
docker logs web                      # View container logs
docker logs -f web                   # Follow logs in real-time
docker exec -it web bash             # Execute command in container
docker inspect web                   # Detailed container info
docker stats                         # Resource usage statistics

# Container Management
docker cp file.txt web:/app/         # Copy file to container
docker port web                      # Show port mappings
docker top web                       # Show running processes
docker diff web                      # Show filesystem changes

# Cleanup
docker system prune                  # Remove unused data
docker system prune -a               # Remove all unused images
docker volume prune                  # Remove unused volumes
docker network prune                 # Remove unused networks
```

---

## Part 2: Dockerfile Best Practices

### Basic Dockerfile Structure

```dockerfile
# Simple Node.js Application
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production

# Run application
CMD ["node", "server.js"]
```

### Multi-Stage Builds (Production Optimization)

```dockerfile
# Stage 1: Build
FROM node:18 AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist

USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

### Python Application Dockerfile

```dockerfile
# Multi-stage build for Python
FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

USER nobody
EXPOSE 8000
CMD ["python", "app.py"]
```

### Go Application Dockerfile

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Production stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]
```

### Dockerfile Best Practices

**1. Use Official Base Images**
```dockerfile
# Good - Official and lightweight
FROM node:18-alpine

# Avoid - Unknown source, large size
FROM randomuser/node:latest
```

**2. Minimize Layers**
```dockerfile
# Good - Combined commands
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Avoid - Multiple RUN commands
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
```

**3. Order Commands by Change Frequency**
```dockerfile
# Dependencies change less frequently
COPY package*.json ./
RUN npm install

# Code changes more frequently
COPY . .
```

**4. Use .dockerignore**
```
# .dockerignore
node_modules
npm-debug.log
.git
.env
*.md
.DS_Store
dist
coverage
.vscode
```

**5. Don't Run as Root**
```dockerfile
# Create non-root user
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -S appuser -G appuser

USER appuser
```

**6. Security Scanning**
```dockerfile
# Use minimal base images
FROM alpine:3.18

# Scan images for vulnerabilities
# docker scan myapp:latest
# trivy image myapp:latest
```

---

## Part 3: Docker Compose

### What is Docker Compose?

Docker Compose is a tool for defining and running multi-container Docker applications using YAML configuration files.

### Basic Docker Compose Example

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=mypassword
      - POSTGRES_DB=mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

### Full-Stack Application Example

```yaml
version: '3.8'

services:
  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8000
    depends_on:
      - backend
    networks:
      - app-network

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/appdb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    volumes:
      - ./backend:/app
      - /app/node_modules
    networks:
      - app-network

  # Database
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    networks:
      - app-network

  # Cache
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Docker Compose Commands

```bash
# Start services
docker-compose up                    # Start in foreground
docker-compose up -d                 # Start in background (detached)
docker-compose up --build            # Rebuild images before starting

# Stop services
docker-compose down                  # Stop and remove containers
docker-compose down -v               # Also remove volumes
docker-compose stop                  # Stop without removing

# Service management
docker-compose ps                    # List running services
docker-compose logs                  # View logs from all services
docker-compose logs -f backend       # Follow logs for specific service
docker-compose exec backend bash     # Execute command in service

# Scaling
docker-compose up -d --scale backend=3  # Run 3 instances of backend

# Rebuild
docker-compose build                 # Rebuild all services
docker-compose build backend         # Rebuild specific service
```

### Development vs Production Compose

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      target: development
    volumes:
      - ./backend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DEBUG=*
    command: npm run dev
```

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      target: production
    environment:
      - NODE_ENV=production
    restart: always
    command: npm start
```

```bash
# Use different configs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Part 4: Kubernetes Architecture

### What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications.

**Key Features**:
- **Auto-scaling**: Horizontal and vertical pod scaling
- **Self-healing**: Automatic restart, replacement, and rescheduling
- **Load balancing**: Distribute traffic across pods
- **Rolling updates**: Zero-downtime deployments
- **Secret management**: Secure configuration and credentials
- **Storage orchestration**: Automatic storage provisioning

### Kubernetes Architecture

```
┌─────────────────────────────────────────────────┐
│              Control Plane (Master)             │
├─────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐            │
│  │ API Server   │  │  Scheduler   │            │
│  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Controller   │  │    etcd      │            │
│  │  Manager     │  │  (Database)  │            │
│  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────┘
                     │
      ┌──────────────┴──────────────┐
      │                             │
┌─────▼─────┐                 ┌─────▼─────┐
│  Node 1   │                 │  Node 2   │
├───────────┤                 ├───────────┤
│  Kubelet  │                 │  Kubelet  │
│  Kube-    │                 │  Kube-    │
│  proxy    │                 │  proxy    │
│           │                 │           │
│  ┌────┐   │                 │  ┌────┐   │
│  │Pod │   │                 │  │Pod │   │
│  └────┘   │                 │  └────┘   │
└───────────┘                 └───────────┘
```

**Control Plane Components**:
- **API Server**: Frontend for Kubernetes control plane
- **etcd**: Key-value store for cluster data
- **Scheduler**: Assigns pods to nodes
- **Controller Manager**: Runs controller processes

**Node Components**:
- **Kubelet**: Agent running on each node
- **Kube-proxy**: Network proxy maintaining network rules
- **Container Runtime**: Docker, containerd, CRI-O

### Core Kubernetes Objects

**Pod**: Smallest deployable unit, one or more containers
**Deployment**: Manages replicated pods with rolling updates
**Service**: Exposes pods as network service
**ConfigMap**: Configuration data for applications
**Secret**: Sensitive data like passwords and tokens
**Namespace**: Virtual cluster for resource isolation
**Ingress**: HTTP/HTTPS routing to services
**PersistentVolume**: Storage abstraction

---

## Part 5: Kubernetes Resources & Deployments

### Pod Definition

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

### Deployment Definition

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: myapp/backend:1.0
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Service Definitions

**ClusterIP Service (Internal)**:
```yaml
# service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
```

**NodePort Service (External Access)**:
```yaml
# service-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-nodeport
spec:
  type: NodePort
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
    nodePort: 30080
```

**LoadBalancer Service (Cloud Provider)**:
```yaml
# service-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-lb
spec:
  type: LoadBalancer
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
```

### ConfigMap

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    environment=production
    log_level=info
    max_connections=100
  nginx.conf: |
    server {
      listen 80;
      location / {
        proxy_pass http://backend:8000;
      }
    }
```

**Using ConfigMap in Pod**:
```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
    envFrom:
    - configMapRef:
        name: app-config
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

### Secrets

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: cGFzc3dvcmQxMjM=
  url: cG9zdGdyZXNxbDovL2FkbWluOnBhc3N3b3JkMTIzQGRiOjU0MzIvbXlkYg==
```

```bash
# Create secret from literal
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=password123

# Create secret from file
kubectl create secret generic tls-secret \
  --from-file=tls.crt=server.crt \
  --from-file=tls.key=server.key
```

### PersistentVolume and PersistentVolumeClaim

```yaml
# persistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /data/postgres
```

```yaml
# persistentvolumeclaim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
```

**Using PVC in Deployment**:
```yaml
spec:
  containers:
  - name: postgres
    image: postgres:15
    volumeMounts:
    - name: postgres-storage
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: postgres-storage
    persistentVolumeClaim:
      claimName: postgres-pvc
```

### Ingress

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

---

## Part 6: Essential kubectl Commands

```bash
# Cluster Information
kubectl cluster-info                 # Display cluster info
kubectl version                      # Show client and server version
kubectl get nodes                    # List all nodes

# Resource Management
kubectl get pods                     # List pods
kubectl get pods -o wide             # List pods with more details
kubectl get pods -n namespace        # List pods in namespace
kubectl get all                      # List all resources

kubectl describe pod my-pod          # Detailed pod information
kubectl logs my-pod                  # View pod logs
kubectl logs -f my-pod               # Follow logs
kubectl logs my-pod -c container     # Logs from specific container

kubectl exec -it my-pod -- bash      # Execute command in pod
kubectl exec my-pod -- env           # Run command in pod

# Create/Apply Resources
kubectl apply -f deployment.yaml     # Create/update resource
kubectl create -f pod.yaml           # Create resource
kubectl delete -f deployment.yaml    # Delete resource
kubectl delete pod my-pod            # Delete specific pod

# Deployments
kubectl get deployments              # List deployments
kubectl scale deployment my-app --replicas=5  # Scale deployment
kubectl rollout status deployment/my-app      # Check rollout status
kubectl rollout history deployment/my-app     # View rollout history
kubectl rollout undo deployment/my-app        # Rollback deployment

# Services
kubectl get services                 # List services
kubectl expose deployment my-app --port=80 --type=LoadBalancer

# ConfigMaps and Secrets
kubectl create configmap app-config --from-file=config.yaml
kubectl create secret generic db-secret --from-literal=password=secret
kubectl get configmaps
kubectl get secrets

# Namespaces
kubectl get namespaces               # List namespaces
kubectl create namespace dev         # Create namespace
kubectl config set-context --current --namespace=dev  # Switch namespace

# Debugging
kubectl describe pod my-pod          # Detailed pod info
kubectl get events                   # View cluster events
kubectl top nodes                    # Node resource usage
kubectl top pods                     # Pod resource usage
kubectl port-forward my-pod 8080:80  # Forward local port to pod
```

---

## Part 7: Complete Application Deployment

### Full-Stack Kubernetes Deployment

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
```

```yaml
# postgres-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: appdb
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: myapp
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: myrepo/backend:1.0.0
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          value: postgresql://$(DB_USER):$(DB_PASSWORD)@postgres:5432/appdb
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        - name: REDIS_URL
          value: redis://redis:6379
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: myapp
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8000
```

```yaml
# redis-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: myapp
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
```

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: myrepo/frontend:1.0.0
        ports:
        - containerPort: 80
        env:
        - name: API_URL
          value: http://backend
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: myapp
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
```

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: myapp
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

### Deployment Script

```bash
#!/bin/bash
# deploy.sh

# Create namespace
kubectl apply -f namespace.yaml

# Create secrets
kubectl create secret generic db-secret \
  --from-literal=username=appuser \
  --from-literal=password=secretpassword \
  --namespace=myapp \
  --dry-run=client -o yaml | kubectl apply -f -

# Create PVC
kubectl apply -f postgres-pvc.yaml

# Deploy database
kubectl apply -f postgres-deployment.yaml

# Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n myapp --timeout=60s

# Deploy Redis
kubectl apply -f redis-deployment.yaml

# Deploy backend
kubectl apply -f backend-deployment.yaml

# Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend -n myapp --timeout=60s

# Deploy frontend
kubectl apply -f frontend-deployment.yaml

# Deploy ingress
kubectl apply -f ingress.yaml

# Check status
kubectl get all -n myapp
```

---

## Part 8: Troubleshooting Guide

### Common Issues and Solutions

**1. Pod Not Starting (CrashLoopBackOff)**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Logs from previous crashed container

# Common causes:
# - Application error
# - Missing environment variables
# - Insufficient resources
# - Incorrect image
```

**2. ImagePullBackOff**
```bash
# Check events
kubectl describe pod <pod-name>

# Common causes:
# - Wrong image name
# - Private registry without credentials
# - Network issues

# Solution for private registry:
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password>

# Use in pod spec:
spec:
  imagePullSecrets:
  - name: regcred
```

**3. Service Not Reachable**
```bash
# Check service
kubectl get service <service-name>
kubectl describe service <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Test from within cluster
kubectl run test --image=busybox -it --rm -- wget -O- http://<service-name>

# Check labels match
kubectl get pods --show-labels
```

**4. Pod Pending (Not Scheduled)**
```bash
# Check pod events
kubectl describe pod <pod-name>

# Common causes:
# - Insufficient resources
# - No nodes available
# - Volume mount issues
# - Node selector/affinity not matching

# Check node resources
kubectl top nodes
kubectl describe node <node-name>
```

**5. Out of Memory (OOMKilled)**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Solution: Increase memory limits
spec:
  containers:
  - name: app
    resources:
      limits:
        memory: "512Mi"  # Increase this
```

### Debugging Workflow

```bash
# 1. Check pod status
kubectl get pods

# 2. Describe pod for events
kubectl describe pod <pod-name>

# 3. Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # Follow logs

# 4. Execute commands in pod
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec <pod-name> -- env  # Check environment variables

# 5. Port forward for local testing
kubectl port-forward <pod-name> 8080:80

# 6. Check resource usage
kubectl top pod <pod-name>

# 7. Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Performance Optimization

**1. Resource Requests and Limits**
```yaml
resources:
  requests:
    memory: "128Mi"  # Guaranteed minimum
    cpu: "250m"
  limits:
    memory: "256Mi"  # Maximum allowed
    cpu: "500m"
```

**2. Horizontal Pod Autoscaler**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**3. Pod Disruption Budget**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: backend-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: backend
```

---

## Best Practices

### Container Best Practices
1. Use official base images
2. Minimize image layers
3. Don't run as root
4. Use multi-stage builds
5. Scan for vulnerabilities
6. Keep images small
7. Use .dockerignore
8. Tag images properly

### Kubernetes Best Practices
1. Use namespaces for isolation
2. Set resource requests and limits
3. Implement health checks (liveness/readiness)
4. Use ConfigMaps and Secrets
5. Version your deployments
6. Use labels and annotations
7. Implement RBAC
8. Regular backups

### Security Best Practices
1. Scan images for vulnerabilities
2. Use private registries
3. Implement network policies
4. Use Pod Security Policies
5. Rotate secrets regularly
6. Enable audit logging
7. Use service accounts
8. Implement RBAC

## Success Indicators

- [ ] Built and optimized Docker images
- [ ] Created multi-container applications with Docker Compose
- [ ] Deployed applications to Kubernetes
- [ ] Configured services and ingress
- [ ] Implemented persistent storage
- [ ] Set up health checks and monitoring
- [ ] Debugged and troubleshooted issues
- [ ] Implemented auto-scaling
- [ ] Secured containers and cluster
- [ ] Documented deployment procedures
