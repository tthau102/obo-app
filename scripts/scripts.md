# Automation Scripts Documentation

This directory contains automation scripts for development, building, deployment, database management, and monitoring of the OBO Stadium application.

## Directory Structure

```
scripts/
├── setup/              # Initial setup and configuration
├── build/              # Build and compilation scripts
├── deploy/             # Deployment scripts (Kubernetes)
├── database/           # Database management scripts
├── monitoring/         # Health checks and log monitoring
└── scripts.md          # This documentation
```

## Prerequisites

All scripts require:
- **Bash 4.0+**
- **Execute permissions**: Run `chmod +x scripts/**/*.sh` to make scripts executable
- **Environment variables**: Most scripts read from `.env` file

Platform-specific requirements:
- **macOS**: Homebrew for dependency installation
- **Linux**: apt/yum package manager access
- **Docker**: For containerization scripts
- **kubectl**: For Kubernetes deployment scripts

## Quick Start

```bash
# 1. Make all scripts executable
chmod +x scripts/**/*.sh

# 2. Install dependencies
./scripts/setup/install-dependencies.sh

# 3. Setup environment
./scripts/setup/setup-env.sh

# 4. Initialize database
docker-compose up -d mysql
./scripts/database/init-db.sh

# 5. Build and run
./scripts/build/build-local.sh
./mvnw spring-boot:run
```

---

## Setup Scripts

### install-dependencies.sh

**Purpose**: Install all required dependencies for local development

**Usage**:
```bash
./scripts/setup/install-dependencies.sh
```

**What it does**:
- Detects OS (macOS/Linux)
- Installs Java 11 if not present
- Checks Docker installation
- Installs Docker Compose (Linux only)
- Installs kubectl for Kubernetes management
- Makes Maven wrapper executable

**Requirements**:
- Internet connection
- sudo access (for Linux package installation)

**Example Output**:
```
=========================================
Installing OBO App Dependencies
=========================================
Detected OS: Linux
Java 11 is already installed
Docker version 24.0.7 is installed
Docker Compose v2.23.0 is installed
kubectl v1.28.10 is installed

✅ All dependencies installed successfully!
```

---

### setup-env.sh

**Purpose**: Generate `.env` file from template with secure defaults

**Usage**:
```bash
./scripts/setup/setup-env.sh
```

**What it does**:
- Copies `.env.example` to `.env`
- Generates secure 256-bit JWT secret using OpenSSL
- Prompts for overwrite if `.env` exists

**Important**: After running, manually update:
- `DB_HOST` - Database host (default: mysql)
- `DB_USERNAME` - Database username (default: admin)
- `DB_PASSWORD` - Database password (default: changeme)
- `DB_NAME` - Database name (default: obo)

**Example Output**:
```
=========================================
Setting up Environment Configuration
=========================================
✅ Created .env from .env.example
✅ Generated secure JWT secret

⚠️  IMPORTANT: Review and update the following:
  - DB_HOST (current: mysql)
  - DB_USERNAME (current: admin)
  - DB_PASSWORD (current: changeme)
```

---

## Build Scripts

### build-local.sh

**Purpose**: Build application JAR file using Maven

**Usage**:
```bash
# Build with tests
./scripts/build/build-local.sh

# Build without tests (faster)
./scripts/build/build-local.sh --skip-tests
```

**What it does**:
- Runs `./mvnw clean`
- Builds JAR file with Maven
- Optionally skips unit tests
- Shows artifact location and size

**Output Artifact**: `target/obo-stadium-0.0.1-SNAPSHOT.jar`

**Example Output**:
```
=========================================
Building OBO Application (Local)
=========================================
Cleaning previous build...
Building with tests...
[INFO] BUILD SUCCESS

✅ Build successful!
   Artifact: target/obo-stadium-0.0.1-SNAPSHOT.jar
   Size: 85M
```

---

### build-docker.sh

**Purpose**: Build Docker image for local testing

**Usage**:
```bash
# Build with 'local' tag
./scripts/build/build-docker.sh

# Build with custom tag
./scripts/build/build-docker.sh v1.0.0
```

**What it does**:
- Builds Docker image using multi-stage Dockerfile
- Tags image with provided tag (default: `local`)
- Includes build metadata (build number, git commit)
- Shows image size and run instructions

**Build Arguments**:
- `BUILD_NUMBER` - Build timestamp
- `GIT_COMMIT` - Current git commit hash

