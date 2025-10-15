# Migration Guide - Security Updates

This guide helps you migrate from the old version to the new security-hardened version of OBO Stadium application.

## Pre-Migration Checklist

- [ ] Backup your database
- [ ] Note down current environment variables
- [ ] Test the migration in a staging environment first
- [ ] Plan for application downtime (estimated: 15-30 minutes)
- [ ] Inform users about the maintenance window

## Step-by-Step Migration

### Step 1: Update Application Code

```bash
# Pull the latest code
git pull origin main

# Or if you have local changes:
git stash
git pull origin main
git stash pop
```

### Step 2: Generate Strong JWT Secret

```bash
# Generate a secure 256-bit JWT secret
openssl rand -base64 32

# Save this output - you'll need it for environment variables
# Example output: "Xm3K8vNqP2wR5yT7uH9jL1mN4bV6cX8zA0sD2fG4hJ6="
```

### Step 3: Configure Environment Variables

#### Option A: Using .env file (Development)

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your values
nano .env
```

Fill in:
```bash
DB_HOST=mysql
DB_PORT=3306
DB_NAME=obo
DB_USERNAME=obo_user
DB_PASSWORD=your_new_secure_password_here  # Change this!

JWT_SECRET=Xm3K8vNqP2wR5yT7uH9jL1mN4bV6cX8zA0sD2fG4hJ6=  # Use your generated secret
JWT_DURATION=7200  # 2 hours

SPRING_PROFILES_ACTIVE=dev
```

#### Option B: Using Environment Variables (Production)

```bash
export DB_HOST=your-mysql-host
export DB_PORT=3306
export DB_NAME=obo
export DB_USERNAME=obo_user
export DB_PASSWORD='your_secure_password'
export JWT_SECRET='Xm3K8vNqP2wR5yT7uH9jL1mN4bV6cX8zA0sD2fG4hJ6='
export JWT_DURATION=3600
export SPRING_PROFILES_ACTIVE=prod

# Production database URL
export DATABASE_URL='jdbc:mysql://your-db-host:3306/obo?useSSL=true&requireSSL=true'
export DATABASE_USERNAME=obo_user
export DATABASE_PASSWORD='your_production_password'
```

### Step 4: Update Database Password (IMPORTANT!)

```sql
-- Connect to MySQL as root
mysql -u root -p

-- Change the database user password
ALTER USER 'obo_user'@'%' IDENTIFIED BY 'your_new_secure_password';
FLUSH PRIVILEGES;

-- Verify the change
SELECT User, Host FROM mysql.user WHERE User = 'obo_user';
```

### Step 5: Prepare Database for Flyway

For **existing databases**, you need to baseline:

```bash
# Build the application first
./mvnw clean package -DskipTests

# Baseline the database (marks current schema as V1)
./mvnw flyway:baseline

# Then run migrations
./mvnw flyway:migrate
```

For **new databases**:
```bash
# Just run migrations
./mvnw flyway:migrate
```

### Step 6: Build and Test Locally

```bash
# Clean and build
./mvnw clean package

# Run tests
./mvnw test

# Start the application
./mvnw spring-boot:run

# In another terminal, test the health endpoint
curl http://localhost:8080/actuator/health
```

Expected response:
```json
{"status":"UP"}
```

### Step 7: Test Security Features

#### Test 1: Rate Limiting
```bash
# Send 6 login requests quickly - the 6th should be blocked
for i in {1..6}; do
  curl -X POST http://localhost:8080/api/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"wrong"}'
  echo ""
done
```

6th request should return: `429 Too Many Requests`

#### Test 2: JWT Token Expiration
```bash
# Login and save the cookie
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"your_password"}' \
  -c cookies.txt

# Access protected endpoint
curl http://localhost:8080/tai-khoan -b cookies.txt

# Wait 2+ hours, then try again - should be unauthorized
```

#### Test 3: SQL Injection Protection
```bash
# Try SQL injection in product search
curl "http://localhost:8080/admin/san-pham?order=id'; DROP TABLE product;--"

# Should return default ordering, not execute the injection
```

### Step 8: Update Docker Image

```bash
# Build new Docker image
docker build -t harbor.server.thweb.click/harbor-obo/obo-app:security-v1 .

# Test the image locally
docker run -d -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_USERNAME=obo_user \
  -e DB_PASSWORD=your_password \
  -e JWT_SECRET=your_jwt_secret \
  harbor.server.thweb.click/harbor-obo/obo-app:security-v1

# Check logs
docker logs <container_id>

# Test health endpoint
curl http://localhost:8080/actuator/health
```

### Step 9: Deploy to Kubernetes

#### Update Secrets

```bash
# Create or update the database secret
kubectl create secret generic obo-db-secret \
  --from-literal=DB_PASSWORD='your_new_secure_password' \
  --dry-run=client -o yaml | kubectl apply -f - -n obo-ns

