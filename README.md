# OBO Stadium - E-Commerce Platform

A production-ready Spring Boot e-commerce application for selling shoes/sneakers with complete CI/CD pipeline, security hardening, and Kubernetes deployment.

![Spring Boot](https://img.shields.io/badge/Spring%20Boot-2.7.18-brightgreen)
![Java](https://img.shields.io/badge/Java-11-orange)
![MySQL](https://img.shields.io/badge/MySQL-5.7+-blue)
![Docker](https://img.shields.io/badge/Docker-Ready-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28+-blue)
![Security](https://img.shields.io/badge/Security-8.5%2F10-green)

## Overview

OBO Stadium is a full-stack e-commerce web application built with Spring Boot, featuring:

- **Secure Authentication**: JWT-based authentication with rate limiting and HttpOnly cookies
- **Product Management**: Complete CRUD operations with image management and inventory tracking
- **Order Processing**: Shopping cart, checkout flow, and order management
- **Admin Panel**: AdminLTE-based dashboard for product, category, and order management
- **Production CI/CD**: Automated Jenkins pipeline with GitLab, Harbor registry, and Kubernetes deployment
- **Security Hardened**: SQL injection prevention, pessimistic locking, dependency upgrades (Security Score: 8.5/10)

## Quick Start

### Prerequisites

- Java 11+
- Docker & Docker Compose
- Maven 3.6+ (or use included `./mvnw`)

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://gitlab.server.thweb.click/tthau/obo-app.git
cd obo-app

# Install dependencies
./scripts/setup/install-dependencies.sh

# Setup environment
./scripts/setup/setup-env.sh
```

### 2. Start Database

```bash
# Start MySQL with Docker Compose
docker-compose up -d mysql

# Initialize database
./scripts/database/init-db.sh
```

### 3. Build and Run

```bash
# Build application
./scripts/build/build-local.sh

# Run application
./mvnw spring-boot:run
```

### 4. Access Application

- **Web Application**: http://localhost:8080
- **Admin Panel**: http://localhost:8080/admin (requires admin credentials)
- **Health Check**: http://localhost:8080/actuator/health

## Architecture

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Spring Boot | 2.7.18 |
| Language | Java | 11 |
| Database | MySQL | 5.7+ |
| Authentication | JWT (jjwt) | 0.11.5 |
| Template Engine | Thymeleaf | 3.0.x |
| Build Tool | Maven | 3.6+ |
| Containerization | Docker | 20.10+ |
| Orchestration | Kubernetes | 1.28+ |
| CI/CD | Jenkins | 2.x |
| Registry | Harbor | 2.x |

### Application Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Web UI    │─────>│  Controllers │─────>│  Services   │
│ (Thymeleaf) │      │   (Spring)   │      │  (Business) │
└─────────────┘      └──────────────┘      └─────────────┘
                                                    │
                                                    ▼
                                            ┌─────────────┐
                                            │ Repositories│
                                            │    (JPA)    │
                                            └─────────────┘
                                                    │
                                                    ▼
                                            ┌─────────────┐
                                            │    MySQL    │
                                            │  Database   │
                                            └─────────────┘
```

### CI/CD Pipeline

```
GitLab → Jenkins → Docker Build → Harbor Registry → Kubernetes Deployment
   ↓         ↓           ↓              ↓                ↓
 Code     Build      Package        Store           Deploy
Change    & Test    & Scan         Image           & Verify
```

**Pipeline Stages**:
1. **Checkout SCM**: Pull code from GitLab
2. **Maven Build**: Compile and package application
3. **Run Tests**: Execute unit and integration tests
4. **Build Docker Image**: Create optimized container image
5. **Push to Harbor**: Store image in private registry
6. **Deploy to K8s**: Update Kubernetes deployment
7. **Verify Deployment**: Check health and logs

See [Jenkinsfile](Jenkinsfile) for complete pipeline configuration.

## Project Structure

```
obo-app/
├── src/
│   ├── main/
│   │   ├── java/com/company/demo/
│   │   │   ├── controller/          # Controllers
│   │   │   │   ├── admin/          # Admin panel controllers
│   │   │   │   └── web/            # Public web controllers
│   │   │   ├── entity/             # JPA entities
│   │   │   ├── repository/         # Data access layer
│   │   │   ├── service/            # Business logic
│   │   │   │   └── impl/          # Service implementations
│   │   │   ├── security/           # Security configuration
│   │   │   │   ├── jwt/           # JWT utilities
│   │   │   │   └── filter/        # Security filters
│   │   │   ├── model/              # DTOs and requests
│   │   │   └── exception/          # Custom exceptions
│   │   └── resources/
│   │       ├── application.properties         # Main config
│   │       ├── application-dev.properties    # Dev config
│   │       ├── db/migration/                 # Flyway migrations
│   │       ├── static/                       # CSS, JS, images
│   │       └── templates/                    # Thymeleaf templates
│   └── test/
│       ├── java/com/company/demo/
│       │   ├── unit/              # Unit tests
│       │   ├── integration/       # Integration tests
│       │   └── e2e/               # End-to-end tests
│       └── resources/
│           └── application-test.properties   # Test config
├── kubernetes/                     # Kubernetes manifests
│   ├── 00-namespace.yaml
│   ├── 01-configmap.yaml
│   ├── 02-secret.yaml.example
│   ├── 03-harbor-secret.yaml.example
│   ├── 04-deployment.yaml
│   ├── 05-service.yaml
│   ├── 06-ingress.yaml
│   ├── 07-hpa.yaml
│   └── README.md                  # K8s deployment guide
├── scripts/                       # Automation scripts
│   ├── setup/                    # Environment setup
│   ├── build/                    # Build scripts
│   ├── deploy/                   # Deployment scripts
│   ├── database/                 # Database scripts
│   ├── monitoring/               # Monitoring scripts
│   └── scripts.md                # Scripts documentation
├── Dockerfile                     # Multi-stage Docker build
├── docker-compose.yml            # Local development setup
├── Jenkinsfile                   # CI/CD pipeline
├── pom.xml                       # Maven configuration
├── .env.example                  # Environment template
├── .gitignore                    # Git ignore rules
├── CLAUDE.md                     # Project guide for Claude AI
├── SECURITY.md                   # Security documentation
└── README.md                     # This file
```

## Key Features

### 🛍️ E-Commerce Features

- Product catalog with categories, brands, and search
- Product detail pages with multiple images
- Size-based inventory management (Vietnamese shoe sizing)
- Shopping cart with session persistence
- Checkout flow with order tracking
- Promotion/coupon system with time-based validity
- User account management and order history

### 🔐 Security Features

- JWT authentication with HttpOnly cookies
- Rate limiting (5 requests/min on auth endpoints)
- SQL injection prevention with parameterized queries
- Pessimistic locking for inventory updates
- CSRF protection
- Security headers (X-Frame-Options, CSP, etc.)
- BCrypt password hashing
- Environment-based secret management

### 👨‍💼 Admin Features

- AdminLTE dashboard interface
- Product CRUD with image upload
- Category and brand management
- Order management and status tracking
- User management
- Promotion management

### 🚀 DevOps Features

- Multi-stage Docker build (optimized image size)
- Kubernetes deployment with health checks
- Horizontal Pod Autoscaler (2-5 replicas)
- Flyway database migrations
- Spring Boot Actuator endpoints
- Automated CI/CD pipeline with Jenkins
- Harbor private registry integration

## Configuration

### Environment Variables

Create a `.env` file from the template:

```bash
cp .env.example .env
```

**Required Variables**:

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `APP_PORT` | Application port | 8080 | No |
| `SPRING_PROFILES_ACTIVE` | Spring profile | dev | No |
| `DB_HOST` | Database host | mysql | Yes |
| `DB_PORT` | Database port | 3306 | Yes |
| `DB_NAME` | Database name | obo | Yes |
| `DB_USERNAME` | Database username | admin | Yes |
| `DB_PASSWORD` | Database password | changeme | Yes |
| `JWT_SECRET` | JWT signing key (256-bit) | (auto-generated) | Yes |
| `JWT_DURATION` | JWT expiry (seconds) | 7200 | No |

**Generate Secure JWT Secret**:
```bash
openssl rand -base64 32
```

### Spring Profiles

- **dev** (`application-dev.properties`): Local development with external MySQL
- **prod** (`application-prod.properties`): Production with strict security
- **test** (`application-test.properties`): Testing with H2 in-memory database

Activate profile:
```bash
# Via environment variable
export SPRING_PROFILES_ACTIVE=dev

# Via command line
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

## Development

### Running Tests

```bash
# Run all tests
./mvnw test

# Run specific test type
./mvnw test -Dtest="**/unit/**/*Test"      # Unit tests
./mvnw test -Dtest="**/integration/**/*"   # Integration tests
./mvnw test -Dtest="**/e2e/**/*"           # E2E tests

# Run with coverage report
./mvnw test jacoco:report
# Report: target/site/jacoco/index.html
```

See [src/test/README.md](src/test/README.md) for complete testing documentation.

### Building Docker Image

```bash
# Build image locally
./scripts/build/build-docker.sh

# Build with custom tag
./scripts/build/build-docker.sh v1.0.0

# Run container
docker-compose up
```

### Database Management

```bash
# Initialize database
./scripts/database/init-db.sh

# Backup database
./scripts/database/backup-db.sh

# Run Flyway migrations manually
./mvnw flyway:migrate
```

## Deployment

### Kubernetes Deployment

Complete deployment guide: [kubernetes/README.md](kubernetes/README.md)

**Quick Deploy**:

```bash
# 1. Create secrets
kubectl create secret generic obo-secret \
  --from-literal=DB_PASSWORD='your-password' \
  --from-literal=JWT_SECRET="$(openssl rand -base64 32)" \
  --namespace=obo-ns

kubectl create secret docker-registry harbor-registry \
  --docker-server=harbor.server.thweb.click \
  --docker-username=gitlab-ci \
  --docker-password='HARBOR_TOKEN' \
  --namespace=obo-ns

# 2. Deploy application
./scripts/deploy/deploy-k8s.sh obo-ns latest

# 3. Verify deployment
kubectl get pods -n obo-ns
./scripts/monitoring/tail-logs-k8s.sh obo-ns
./scripts/monitoring/health-check.sh https://obo.app.thweb.click
```

### Rolling Back Deployment

```bash
# Rollback to previous version
./scripts/deploy/rollback-k8s.sh obo-ns

# Rollback to specific revision
./scripts/deploy/rollback-k8s.sh obo-ns 3
```

### CI/CD with Jenkins

Pipeline automatically triggers on Git push:

1. Checkout code from GitLab
2. Build with Maven and run tests
3. Build Docker image with build metadata
4. Push to Harbor registry with tags: `${BUILD_NUMBER}`, `latest`, `${GIT_COMMIT}`
5. Deploy to Kubernetes cluster
6. Verify deployment health

Manual trigger:
```bash
# Trigger Jenkins build
curl -X POST http://jenkins.server.thweb.click/job/obo-app/build \
  --user username:token
```

## Monitoring & Operations

### Health Checks

```bash
# Check application health
./scripts/monitoring/health-check.sh

# Check specific URL
./scripts/monitoring/health-check.sh https://obo.app.thweb.click
```

**Actuator Endpoints**:
- `/actuator/health` - Overall health status
- `/actuator/health/liveness` - Liveness probe
- `/actuator/health/readiness` - Readiness probe
- `/actuator/info` - Application information
- `/actuator/prometheus` - Prometheus metrics

### Viewing Logs

```bash
# Local logs
tail -f logs/application.log

# Kubernetes logs
./scripts/monitoring/tail-logs-k8s.sh obo-ns

# Specific pod
kubectl logs -f pod/obo-app-xxxxx -n obo-ns
```

### Common Operations

```bash
# Scale deployment
kubectl scale deployment obo-app --replicas=3 -n obo-ns

# Update image
kubectl set image deployment/obo-app obo-app=harbor.../obo-app:v2.0 -n obo-ns

# Restart deployment
kubectl rollout restart deployment/obo-app -n obo-ns

# Port forward for local debugging
kubectl port-forward deployment/obo-app 8080:8080 -n obo-ns
```

## Security

**Security Score**: 8.5/10

### Security Improvements

- ✅ Spring Boot upgraded from 2.2.5 → 2.7.18 (fixes 15+ CVEs)
- ✅ JWT upgraded from 0.9.1 → 0.11.5 (modern cryptography)
- ✅ Environment-based secrets (no hardcoded credentials)
- ✅ SQL injection prevention with parameterized queries
- ✅ Pessimistic locking for inventory race conditions
- ✅ Rate limiting on authentication endpoints
- ✅ Security headers in Kubernetes Ingress
- ✅ Flyway database migrations

See [SECURITY.md](SECURITY.md) for complete security documentation and migration guide.

### Security Checklist for Production

- [ ] Strong JWT secret (256-bit) configured via environment
- [ ] JWT expiration set to 1 hour or less
- [ ] Strong database password (not default)
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] Security headers configured in Ingress
- [ ] Rate limiting enabled on auth endpoints
- [ ] All secrets stored in Kubernetes Secrets (not ConfigMap)
- [ ] `.env` file not committed to Git
- [ ] Database access restricted by IP
- [ ] All dependencies up to date

## Troubleshooting

### Application Won't Start

**Check**:
```bash
# Database connectivity
./scripts/database/init-db.sh

# Environment variables
cat .env

# Application logs
tail -f logs/application.log
```

### Database Connection Failed

**Solutions**:
```bash
# Verify MySQL is running
docker-compose ps mysql

# Test connection
mysql -h localhost -u admin -p obo

# Check database credentials in .env
cat .env | grep DB_
```

### Kubernetes Pod CrashLoopBackOff

**Check**:
```bash
# Pod status
kubectl describe pod obo-app-xxxxx -n obo-ns

# Pod logs
kubectl logs obo-app-xxxxx -n obo-ns --previous

# Common issues:
# - Database connection failed (check ConfigMap DB_HOST)
# - Missing secrets (check obo-secret exists)
# - Image pull failed (check harbor-registry secret)
```

### Tests Failing

**Solutions**:
```bash
# Clean and rebuild
./mvnw clean test

# Check H2 compatibility
# H2 may have SQL differences from MySQL

# Run specific failing test
./mvnw test -Dtest=ProductServiceTest
```

See [kubernetes/README.md](kubernetes/README.md) for more troubleshooting.

## Documentation

- [CLAUDE.md](CLAUDE.md) - Project overview and architecture for Claude AI
- [SECURITY.md](SECURITY.md) - Security improvements and migration guide
- [kubernetes/README.md](kubernetes/README.md) - Kubernetes deployment guide (400+ lines)
- [scripts/scripts.md](scripts/scripts.md) - Automation scripts documentation
- [src/test/README.md](src/test/README.md) - Testing guide and best practices

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes and test: `./mvnw test`
4. Commit changes: `git commit -am 'Add my feature'`
5. Push to branch: `git push origin feature/my-feature`
6. Submit merge request on GitLab

## License

This project is licensed under the MIT License.

## Contact

**Maintainer**: Tran Trung Hau

- Email: trunghautran0102@gmail.com
- GitLab: https://gitlab.server.thweb.click/tthau/obo-app

## Acknowledgments

- Spring Boot framework and community
- AdminLTE admin template
- Harbor registry project
- Kubernetes and CNCF community

---

**Version**: 2.0
**Last Updated**: 2025-01-16
**Production URL**: https://obo.app.thweb.click