**Example Output**:
```
=========================================
Building Docker Image
=========================================
Building image: obo-app:local
Using multi-stage Dockerfile...

✅ Docker image built successfully!
   Image: obo-app:local

REPOSITORY    TAG      SIZE
obo-app       local    140MB
```

---

## Deploy Scripts

### deploy-k8s.sh

**Purpose**: Deploy application to Kubernetes cluster

**Usage**:
```bash
# Deploy to default namespace with latest image
./scripts/deploy/deploy-k8s.sh

# Deploy to specific namespace
./scripts/deploy/deploy-k8s.sh obo-ns

# Deploy specific image tag
./scripts/deploy/deploy-k8s.sh obo-ns v1.2.3
```

**Parameters**:
1. `NAMESPACE` - Kubernetes namespace (default: `obo-ns`)
2. `IMAGE_TAG` - Docker image tag (default: `latest`)

**What it does**:
- Verifies kubectl connectivity
- Creates namespace if not exists (with confirmation)
- Updates deployment with new image using `kubectl set image`
- Waits for rollout completion (5min timeout)
- Shows pod, deployment, service, and ingress status

**Requirements**:
- kubectl configured with cluster access
- Harbor registry credentials configured in K8s
- Kubernetes manifests in `kubernetes/` directory

**Example Output**:
```
=========================================
Deploying to Kubernetes
=========================================
Namespace: obo-ns
Image: harbor.server.thweb.click/tthau/obo-app:latest

✅ Connected to cluster: rancher-desktop
Updating deployment image...
Waiting for rollout to complete (timeout: 5m)...
deployment "obo-app" successfully rolled out

✅ Deployment successful!

--- Pod Status ---
NAME                       READY   STATUS    RESTARTS   AGE
obo-app-7b8c9d5f6d-abc12   1/1     Running   0          30s
obo-app-7b8c9d5f6d-def34   1/1     Running   0          28s
```

---

### rollback-k8s.sh

**Purpose**: Rollback deployment to previous version

**Usage**:
```bash
# Rollback to previous revision
./scripts/deploy/rollback-k8s.sh

# Rollback to specific revision
./scripts/deploy/rollback-k8s.sh obo-ns 3

# Rollback in specific namespace
./scripts/deploy/rollback-k8s.sh my-namespace
```

**Parameters**:
1. `NAMESPACE` - Kubernetes namespace (default: `obo-ns`)
2. `REVISION` - Specific revision number (optional)

**What it does**:
- Shows rollout history
- Prompts for confirmation
- Rolls back deployment
- Waits for rollback completion
- Shows updated pod status

**Example Output**:
```
=========================================
Kubernetes Deployment Rollback
=========================================
Namespace: obo-ns

--- Rollout History ---
REVISION  CHANGE-CAUSE
1         kubectl set image deployment/obo-app obo-app=...
2         kubectl set image deployment/obo-app obo-app=...
3         kubectl set image deployment/obo-app obo-app=...

⚠️  You are about to rollback to the PREVIOUS revision
Continue? (y/N): y
Rolling back to previous revision...

✅ Rollback completed successfully!
```

---

## Database Scripts

### init-db.sh

**Purpose**: Initialize MySQL database for local development

**Usage**:
```bash
./scripts/database/init-db.sh
```

**What it does**:
- Loads database credentials from `.env`
- Checks MySQL connectivity
- Creates database if not exists (utf8mb4 charset)
- Reminds about Flyway automatic migrations

**Requirements**:
- MySQL server running (via Docker Compose or standalone)
- Valid credentials in `.env` file
- `nc` (netcat) for connectivity check

**Example Output**:
```
=========================================
Initializing Database
=========================================
Database Host: localhost
Database Port: 3306
Database Name: obo
Database User: admin

✅ MySQL is running
✅ Database 'obo' is ready

Flyway will automatically run migrations on first application startup
```

---

### backup-db.sh

**Purpose**: Backup MySQL database to compressed SQL file

**Usage**:
```bash
# Backup to default location (./backups)
./scripts/database/backup-db.sh

# Backup to custom directory
./scripts/database/backup-db.sh /path/to/backups
```

**Parameters**:
1. `OUTPUT_DIR` - Backup directory (default: `./backups`)

**What it does**:
- Creates backup directory if needed
- Exports database using `mysqldump`
- Includes routines, triggers, and events
- Compresses with gzip
- Shows backup file location and size