# Create JWT secret
kubectl create secret generic obo-jwt-secret \
  --from-literal=JWT_SECRET='your_generated_jwt_secret' \
  --dry-run=client -o yaml | kubectl apply -f - -n obo-ns
```

#### Update Deployment

Edit `kubernetes/1.app.yml` to use the new secret:

```yaml
env:
  - name: JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: obo-jwt-secret
        key: JWT_SECRET
```

Deploy:
```bash
# Apply the updated manifests
kubectl apply -f kubernetes/1.app.yml

# Watch the rollout
kubectl rollout status deployment/obo-app -n obo-ns

# Check pods
kubectl get pods -n obo-ns

# Check logs
kubectl logs -f deployment/obo-app -n obo-ns
```

#### Verify Deployment

```bash
# Check health via ingress
curl https://obo.app.thweb.click/actuator/health

# Check application is running
curl https://obo.app.thweb.click/
```

### Step 10: Monitor After Deployment

```bash
# Watch logs for errors
kubectl logs -f deployment/obo-app -n obo-ns

# Check pod resource usage
kubectl top pods -n obo-ns

# Check metrics
curl https://obo.app.thweb.click/actuator/metrics
```

## Rollback Plan

If issues occur, rollback:

### For Docker/Local
```bash
# Stop new version
docker stop <container_id>

# Start old version
docker run -d -p 8080:8080 <old_image>
```

### For Kubernetes
```bash
# Rollback to previous version
kubectl rollout undo deployment/obo-app -n obo-ns

# Or rollback to specific revision
kubectl rollout history deployment/obo-app -n obo-ns
kubectl rollout undo deployment/obo-app --to-revision=<number> -n obo-ns
```

### For Database
```bash
# If Flyway migrations failed, they will auto-rollback
# If you need to manually rollback:
./mvnw flyway:undo  # Requires Flyway Teams edition

# Or restore from backup:
mysql -u root -p obo < backup_before_migration.sql
```

## Common Issues & Solutions

### Issue 1: "JWT secret must be at least 256 bits"
**Solution:** Generate a proper secret with `openssl rand -base64 32`

### Issue 2: "Flyway failed: Schema version mismatch"
**Solution:**
```bash
./mvnw flyway:repair
./mvnw flyway:baseline
./mvnw flyway:migrate
```

### Issue 3: "Too many connections to database"
**Solution:** Check HikariCP pool settings in `application-prod.properties`

### Issue 4: "Rate limit blocking legitimate users"
**Solution:** Adjust rate limits in `RateLimitingFilter.java` - increase from 5 to 10 requests/minute

### Issue 5: "Health checks failing in Kubernetes"
**Solution:** Increase `initialDelaySeconds` in readiness/liveness probes:
```yaml
readinessProbe:
  initialDelaySeconds: 60  # Increase if app takes longer to start
```

### Issue 6: "Old JWT tokens not working"
**Solution:** This is expected - users need to re-login after migration

## Post-Migration Checklist

- [ ] Verify application is accessible
- [ ] Test login/logout functionality
- [ ] Test product browsing and search
- [ ] Test order creation (with concurrent users if possible)
- [ ] Verify admin panel access
- [ ] Check application logs for errors
- [ ] Monitor database connection pool
- [ ] Verify rate limiting is working
- [ ] Check health endpoint returns UP
- [ ] Verify HTTPS is enabled (production)
- [ ] Test that old JWT tokens are invalidated
- [ ] Verify database migrations completed successfully

## Security Hardening (Post-Migration)

After successful migration, implement these additional hardening steps:

1. **Enable HTTPS in Production:**
   ```java
   // In UserController.java
   cookie.setSecure(true);
   ```

2. **Rotate JWT Secret Regularly:**
   - Schedule quarterly JWT secret rotation
   - Document the rotation process

3. **Set up Monitoring:**
   - Configure alerts for failed login attempts
   - Monitor rate limit violations
   - Track database connection pool usage

4. **Implement Backup Strategy:**
   - Automated daily database backups
   - Test restore procedures monthly

5. **Review Access Logs:**
   - Set up log aggregation (ELK stack or similar)
   - Review suspicious access patterns weekly

## Support

If you encounter issues during migration:

1. Check application logs: `kubectl logs -f deployment/obo-app -n obo-ns`
2. Check database logs
3. Review this guide and `SECURITY_IMPROVEMENTS.md`
4. Contact the development team

---

**Migration Version:** 1.0
**Last Updated:** 2025-01-15
**Tested On:** Spring Boot 2.7.18, MySQL 5.7+, Kubernetes 1.24+
