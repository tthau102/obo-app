# Kubernetes Deployment Guide

This directory contains production-ready Kubernetes manifests for deploying the OBO Stadium e-commerce application.

## 📋 Prerequisites

- Kubernetes cluster v1.24+ (tested on v1.28.10)
- `kubectl` configured with cluster access
- NGINX Ingress Controller installed
- cert-manager installed (for automatic TLS certificates)
- Harbor registry access (harbor.server.thweb.click)
- External MySQL database accessible from cluster

## 📂 Manifest Files

| File | Description |
|------|-------------|
| `00-namespace.yaml` | Namespace definition (obo-ns) |
| `01-configmap.yaml` | Non-sensitive configuration (DB host, ports, etc.) |
| `02-secret.yaml.example` | Secret template (DB password, JWT secret) |
| `03-harbor-secret.yaml.example` | Harbor registry credentials template |
| `04-deployment.yaml` | Application deployment with health checks |
| `05-service.yaml` | ClusterIP service |
| `06-ingress.yaml` | Ingress with TLS and security headers |
| `07-hpa.yaml` | Horizontal Pod Autoscaler (optional) |

## 🚀 Deployment Steps

### Step 1: Create Secrets

**Important:** DO NOT commit actual secrets to Git!

#### Create Application Secret

```bash
# Generate JWT secret (256-bit)
JWT_SECRET=$(openssl rand -base64 32)

# Create secret
kubectl create secret generic obo-secret \
  --from-literal=DB_PASSWORD='your_database_password' \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --namespace=obo-ns
```

#### Create Harbor Registry Secret

```bash
# Get robot account token from Harbor UI:
# Harbor → Projects → tthau → Robot Accounts → gitlab-ci

kubectl create secret docker-registry harbor-registry \
  --docker-server=harbor.server.thweb.click \
  --docker-username=gitlab-ci \
  --docker-password='ROBOT_ACCOUNT_TOKEN_HERE' \
  --namespace=obo-ns
```

### Step 2: Update ConfigMap

Edit `01-configmap.yaml` and update:
- `DB_HOST`: Your external MySQL IP address (e.g., `10.25.0.109`)
- `DB_USERNAME`: Your database username
- Other configurations as needed

### Step 3: Apply Manifests

```bash
# Apply in order (numbered files ensure correct sequence)
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmap.yaml
kubectl apply -f 04-deployment.yaml
kubectl apply -f 05-service.yaml
kubectl apply -f 06-ingress.yaml

# Optional: Apply HPA for autoscaling
kubectl apply -f 07-hpa.yaml
```

**Or apply all at once:**
```bash
kubectl apply -f kubernetes/ --recursive
```

### Step 4: Verify Deployment

```bash
# Check namespace
kubectl get ns obo-ns

# Check pods
kubectl get pods -n obo-ns

# Check deployment
kubectl get deployment obo-app -n obo-ns

# Check service
kubectl get svc -n obo-ns

# Check ingress
kubectl get ingress -n obo-ns

# Check HPA (if enabled)
kubectl get hpa -n obo-ns

# View logs
kubectl logs -f deployment/obo-app -n obo-ns

# Check health endpoint
kubectl exec -it deployment/obo-app -n obo-ns -- curl localhost:8080/actuator/health
```

## 🔧 Configuration

### Environment Variables

The application is configured via ConfigMap and Secrets:

**ConfigMap (obo-config):**
- `APP_PORT`: Application port (default: 8080)
- `SPRING_PROFILES_ACTIVE`: Spring profile (prod)
- `DB_HOST`: External MySQL host IP
- `DB_PORT`: MySQL port (default: 3306)
- `DB_NAME`: Database name (default: obo)
- `DB_USERNAME`: Database username
- `JWT_DURATION`: JWT token duration in seconds (default: 3600)

**Secret (obo-secret):**
- `DB_PASSWORD`: Database password
- `JWT_SECRET`: JWT signing secret (256-bit)

### Resource Limits

Current configuration:
- **Requests**: 200m CPU, 512Mi RAM
- **Limits**: 1000m CPU, 1Gi RAM
- **Replicas**: 2 (HPA can scale 2-5)

Adjust in `04-deployment.yaml` based on your workload.

### Health Checks

The deployment uses three types of probes:

1. **Liveness Probe**: Checks if app is alive (`/actuator/health/liveness`)
   - Fails → Pod restart
   - Initial delay: 60s, period: 10s

2. **Readiness Probe**: Checks if app is ready for traffic (`/actuator/health/readiness`)
   - Fails → Remove from service endpoints
   - Initial delay: 30s, period: 10s

3. **Startup Probe**: Allows slow startup (`/actuator/health`)
   - Max wait: 150s (30 failures × 5s period)

### Ingress Configuration

- **Domain**: obo.app.thweb.click
- **TLS**: Automatic certificate via cert-manager
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, etc.
- **Max Body Size**: 5MB (for file uploads)
- **Timeouts**: 60s for connect/send/read

## 🔄 Common Operations

### Update Application Image

```bash
# Option 1: Update deployment YAML and apply
# Edit 04-deployment.yaml, change image tag, then:
kubectl apply -f 04-deployment.yaml

# Option 2: Use kubectl set image
kubectl set image deployment/obo-app \
  obo-app=harbor.server.thweb.click/tthau/obo-app:v2.0 \
  -n obo-ns

# Watch rollout
kubectl rollout status deployment/obo-app -n obo-ns
```

