# Build Instructions

## Prerequisites

- Java 11 or higher
- Maven 3.6+
- MySQL 5.7+
- Docker (optional)
- Kubernetes cluster (optional, for deployment)

## Local Development Build

### 1. Install Dependencies

```bash
# Verify Java version
java -version  # Should be 11 or higher

# Verify Maven
mvn -version

# Or use the Maven wrapper (recommended)
./mvnw -version
```

### 2. Set Up Database

```bash
# Create database
mysql -u root -p
CREATE DATABASE obo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'obo_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON obo.* TO 'obo_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Configure Environment

```bash
# Copy and edit environment file
cp .env.example .env

# Generate JWT secret
openssl rand -base64 32

# Edit .env with your values
nano .env
```

### 4. Build the Application

```bash
# Clean and compile
./mvnw clean compile

# Run tests (optional)
./mvnw test

# Build JAR package
./mvnw clean package

# Skip tests if needed
./mvnw clean package -DskipTests
```

The compiled JAR will be in `target/obo-stadium-0.0.1-SNAPSHOT.jar`

### 5. Run Database Migrations

```bash
# Run Flyway migrations
./mvnw flyway:migrate

# Or if you have existing data, baseline first:
./mvnw flyway:baseline
./mvnw flyway:migrate
```

### 6. Run the Application

```bash
# Using Maven
./mvnw spring-boot:run

# Or using the JAR directly
java -jar target/obo-stadium-0.0.1-SNAPSHOT.jar

# With environment variables
JWT_SECRET=your_secret DB_PASSWORD=your_password java -jar target/obo-stadium-0.0.1-SNAPSHOT.jar
```

The application will start on `http://localhost:8080`

### 7. Verify the Build

```bash
# Check health endpoint
curl http://localhost:8080/actuator/health

# Expected response:
{"status":"UP","components":{"db":{"status":"UP"}}}

# Access Swagger UI (API documentation)
open http://localhost:8080/swagger-ui/index.html
```

## Docker Build

### Build Docker Image

```bash
# Build image
docker build -t obo-app:latest .

# Build with specific tag
docker build -t harbor.server.thweb.click/harbor-obo/obo-app:v1.0 .
```

### Run Docker Container

```bash
# Run with environment variables
docker run -d -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=3306 \
  -e DB_NAME=obo \
  -e DB_USERNAME=obo_user \
  -e DB_PASSWORD=your_password \
  -e JWT_SECRET=your_jwt_secret \
  --name obo-app \
  obo-app:latest

# Check logs
docker logs -f obo-app

# Stop container
docker stop obo-app

# Remove container
docker rm obo-app
```

### Push to Harbor Registry

```bash
# Login to Harbor
docker login harbor.server.thweb.click

# Tag image
docker tag obo-app:latest harbor.server.thweb.click/harbor-obo/obo-app:latest
docker tag obo-app:latest harbor.server.thweb.click/harbor-obo/obo-app:v1.0.0

# Push to registry
docker push harbor.server.thweb.click/harbor-obo/obo-app:latest
docker push harbor.server.thweb.click/harbor-obo/obo-app:v1.0.0
```

## Kubernetes Deployment

### Deploy to Kubernetes

```bash
# Create namespace
kubectl create namespace obo-ns

# Apply configurations
kubectl apply -f kubernetes/1.app.yml

# Check deployment status
kubectl rollout status deployment/obo-app -n obo-ns

# View pods
kubectl get pods -n obo-ns

# View logs
kubectl logs -f deployment/obo-app -n obo-ns
```

### Update Deployment

```bash
# Update image
kubectl set image deployment/obo-app \
  obo-app=harbor.server.thweb.click/harbor-obo/obo-app:v1.0.0 \
  -n obo-ns

# Or apply updated manifest
kubectl apply -f kubernetes/1.app.yml

# Rollout restart
kubectl rollout restart deployment/obo-app -n obo-ns
```

## CI/CD Pipeline (Jenkins)

The Jenkinsfile automates the build and deployment process:

```bash
# Trigger Jenkins build
# Pipeline will:
# 1. Checkout code from GitLab
# 2. Build Docker image
# 3. Push to Harbor registry with BUILD_NUMBER tag
# 4. (Optional) Deploy to Kubernetes
```

To enable Kubernetes deployment, uncomment the deploy stage in `Jenkinsfile`.

## Build Profiles

### Development Profile

```bash
# Build with dev profile
./mvnw clean package -Pdev

# Run with dev profile
SPRING_PROFILES_ACTIVE=dev java -jar target/obo-stadium-0.0.1-SNAPSHOT.jar
```

Features:
- SQL logging enabled
- Hot reload for templates
- Detailed error messages
- Relaxed security settings

### Production Profile

```bash
# Build for production
./mvnw clean package -Pprod

# Run with production profile
SPRING_PROFILES_ACTIVE=prod java -jar target/obo-stadium-0.0.1-SNAPSHOT.jar
```

Features:
- SQL logging disabled
- Template caching enabled
- Minimal error messages
- Strict security settings
- Optimized performance

## Troubleshooting Build Issues

### Issue: Maven dependencies not downloading

```bash
# Clear Maven cache
./mvnw dependency:purge-local-repository

# Or manually delete and re-download
rm -rf ~/.m2/repository
./mvnw clean install
```

### Issue: Compilation errors after upgrade

```bash
# Clean everything
./mvnw clean

# Remove IDE-specific files
rm -rf .idea/
rm -rf target/

# Rebuild
./mvnw clean compile
```

### Issue: Tests failing

```bash
# Run tests with detailed output
./mvnw test -X

# Run specific test
./mvnw test -Dtest=ProductServiceImplTest

# Skip tests temporarily
./mvnw clean package -DskipTests
```

### Issue: Flyway migration errors

```bash
# Check migration status
./mvnw flyway:info

# Repair metadata table
./mvnw flyway:repair

# Baseline existing database
./mvnw flyway:baseline -Dflyway.baselineVersion=1
```

### Issue: Port 8080 already in use

```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or run on different port
SERVER_PORT=8081 ./mvnw spring-boot:run
```

## Performance Optimization

### Build Performance

```bash
# Parallel builds
./mvnw -T 4 clean package

# Skip non-essential plugins
./mvnw clean package -DskipTests -Dcheckstyle.skip

# Use Maven daemon
mvnd clean package
```

### Application Performance

```bash
# Increase heap size
JAVA_OPTS="-Xmx1024m -Xms512m" java -jar target/obo-stadium-0.0.1-SNAPSHOT.jar

# Enable JMX monitoring
java -Dcom.sun.management.jmxremote \
  -Dcom.sun.management.jmxremote.port=9010 \
  -jar target/obo-stadium-0.0.1-SNAPSHOT.jar
```

## Build Artifacts

After a successful build, you'll find:

- `target/obo-stadium-0.0.1-SNAPSHOT.jar` - Executable JAR
- `target/classes/` - Compiled classes
- `target/test-classes/` - Compiled test classes
- `target/maven-status/` - Build metadata

## Next Steps

After successful build:

1. Review `SECURITY_IMPROVEMENTS.md` for security enhancements
2. Follow `MIGRATION_GUIDE.md` for deployment
3. Read `CLAUDE.md` for project architecture
4. Set up monitoring and logging
5. Configure backups

---

**Last Updated:** 2025-01-15
**Build Tool:** Maven 3.8+
**Java Version:** 11+
**Spring Boot Version:** 2.7.18
