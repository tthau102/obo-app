# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Spring Boot e-commerce application (obo-stadium) for selling shoes/sneakers with MySQL database backend. The application is containerized with Docker and deployed to Kubernetes via Jenkins CI/CD pipeline. It uses Harbor registry for container images and supports deployment to Kubernetes clusters with NGINX ingress.

## Technology Stack

- **Framework**: Spring Boot 2.7.18 (Java 11)
- **Database**: MySQL 5.7+ with JPA/Hibernate
- **Security**: Spring Security with JWT authentication (jjwt 0.11.5)
- **Frontend**: Thymeleaf templates with AdminLTE admin panel
- **Build Tool**: Maven
- **Container**: Docker (multi-stage builds)
- **Orchestration**: Kubernetes (1.28+) with NGINX Ingress
- **CI/CD**: Jenkins pipeline with GitLab integration
- **Registry**: Harbor (private container registry)
- **Additional**: Spring Boot Actuator, Flyway migrations, Bucket4j rate limiting

## Build and Development Commands

### Local Development

```bash
# Build the application
./mvnw clean package

# Run locally (requires MySQL)
./mvnw spring-boot:run

# Run with specific profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Run tests
./mvnw test

# Run specific test class
./mvnw test -Dtest=ProductServiceTest

# Run specific test method
./mvnw test -Dtest=ProductServiceTest#testCreateProduct

# Run tests by pattern
./mvnw test -Dtest="**/unit/**/*Test"           # Unit tests only
./mvnw test -Dtest="**/integration/**/*Test"    # Integration tests only

# Run tests with coverage report
./mvnw test jacoco:report
# View report: target/site/jacoco/index.html

# Skip tests during build
./mvnw clean package -DskipTests

# Clean build artifacts
./mvnw clean
```

### Using Docker Compose (Recommended for Local Development)

```bash
# Start all services (app + MySQL)
docker-compose up

# Start only MySQL
docker-compose up -d mysql

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes (clean database)
docker-compose down -v
```

### Docker Operations

```bash
# Build Docker image
docker build -t hautt/obo-app:latest .

# Run container (requires DB connection)
docker run -p 8080:8080 \
  -e DB_HOST=mysql \
  -e DB_USERNAME=obo_user \
  -e DB_PASSWORD=obopasswd \
  -e DB_NAME=obo_db \
  hautt/obo-app:latest
```

### Kubernetes Deployment

```bash
# Deploy using kubectl (all manifests)
kubectl apply -f kubernetes/

# Deploy specific manifest
kubectl apply -f kubernetes/04-deployment.yaml

# Check deployment status
kubectl get pods -n obo-ns
kubectl logs -f deployment/obo-app -n obo-ns

# Scale deployment
kubectl scale deployment obo-app --replicas=3 -n obo-ns

# Restart deployment (for config changes)
kubectl rollout restart deployment/obo-app -n obo-ns

# Check deployment history
kubectl rollout history deployment/obo-app -n obo-ns

# Rollback deployment
kubectl rollout undo deployment/obo-app -n obo-ns
```

### Automation Scripts

The `scripts/` directory contains helpful automation scripts:

```bash
# Setup
./scripts/setup/install-dependencies.sh    # Install system dependencies
./scripts/setup/setup-env.sh               # Generate .env file with secure defaults

# Build
./scripts/build/build-local.sh             # Build application locally
./scripts/build/build-docker.sh            # Build Docker image

# Database
./scripts/database/init-db.sh              # Initialize database
./scripts/database/backup-db.sh            # Backup database

# Deployment
./scripts/deploy/deploy-k8s.sh obo-ns latest       # Deploy to Kubernetes
./scripts/deploy/rollback-k8s.sh obo-ns           # Rollback deployment

# Monitoring
./scripts/monitoring/health-check.sh               # Check application health
./scripts/monitoring/tail-logs-k8s.sh obo-ns      # Tail Kubernetes logs
```

See [scripts/scripts.md](scripts/scripts.md) for complete documentation.

## Architecture

### Application Structure

The codebase follows standard Spring Boot layered architecture:

- **Controllers**: Located in `com.company.demo.controller`
  - `admin/*` - Admin panel controllers (require ROLE_ADMIN)
  - `anonymous/*` - Public-facing controllers (shop, blog, user)