### Rollback Deployment

```bash
# View rollout history
kubectl rollout history deployment/obo-app -n obo-ns

# Rollback to previous version
kubectl rollout undo deployment/obo-app -n obo-ns

# Rollback to specific revision
kubectl rollout undo deployment/obo-app --to-revision=2 -n obo-ns
```

### Scale Manually

```bash
# Scale to 3 replicas
kubectl scale deployment obo-app --replicas=3 -n obo-ns

# Or edit deployment
kubectl edit deployment obo-app -n obo-ns
```

### View Logs

```bash
# Tail logs from all pods
kubectl logs -f deployment/obo-app -n obo-ns

# Logs from specific pod
kubectl logs -f obo-app-xxxxx-yyyyy -n obo-ns

# Previous container logs (if pod crashed)
kubectl logs obo-app-xxxxx-yyyyy -n obo-ns --previous

# Stream logs with timestamps
kubectl logs -f deployment/obo-app -n obo-ns --timestamps=true
```

### Debug Pod Issues

```bash
# Describe pod
kubectl describe pod obo-app-xxxxx-yyyyy -n obo-ns

# Get pod events
kubectl get events -n obo-ns --sort-by='.lastTimestamp'

# Exec into pod
kubectl exec -it obo-app-xxxxx-yyyyy -n obo-ns -- /bin/sh

# Port forward to local
kubectl port-forward deployment/obo-app 8080:8080 -n obo-ns
```

### Update ConfigMap or Secret

```bash
# Edit ConfigMap
kubectl edit configmap obo-config -n obo-ns

# Edit Secret
kubectl edit secret obo-secret -n obo-ns

# Restart pods to pick up changes
kubectl rollout restart deployment/obo-app -n obo-ns
```

## 🛡️ Security Best Practices

### ✅ Implemented

- TLS encryption via cert-manager
- HTTP to HTTPS redirect
- Security headers (X-Frame-Options, CSP, etc.)
- Non-root container user (UID 1000)
- Read-only root filesystem capability
- Dropped all Linux capabilities
- imagePullSecrets for private registry
- Secrets stored in Kubernetes Secrets (not ConfigMap)
- Resource limits to prevent resource exhaustion

### 🔜 Recommended Additions

- **Network Policies**: Restrict pod-to-pod communication
- **Pod Security Standards**: Enforce restricted PSS
- **External Secrets Operator**: Integrate with Vault/AWS Secrets Manager
- **OPA/Gatekeeper**: Policy enforcement
- **Monitoring**: ServiceMonitor for Prometheus scraping
- **Logging**: FluentBit for log aggregation

## 📊 Monitoring

### Prometheus Integration

The deployment includes annotations for Prometheus scraping:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/path: "/actuator/prometheus"
  prometheus.io/port: "8080"
```

**Note**: Requires Spring Boot Actuator with Micrometer Prometheus exporter.

### Grafana Dashboards

Recommended dashboards:
- JVM Micrometer (ID: 4701)
- Spring Boot 2.1 Statistics (ID: 10280)
- Kubernetes / Compute Resources / Pod (ID: 6417)

## 🔥 Troubleshooting

### Pods CrashLoopBackOff

```bash
# Check logs
kubectl logs -f deployment/obo-app -n obo-ns --previous

# Common causes:
# 1. Database connection failed → Check DB_HOST in ConfigMap
# 2. Missing secrets → Verify obo-secret exists
# 3. Image pull failed → Check harbor-registry secret
```

### ImagePullBackOff

```bash
# Describe pod to see error
kubectl describe pod obo-app-xxxxx -n obo-ns

# Common causes:
# 1. Wrong registry secret → Recreate harbor-registry
# 2. Invalid image tag → Check Harbor for available tags
# 3. Network issue → Test: kubectl run test --image=harbor.../obo-app:latest -n obo-ns
```

### Ingress Not Working

```bash
# Check ingress
kubectl describe ingress obo-app-ing -n obo-ns

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check cert-manager
kubectl get certificate -n obo-ns
kubectl describe certificate obo-tls -n obo-ns

# Common causes:
# 1. DNS not pointing to LB → Check Cloudflare DNS
# 2. cert-manager issue → Check cert-manager logs
# 3. Ingress class mismatch → Verify ingressClassName: nginx
```

### Database Connection Failed

```bash
# Test database connectivity from pod
kubectl exec -it deployment/obo-app -n obo-ns -- sh
# Inside pod:
# nc -zv $DB_HOST $DB_PORT

# Check environment variables
kubectl exec deployment/obo-app -n obo-ns -- env | grep DB_

# Common causes:
# 1. Wrong DB_HOST → Update ConfigMap
# 2. Firewall blocking → Allow K8s worker IPs
# 3. Wrong credentials → Check obo-secret
```

## 📚 Additional Resources

- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)

## 🆘 Support

For issues or questions:
1. Check application logs: `kubectl logs -f deployment/obo-app -n obo-ns`
2. Check deployment events: `kubectl get events -n obo-ns`
3. Review this README's troubleshooting section
4. Contact DevOps team

---

**Last Updated**: 2025-01-15
**Kubernetes Version**: v1.28.10
**Application**: OBO Stadium E-commerce