**Output Format**: `obo_db_backup_YYYYMMDD_HHMMSS.sql.gz`

**Requirements**:
- `mysqldump` command-line tool
- Database credentials in `.env`
- Write permissions for output directory

**Example Output**:
```
=========================================
Database Backup
=========================================
Database: obo
Output: ./backups/obo_db_backup_20250116_143025.sql

Backing up database...

✅ Backup completed successfully!
   File: ./backups/obo_db_backup_20250116_143025.sql.gz
   Size: 2.3M

To restore this backup:
  gunzip -c ./backups/obo_db_backup_20250116_143025.sql.gz | mysql -h $DB_HOST -u $DB_USERNAME -p $DB_NAME
```

---

## Monitoring Scripts

### health-check.sh

**Purpose**: Check application health endpoints

**Usage**:
```bash
# Check local application
./scripts/monitoring/health-check.sh

# Check specific URL
./scripts/monitoring/health-check.sh https://obo.app.thweb.click
```

**Parameters**:
1. `URL` - Application URL (default: `http://localhost:8080`)

**What it does**:
- Tests `/actuator/health` endpoint
- Tests `/actuator/health/liveness` probe
- Tests `/actuator/health/readiness` probe
- Shows `/actuator/info` endpoint data
- Pretty-prints JSON responses

**Requirements**:
- curl command-line tool
- python3 for JSON formatting (optional)
- Application running with Spring Boot Actuator

**Example Output**:
```
=========================================
Health Check
=========================================
Target: http://localhost:8080

--- Main Health Status ---
✅ Status: UP (HTTP 200)
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP"
    },
    "diskSpace": {
      "status": "UP"
    }
  }
}

--- Liveness Probe ---
✅ Liveness: UP (HTTP 200)

--- Readiness Probe ---
✅ Readiness: UP (HTTP 200)

--- Application Info ---
{
  "app": {
    "name": "obo-stadium",
    "version": "0.0.1-SNAPSHOT"
  }
}
```

---

### tail-logs-k8s.sh

**Purpose**: Stream logs from Kubernetes pods

**Usage**:
```bash
# Tail logs from default namespace
./scripts/monitoring/tail-logs-k8s.sh

# Tail logs from specific namespace
./scripts/monitoring/tail-logs-k8s.sh obo-ns
```

**Parameters**:
1. `NAMESPACE` - Kubernetes namespace (default: `obo-ns`)

**What it does**:
- Verifies kubectl connectivity and deployment exists
- Shows current pod status
- Streams logs from all pods in deployment
- Includes timestamps for each log line
- Streams from all containers (if multi-container pods)

**Requirements**:
- kubectl configured with cluster access
- Deployment exists in specified namespace

**Keyboard Shortcuts**:
- `Ctrl+C` - Stop tailing logs

**Example Output**:
```
=========================================
Tailing Logs from Kubernetes
=========================================
Namespace: obo-ns

--- Pod Status ---
NAME                       READY   STATUS    RESTARTS   AGE
obo-app-7b8c9d5f6d-abc12   1/1     Running   0          5m
obo-app-7b8c9d5f6d-def34   1/1     Running   0          5m

--- Streaming Logs (Ctrl+C to stop) ---

2025-01-16T14:30:45.123Z INFO  c.c.demo.DemoApplication : Starting application...
2025-01-16T14:30:46.456Z INFO  c.c.demo.DemoApplication : Connected to database
2025-01-16T14:30:47.789Z INFO  c.c.demo.DemoApplication : Application ready
```

---

## Common Workflows

### Local Development Workflow

```bash
# 1. First time setup
./scripts/setup/install-dependencies.sh
./scripts/setup/setup-env.sh

# 2. Start MySQL
docker-compose up -d mysql
./scripts/database/init-db.sh

# 3. Build and run
./scripts/build/build-local.sh
./mvnw spring-boot:run

# 4. Check health
./scripts/monitoring/health-check.sh
```

### Docker Development Workflow

```bash
# 1. Setup environment
./scripts/setup/setup-env.sh

# 2. Build Docker image
./scripts/build/build-docker.sh local-test

# 3. Run with Docker Compose
docker-compose up

# 4. Check health
./scripts/monitoring/health-check.sh
```

### Kubernetes Deployment Workflow

