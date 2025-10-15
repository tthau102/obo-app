# Security Improvements Documentation

This document outlines the security improvements and bug fixes applied to the OBO Stadium e-commerce application.

## Summary of Changes

### 1. Dependency Upgrades

**Critical Updates:**
- ✅ Spring Boot: `2.2.5.RELEASE` → `2.7.18` (fixes numerous CVEs)
- ✅ JWT (jjwt): `0.9.1` → `0.11.5` (modern API with better security)
- ✅ Gson: `2.8.0` → `2.10.1` (security patches)
- ✅ Apache Commons Lang3: `3.9` → `3.14.0`
- ✅ Hibernate Types: `2.7.1` → `2.21.1`

**New Dependencies:**
- ✅ Spring Boot Actuator (health checks & metrics)
- ✅ Flyway (database migrations)
- ✅ Springdoc OpenAPI (replaces deprecated Springfox)
- ✅ Bucket4j (rate limiting)
- ✅ Spring Boot Validation (enhanced input validation)

### 2. Security Vulnerabilities Fixed

#### 2.1 Hardcoded Credentials (CRITICAL)
**Before:**
```properties
jwt.secret=supersecret
DB_PASSWORD:123456
```

**After:**
```properties
jwt.secret=${JWT_SECRET:PLEASE_CHANGE_THIS_TO_A_SECURE_RANDOM_256_BIT_KEY}
DB_PASSWORD:${DB_PASSWORD:changeme}
```

**Files Changed:**
- `application-dev.properties`
- `application-prod.properties`
- `.env.example` (created)
- `.gitignore` (created)

#### 2.2 SQL Injection Vulnerabilities (CRITICAL)
**Before:**
```java
"ORDER BY ?5 ?6" // Direct parameter injection - SQL injection risk!
```

**After:**
```java
"ORDER BY
CASE WHEN :orderBy = 'id' AND :direction = 'ASC' THEN product.id END ASC,
CASE WHEN :orderBy = 'id' AND :direction = 'DESC' THEN product.id END DESC,
..."
```

**Additional Protection:**
- Input validation in `ProductServiceImpl.validateOrderBy()`
- Whitelist-based parameter validation

**Files Changed:**
- `ProductRepository.java`
- `ProductServiceImpl.java`

#### 2.3 CSRF Protection (HIGH)
**Before:**
```java
.csrf().disable() // All CSRF protection disabled!
```

**After:**
```java
.csrf()
.ignoringAntMatchers("/api/login", "/api/register", "/api/**") // Only exempt JWT endpoints
```

**Files Changed:**
- `WebSecurityConfig.java`

#### 2.4 Weak JWT Configuration (HIGH)
**Changes:**
- JWT duration: `604800s (7 days)` → `7200s (2 hours)` default
- Added proper cookie security flags: `HttpOnly`, `Secure` (for production)
- Updated to jjwt 0.11.x with proper `SecretKey` generation
- Better error handling (no information disclosure)

**Files Changed:**
- `JwtTokenUtil.java`
- `UserController.java`
- `application-*.properties`

#### 2.5 Race Conditions in Inventory (HIGH)
**Before:**
```java
// Non-atomic check-then-act - race condition!
ProductSize ps = checkProductSizeAvailable(id, size);
if (ps != null) {
    minusOneProductBySize(id, size);
}
```

**After:**
```java
// Atomic UPDATE with check
int updated = minusOneProductBySize(id, size); // Returns affected rows
if (updated == 0) {
    throw new BadRequestException("Sản phẩm đã hết hàng");
}

// Also added pessimistic locking for read operations
@Lock(LockModeType.PESSIMISTIC_WRITE)
ProductSize checkProductSizeAvailableWithLock(...);
```

**Files Changed:**
- `ProductSizeRepository.java`
- `OrderServiceImpl.java`

#### 2.6 No Rate Limiting (MEDIUM)
**Added:**
- Rate limiting filter using Bucket4j
- 5 requests per minute for `/api/login`, `/api/register`, `/api/admin/**`
- IP-based tracking with X-Forwarded-For support

**Files Created:**
- `RateLimitingFilter.java`

**Files Changed:**
- `WebSecurityConfig.java`

### 3. Security Headers Added

```java
.headers()
.contentSecurityPolicy("default-src 'self'; script-src 'self' 'unsafe-inline';...")
.xssProtection()
.contentTypeOptions()
.frameOptions().deny()
```

### 4. Database Migrations (Flyway)

**Added:**
- `V1__Initial_schema.sql` - Baseline schema
- `V2__Add_security_indexes.sql` - Performance & security indexes