- **Services**: Business logic in `com.company.demo.service.impl`
- **Repositories**: JPA repositories in `com.company.demo.repository`
- **Entities**: JPA entities in `com.company.demo.entity`
- **Security**: JWT-based authentication in `com.company.demo.security`
  - `JwtRequestFilter` - Validates JWT tokens from cookies
  - `WebSecurityConfig` - Spring Security configuration

### Key Domain Models

- **Product**: Shoes/sneakers with multiple sizes, images, categories, and brands
- **ProductSize**: Product inventory by size (Vietnamese sizing: SIZE_VN constant)
- **Order**: Customer orders with status tracking
- **User**: Customer/admin accounts with BCrypt passwords
- **Promotion**: Discount coupons with time-based validity
- **Category**: Product categorization (many-to-many with products)
- **Brand**: Shoe brands

### Security Model

- JWT tokens stored in HTTP-only cookies (`JWT_TOKEN`)
- Public endpoints: Shop, blog, product listing
- Authenticated endpoints: `/tai-khoan`, `/api/order`, profile management
- Admin endpoints: `/admin/**`, `/api/admin/**` (require ROLE_ADMIN)
- Static resources bypass security: `/css/**`, `/adminlte/**`, etc.

### Database Configuration

Application uses profile-based configuration (`application.properties` with `spring.profiles.active=dev`):

- **Dev profile** (`application-dev.properties`): Uses environment variables with defaults
  - `DB_HOST` (default: mysql)
  - `DB_PORT` (default: 3306)
  - `DB_NAME` (default: obo)
  - `DB_USERNAME` (default: admin)
  - `DB_PASSWORD` (default: 123456)
  - `JWT_SECRET` (required for production, has dev default)
  - `JWT_DURATION` (default: 7200 seconds / 2 hours)

- **Test profile** (`application-test.properties`): Uses H2 in-memory database
- Hibernate auto-updates schema in dev (`spring.jpa.hibernate.ddl-auto=update`)
- Flyway manages migrations in production (`spring.flyway.enabled=true`)
- Hot reload enabled for Thymeleaf templates in dev mode

### Monitoring & Debugging

Spring Boot Actuator endpoints (available at `/actuator/*`):

```bash
# Health check endpoints
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/health/liveness    # Kubernetes liveness probe
curl http://localhost:8080/actuator/health/readiness   # Kubernetes readiness probe

# Application info
curl http://localhost:8080/actuator/info

# Metrics (Prometheus format)
curl http://localhost:8080/actuator/prometheus
```

**API Documentation:**
- OpenAPI/Swagger UI: `http://localhost:8080/swagger-ui.html` (uses springdoc-openapi)

### CI/CD Pipeline

Jenkins pipeline (see `Jenkinsfile`) automatically:

1. Checks out code from GitLab (`gitlab.server.thweb.click`)
2. Builds Docker image with multi-stage build
3. Pushes to Harbor registry (`harbor.server.thweb.click/harbor-obo`)
4. Tags images with `${BUILD_NUMBER}`, `${GIT_COMMIT}`, and `latest`
5. Kubernetes deployment stage available (can be enabled)

**Image Naming Convention:**
- `harbor.server.thweb.click/harbor-obo/obo-app:latest`
- `harbor.server.thweb.click/harbor-obo/obo-app:123` (build number)
- `harbor.server.thweb.click/harbor-obo/obo-app:abc1234` (git commit)

### Kubernetes Resources

The `kubernetes/` directory contains separate manifest files:

- `00-namespace.yaml`: Creates `obo-ns` namespace
- `01-configmap.yaml`: Database connection parameters (non-sensitive)
- `02-secret.yaml.example`: Template for secrets (DB_PASSWORD, JWT_SECRET)
- `03-harbor-secret.yaml.example`: Template for Harbor registry credentials
- `04-deployment.yaml`: Application deployment with health checks
- `05-service.yaml`: ClusterIP service on port 80
- `06-ingress.yaml`: NGINX ingress with TLS and security headers
- `07-hpa.yaml`: Horizontal Pod Autoscaler (2-5 replicas based on CPU)

**Important:** Never commit actual secret files. Use `.example` templates and create real secrets using `kubectl create secret`.

