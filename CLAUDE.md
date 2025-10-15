# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Spring Boot e-commerce application (obo-stadium) for selling shoes/sneakers with MySQL database backend. The application is containerized with Docker and deployed to Kubernetes via Jenkins CI/CD pipeline. It uses Harbor registry for container images and supports deployment to Kubernetes clusters with NGINX ingress.

## Technology Stack

- **Framework**: Spring Boot 2.2.5 (Java 11)
- **Database**: MySQL 5.7+ with JPA/Hibernate
- **Security**: Spring Security with JWT authentication
- **Frontend**: Thymeleaf templates with AdminLTE admin panel
- **Build Tool**: Maven
- **Container**: Docker (multi-stage builds)
- **Orchestration**: Kubernetes with Helm charts
- **CI/CD**: Jenkins pipeline with GitLab integration

## Build and Development Commands

### Local Development

```bash
# Build the application
./mvnw clean package

# Run locally (requires MySQL)
./mvnw spring-boot:run

# Run tests
./mvnw test

# Skip tests during build
./mvnw clean package -DskipTests
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
# Deploy using kubectl
kubectl apply -f kubernetes/1.app.yml

# Deploy with Helm
helm upgrade --install obo-app ./helm-chart --set image.tag=latest

# Check deployment status
kubectl get pods -n obo-ns
kubectl logs -f deployment/obo-app -n obo-ns
```

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
  - JWT secret: `supersecret` (change in production)

- Hibernate auto-updates schema (`spring.jpa.hibernate.ddl-auto=update`)
- Hot reload enabled for Thymeleaf templates in dev mode

### CI/CD Pipeline

Jenkins pipeline (see `Jenkinsfile`) automatically:

1. Checks out code from GitLab (`gitlab.server.thweb.click`)
2. Builds Docker image with multi-stage build
3. Pushes to Harbor registry (`harbor.server.thweb.click/harbor-obo`)
4. Tags images with build number and `latest`
5. Kubernetes deployment stage is commented out (manual deployment)

### Kubernetes Resources

The `kubernetes/1.app.yml` manifest includes:

- Namespace: `obo-ns`
- ConfigMap: Database connection parameters
- Secret: Database password
- External MySQL service: Points to external DB at `10.25.0.109`
- Deployment: Single replica with environment variable injection
- Service: ClusterIP on port 80
- Ingress: NGINX ingress with TLS (`obo.app.thweb.click`)

## Important Notes

- **Product IDs**: Auto-generated 6-character alphanumeric strings
- **Size System**: Vietnamese shoe sizing stored in `Constant.SIZE_VN`
- **Promotions**: Checked dynamically for public display and pricing
- **Image Handling**: Product images and "on-feet" images stored separately
- **Transactions**: Product deletion checks for existing orders first
- **Swagger UI**: Available for API documentation (springfox-swagger2)

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
3. Manually update Kubernetes deployment or use Helm upgrade with new image tag
4. Verify deployment: `kubectl get pods -n obo-ns && kubectl logs -f deployment/obo-app -n obo-ns`