**Configuration:**
```properties
spring.jpa.hibernate.ddl-auto=validate # Changed from 'update' (unsafe)
spring.flyway.enabled=true
```

### 5. Monitoring & Health Checks

**Added:**
- Spring Boot Actuator endpoints (`/actuator/health`, `/actuator/info`)
- Kubernetes readiness/liveness probes
- Resource limits in Kubernetes manifests

**Files Changed:**
- `kubernetes/1.app.yml`
- `application-*.properties`

### 6. Information Disclosure Prevention

**Changes:**
- Removed debug logging (`System.out.println` in `JwtRequestFilter`)
- Disabled SQL logging in production
- Error details hidden in responses:
  ```properties
  server.error.include-message=never
  server.error.include-stacktrace=never
  ```

### 7. Other Improvements

- ✅ Replaced deprecated Springfox with Springdoc OpenAPI
- ✅ Added proper connection pooling configuration (HikariCP)
- ✅ Environment-based configuration (dev vs prod)
- ✅ Added `.gitignore` to prevent committing secrets
- ✅ Cookie security flags (`HttpOnly`, comments for `Secure` in production)

## Migration Guide

### For Development

1. **Update Dependencies:**
   ```bash
   ./mvnw clean install
   ```

2. **Set Environment Variables:**
   ```bash
   cp .env.example .env
   # Edit .env and set secure values
   ```

3. **Generate JWT Secret:**
   ```bash
   openssl rand -base64 32
   # Add to .env as JWT_SECRET
   ```

4. **Run Flyway Migrations:**
   ```bash
   ./mvnw flyway:migrate
   # Or set spring.flyway.baseline-on-migrate=true for existing DBs
   ```

5. **Update Database Password:**
   - Change default password in `.env`
   - Update database user password in MySQL

### For Production

1. **CRITICAL - Set Environment Variables:**
   ```bash
   export JWT_SECRET="$(openssl rand -base64 32)"
   export DATABASE_URL="jdbc:mysql://your-db:3306/obo?useSSL=true"
   export DATABASE_USERNAME="obo_user"
   export DATABASE_PASSWORD="your_secure_password"
   export SPRING_PROFILES_ACTIVE=prod
   ```

2. **Enable HTTPS & Secure Cookies:**
   - In `UserController.java`, change:
     ```java
     cookie.setSecure(true); // Enable for HTTPS
     ```

3. **Update Kubernetes Secrets:**
   ```bash
   kubectl create secret generic obo-db-secret \
     --from-literal=DB_PASSWORD='your_secure_password' \
     -n obo-ns
   ```

4. **Deploy Updated Application:**
   ```bash
   kubectl apply -f kubernetes/1.app.yml
   ```

## Testing Checklist

- [ ] Test login rate limiting (should block after 5 attempts/minute)
- [ ] Test JWT token expiration (should expire after 2 hours in dev)
- [ ] Test concurrent order creation for same product size
- [ ] Test SQL injection attempts in product search/filter
- [ ] Verify health endpoint: `curl http://localhost:8080/actuator/health`
- [ ] Verify secure cookie flags in browser DevTools
- [ ] Test Flyway migrations on clean database
- [ ] Verify CSRF protection on non-API endpoints
- [ ] Test that secrets are not visible in error messages

## Security Recommendations

### Immediate Actions Required:
1. ⚠️ **Change JWT secret** in production to a strong random key
2. ⚠️ **Change database password** to a strong password
3. ⚠️ **Enable HTTPS** and set `cookie.setSecure(true)`
4. ⚠️ **Review and update** all default credentials

### Future Enhancements:
1. Implement refresh tokens for JWT
2. Add comprehensive input validation with `@Valid` annotations
3. Implement audit logging for security events
4. Add account lockout after failed login attempts
5. Implement TOTP/2FA for admin accounts
6. Add automated security scanning in CI/CD pipeline
7. Implement proper session management
8. Add Web Application Firewall (WAF) rules

## Breaking Changes

1. **JWT Token Duration**: Existing tokens will expire after 2 hours instead of 7 days
2. **Database Schema**: Flyway baseline required for existing databases
3. **API Endpoints**: Rate limiting may affect high-frequency API clients
4. **Configuration**: Environment variables now required for secrets

## Support

For questions or issues related to these security improvements:
1. Check `CLAUDE.md` for project architecture details
2. Review this document for migration steps
3. Contact the development team

---

**Last Updated:** 2025-01-15
**Version:** 1.0.0
**Security Audit Date:** 2025-01-15