## Important Notes

### Application Behavior

- **Product IDs**: Auto-generated 6-character alphanumeric strings (see `ProductService`)
- **Size System**: Vietnamese shoe sizing stored in `Constant.SIZE_VN` array
- **Promotions**: Checked dynamically for public display and time-based validity
- **Image Handling**: Product images and "on-feet" images stored separately in filesystem
- **Transactions**: Product deletion checks for existing orders first (prevents orphaned references)
- **JWT Storage**: Tokens stored in HttpOnly cookies (`JWT_TOKEN` cookie name) for XSS protection
- **Rate Limiting**: 5 requests per minute on `/api/login`, `/api/register`, and `/api/admin/*` endpoints

### Security Features

- **Authentication**: JWT-based with HttpOnly cookies
- **Password Hashing**: BCrypt with strength 10
- **SQL Injection Prevention**: Parameterized queries and input validation
- **Pessimistic Locking**: Used for inventory updates to prevent race conditions
- **CSRF Protection**: Enabled by Spring Security
- **Rate Limiting**: Bucket4j with per-IP tracking

See [SECURITY.md](SECURITY.md) for complete security documentation and best practices.

## Common Development Workflows

### Adding New Product Features

When modifying product functionality:

1. Update entity in `entity/Product.java`
2. Add repository methods in `repository/ProductRepository.java` (custom queries if needed)
3. Implement service logic in `service/impl/ProductServiceImpl.java`
4. Add controller endpoints in `controller/admin/ManageProductController.java` or `controller/anonymous/ShopController.java`
5. Update DTOs/mappers in `model/dto` and `model/mapper` if needed

### Database Schema Changes

- Hibernate auto-updates schema in dev mode
- For production, review generated DDL and create migration scripts
- Test schema changes locally before deploying

### Deployment Process

1. Push code to GitLab main branch
2. Jenkins automatically builds and pushes to Harbor
3. Deploy to Kubernetes:
   ```bash
   # Option 1: Using deployment script
   ./scripts/deploy/deploy-k8s.sh obo-ns latest

   # Option 2: Manual kubectl update
   kubectl set image deployment/obo-app obo-app=harbor.server.thweb.click/harbor-obo/obo-app:123 -n obo-ns
   ```
4. Verify deployment:
   ```bash
   kubectl get pods -n obo-ns
   kubectl logs -f deployment/obo-app -n obo-ns
   ./scripts/monitoring/health-check.sh https://obo.app.thweb.click
   ```

### Troubleshooting Common Issues

**Application Won't Start:**
- Check database connectivity: `docker-compose ps mysql`
- Verify environment variables: `cat .env`
- Check logs: `tail -f logs/application.log`

**Database Connection Failed:**
- Ensure MySQL is running: `docker-compose up -d mysql`
- Test connection: `mysql -h localhost -u admin -p obo`
- Verify credentials in `.env` match database

**Kubernetes Pod CrashLoopBackOff:**
- Check pod logs: `kubectl logs obo-app-xxxxx -n obo-ns --previous`
- Verify secrets exist: `kubectl get secrets -n obo-ns`
- Check ConfigMap values: `kubectl describe configmap obo-config -n obo-ns`
- Common causes: missing secrets, wrong DB_HOST, image pull failures

**Tests Failing:**
- H2 database may have SQL compatibility issues with MySQL-specific syntax
- Run specific failing test: `./mvnw test -Dtest=ClassName#methodName`
- Check test profile configuration in `application-test.properties`

See [kubernetes/README.md](kubernetes/README.md) for detailed troubleshooting guide.

## Additional Resources

- **[README.md](README.md)**: Complete project documentation with quick start guide
- **[SECURITY.md](SECURITY.md)**: Security improvements, migration guide, and best practices
- **[kubernetes/README.md](kubernetes/README.md)**: Detailed Kubernetes deployment guide (400+ lines)
- **[scripts/scripts.md](scripts/scripts.md)**: Documentation for all automation scripts
- **Production URL**: https://obo.app.thweb.click
- **GitLab Repository**: https://gitlab.server.thweb.click/tthau/obo-app
- **Harbor Registry**: https://harbor.server.thweb.click/harbor-obo