```bash
# 1. Build and push image (via Jenkins or manually)
./scripts/build/build-docker.sh v1.2.3
docker tag obo-app:v1.2.3 harbor.server.thweb.click/tthau/obo-app:v1.2.3
docker push harbor.server.thweb.click/tthau/obo-app:v1.2.3

# 2. Deploy to Kubernetes
./scripts/deploy/deploy-k8s.sh obo-ns v1.2.3

# 3. Monitor deployment
./scripts/monitoring/tail-logs-k8s.sh obo-ns

# 4. Check health
./scripts/monitoring/health-check.sh https://obo.app.thweb.click

# 5. Rollback if needed
./scripts/deploy/rollback-k8s.sh obo-ns
```

### Database Maintenance Workflow

```bash
# 1. Backup before changes
./scripts/database/backup-db.sh

# 2. Make changes (migrations run automatically)
./mvnw spring-boot:run

# 3. Backup after changes
./scripts/database/backup-db.sh
```

---

## Troubleshooting

### Script Permission Denied

**Problem**: `bash: ./scripts/setup/install-dependencies.sh: Permission denied`

**Solution**:
```bash
chmod +x scripts/**/*.sh
# Or for individual script:
chmod +x scripts/setup/install-dependencies.sh
```

### Database Connection Failed

**Problem**: `Cannot connect to MySQL at localhost:3306`

**Solutions**:
```bash
# Check if MySQL container is running
docker-compose ps

# Start MySQL if not running
docker-compose up -d mysql

# Check MySQL logs
docker-compose logs mysql

# Verify .env configuration
cat .env | grep DB_
```

### Kubernetes Deployment Failed

**Problem**: `Deployment failed or timed out`

**Solutions**:
```bash
# Check pod status
kubectl get pods -n obo-ns -l app=obo-app

# Describe pod for errors
kubectl describe pod <pod-name> -n obo-ns

# Check events
kubectl get events -n obo-ns --sort-by='.lastTimestamp'

# Check logs
./scripts/monitoring/tail-logs-k8s.sh obo-ns

# Common issues:
# - ImagePullBackOff: Check Harbor registry secret
# - CrashLoopBackOff: Check database connectivity
# - Pending: Check resource limits
```

### Health Check Failed

**Problem**: `Status: DOWN (HTTP 503)`

**Solutions**:
```bash
# Check application logs
./mvnw spring-boot:run

# Check database connectivity
./scripts/database/init-db.sh

# Check if all required services are running
docker-compose ps

# Check specific health components
curl http://localhost:8080/actuator/health | jq
```

---

## Best Practices

1. **Always make scripts executable after cloning**:
   ```bash
   chmod +x scripts/**/*.sh
   ```

2. **Review `.env` file before first run**:
   ```bash
   cat .env
   ```

3. **Backup database before major changes**:
   ```bash
   ./scripts/database/backup-db.sh
   ```

4. **Test locally before deploying to Kubernetes**:
   ```bash
   ./scripts/build/build-local.sh
   ./mvnw spring-boot:run
   ```

5. **Monitor deployments after rollout**:
   ```bash
   ./scripts/monitoring/tail-logs-k8s.sh
   ./scripts/monitoring/health-check.sh https://obo.app.thweb.click
   ```

6. **Use specific image tags for production**:
   ```bash
   # Good: Specific version
   ./scripts/deploy/deploy-k8s.sh obo-ns v1.2.3

   # Avoid: Latest tag in production
   # ./scripts/deploy/deploy-k8s.sh obo-ns latest
   ```

---

## Environment Variables Reference

All scripts that interact with the database or application read from `.env`:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `APP_PORT` | Application port | 8080 | No |
| `SPRING_PROFILES_ACTIVE` | Spring profile | dev | No |
| `DB_HOST` | Database host | mysql | Yes |
| `DB_PORT` | Database port | 3306 | Yes |
| `DB_NAME` | Database name | obo | Yes |
| `DB_USERNAME` | Database username | admin | Yes |
| `DB_PASSWORD` | Database password | changeme | Yes |
| `JWT_SECRET` | JWT signing key | (generated) | Yes |
| `JWT_DURATION` | JWT expiry (seconds) | 7200 | No |

---

## Additional Resources

- **Kubernetes Documentation**: See [kubernetes/README.md](../kubernetes/README.md)
- **Docker Compose**: See [docker-compose.yml](../docker-compose.yml)
- **Project README**: See [README.md](../README.md)
- **Architecture**: See [CLAUDE.md](../CLAUDE.md)

---

**Last Updated**: 2025-01-16
**Version**: 1.0
**Maintainer**: DevOps Team
