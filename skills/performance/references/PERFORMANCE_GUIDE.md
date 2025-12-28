# Performance Optimization Guide

## Performance Checklist

### 1. Database
- [ ] Add indexes for frequent queries
- [ ] Use connection pooling
- [ ] Implement read replicas
- [ ] Optimize N+1 queries
- [ ] Use EXPLAIN ANALYZE

### 2. Caching
- [ ] Cache frequently accessed data
- [ ] Set appropriate TTLs
- [ ] Implement cache invalidation
- [ ] Monitor hit/miss ratios

### 3. Application
- [ ] Enable async processing
- [ ] Use connection pooling
- [ ] Optimize serialization
- [ ] Implement pagination

### 4. Infrastructure
- [ ] Configure load balancing
- [ ] Enable HTTP/2
- [ ] Use CDN for static assets
- [ ] Implement auto-scaling

## Load Balancing Algorithms

| Algorithm | Best For |
|-----------|----------|
| Round Robin | Equal servers |
| Least Connections | Variable response times |
| IP Hash | Session affinity |
| Weighted | Different server capacities |

## Monitoring Metrics

### Golden Signals
1. **Latency**: Request duration
2. **Traffic**: Requests per second
3. **Errors**: Error rate
4. **Saturation**: Resource usage
