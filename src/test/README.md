# Test Documentation

This directory contains all test code for the OBO Stadium application, organized by test type.

## Test Structure

```
src/test/java/com/company/demo/
├── unit/                    # Unit tests (isolated component testing)
│   └── service/            # Service layer unit tests
├── integration/            # Integration tests (multiple components)
│   ├── controller/         # Controller integration tests
│   └── repository/         # Repository integration tests
├── e2e/                    # End-to-end tests (full application flows)
└── DemoApplicationTests.java  # Spring Boot application context test
```

## Test Types

### Unit Tests (`unit/`)

**Purpose**: Test individual components in isolation with mocked dependencies

**Characteristics**:
- Fast execution (milliseconds)
- No external dependencies (database, network, etc.)
- Use Mockito for mocking
- Test business logic and edge cases

**Example**: [`ProductServiceTest.java`](java/com/company/demo/unit/service/ProductServiceTest.java)
```java
@ExtendWith(MockitoExtension.class)
class ProductServiceTest {
    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    @Test
    void testCreateProduct_Success() {
        // Test with mocked repository
    }
}
```

**When to use**:
- Testing service layer business logic
- Testing validation logic
- Testing error handling
- Testing calculations and transformations

---

### Integration Tests (`integration/`)

**Purpose**: Test multiple components working together

**Characteristics**:
- Slower than unit tests (seconds)
- Use real database (H2 in-memory for tests)
- Test actual SQL queries and transactions
- Verify component interactions

**Example**: [`ProductRepositoryIntegrationTest.java`](java/com/company/demo/integration/repository/ProductRepositoryIntegrationTest.java)
```java
@DataJpaTest
@ActiveProfiles("test")
class ProductRepositoryIntegrationTest {
    @Autowired
    private ProductRepository productRepository;

    @Test
    void testFindById_ExistingProduct_ReturnsProduct() {
        // Test with real database operations
    }
}
```

**When to use**:
- Testing repository queries
- Testing controller endpoints with MockMvc
- Testing database transactions
- Testing Spring Security configurations

---

### End-to-End Tests (`e2e/`)

**Purpose**: Test complete user workflows from start to finish

**Characteristics**:
- Slowest tests (seconds to minutes)
- Use full application context
- Test real user scenarios
- Can use Selenium for browser automation

**Example**: [`ShopE2ETest.java`](java/com/company/demo/e2e/ShopE2ETest.java)
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class ShopE2ETest {
    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void testCompleteShoppingFlow_BrowseToCheckout() {
        // Test full user journey
    }
}
```

**When to use**:
- Testing complete user workflows
- Testing authentication flows
- Testing multi-step processes (cart → checkout → payment)
- Testing UI with Selenium (optional)

---

## Running Tests

### Run All Tests

```bash
./mvnw test
```

### Run Specific Test Type

```bash
# Unit tests only
./mvnw test -Dtest="**/unit/**/*Test"

# Integration tests only
./mvnw test -Dtest="**/integration/**/*Test"

# E2E tests only
./mvnw test -Dtest="**/e2e/**/*Test"
```

### Run Specific Test Class

```bash
./mvnw test -Dtest=ProductServiceTest
```

### Run Specific Test Method

```bash
./mvnw test -Dtest=ProductServiceTest#testCreateProduct_Success
```

### Run Tests with Coverage

```bash
./mvnw test jacoco:report
# Report available at: target/site/jacoco/index.html
```

---

## Test Configuration

### Test Profile (`application-test.properties`)

Located at: `src/test/resources/application-test.properties`

```properties
# Use H2 in-memory database for tests
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# Disable Flyway for tests (use Hibernate auto-create)
spring.flyway.enabled=false
spring.jpa.hibernate.ddl-auto=create-drop

# Fast startup for tests
spring.jpa.show-sql=false
logging.level.root=WARN
logging.level.com.company.demo=INFO
```

### Test Dependencies (`pom.xml`)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>test</scope>
</dependency>
```

---

## Best Practices

### 1. Test Naming Convention

Use descriptive names following the pattern:
```
testMethodName_Condition_ExpectedResult()
```

Examples:
- `testCreateProduct_Success()`
- `testGetProductById_NotFound_ThrowsException()`
- `testDeleteProduct_WithExistingOrders_ThrowsException()`

### 2. Test Structure (AAA Pattern)

```java
@Test
void testMethodName() {
    // Arrange (Given)
    Product product = new Product();
    product.setName("Test Product");

    // Act (When)
    String result = productService.createProduct(product);

    // Assert (Then)
    assertNotNull(result);
    assertEquals(6, result.length());
}
```

### 3. Use Appropriate Assertions

```java
// JUnit 5
import static org.junit.jupiter.api.Assertions.*;

// AssertJ (more readable)
import static org.assertj.core.api.Assertions.*;
assertThat(result).isNotNull();
assertThat(result).hasSize(3);
assertThat(result).contains("expected");
```

### 4. Test Data Management

**For Unit Tests**: Create mock data in `@BeforeEach`
```java
@BeforeEach
void setUp() {
    testProduct = new Product();
    testProduct.setId("TEST01");
    testProduct.setName("Test Product");
}
```

**For Integration Tests**: Use `@Transactional` to rollback after each test
```java
@Test
@Transactional
void testWithDatabaseRollback() {
    // Changes are rolled back after test
}
```

### 5. Mock vs Real Dependencies

**Mock** when:
- Testing business logic in isolation
- External dependency is slow (API calls, file I/O)
- Testing error scenarios that are hard to trigger

**Use Real** when:
- Testing database queries
- Testing Spring configuration
- Testing component integration

### 6. Test Coverage Goals

- **Unit Tests**: Aim for 80%+ coverage of service layer
- **Integration Tests**: Cover critical user flows
- **E2E Tests**: Cover 3-5 main user journeys

---

## Common Test Annotations

### JUnit 5

| Annotation | Purpose |
|------------|---------|
| `@Test` | Marks a test method |
| `@BeforeEach` | Runs before each test method |
| `@AfterEach` | Runs after each test method |
| `@BeforeAll` | Runs once before all tests (static method) |
| `@AfterAll` | Runs once after all tests (static method) |
| `@Disabled` | Disables a test |
| `@DisplayName` | Custom test name for reports |

### Spring Test

| Annotation | Purpose |
|------------|---------|
| `@SpringBootTest` | Loads full application context |
| `@WebMvcTest` | Tests only MVC layer (controllers) |
| `@DataJpaTest` | Tests only JPA repositories |
| `@AutoConfigureMockMvc` | Auto-configure MockMvc |
| `@ActiveProfiles("test")` | Activate test profile |
| `@Transactional` | Rollback after each test |

### Mockito

| Annotation | Purpose |
|------------|---------|
| `@Mock` | Create mock object |
| `@InjectMocks` | Inject mocks into tested object |
| `@Spy` | Partial mock (real object with some mocked methods) |
| `@Captor` | Capture method arguments |
| `@ExtendWith(MockitoExtension.class)` | Enable Mockito in JUnit 5 |

---

## Example Test Scenarios

### Testing REST Endpoints

```java
@WebMvcTest(ProductController.class)
class ProductControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductService productService;

    @Test
    void testGetProduct() throws Exception {
        mockMvc.perform(get("/api/products/TEST01"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("Test Product"));
    }
}
```

### Testing Exceptions

```java
@Test
void testGetProductById_NotFound_ThrowsException() {
    // Given
    when(productRepository.findById("INVALID"))
        .thenReturn(Optional.empty());

    // When & Then
    assertThrows(NotFoundException.class, () -> {
        productService.getProductById("INVALID");
    });
}
```

### Testing Database Queries

```java
@Test
void testFindProductsByPriceRange() {
    // Given
    Product cheap = createProduct("P1", 1000L);
    Product expensive = createProduct("P2", 5000L);
    productRepository.saveAll(List.of(cheap, expensive));

    // When
    List<Product> results = productRepository
        .findByPriceBetween(900L, 2000L);

    // Then
    assertThat(results).hasSize(1);
    assertThat(results.get(0).getId()).isEqualTo("P1");
}
```

---

## Troubleshooting

### Tests Fail Locally But Pass in CI

**Causes**:
- Database state differences
- Time zone differences
- Environment variables

**Solutions**:
- Use `@Transactional` for test isolation
- Use `@DirtiesContext` to reload context
- Set explicit time zones in tests

### Tests Are Slow

**Solutions**:
- Use `@DataJpaTest` instead of `@SpringBootTest` when possible
- Mock external dependencies
- Use `@WebMvcTest` for controller tests
- Disable unnecessary auto-configuration

### H2 SQL Compatibility Issues

**Problem**: Query works in MySQL but fails in H2 tests

**Solutions**:
- Use H2 MySQL compatibility mode:
  ```properties
  spring.datasource.url=jdbc:h2:mem:testdb;MODE=MySQL
  ```
- Write database-agnostic queries
- Use native queries only when necessary

---

## CI/CD Integration

Tests are automatically run in the Jenkins pipeline:

```groovy
stage('Run Tests') {
    steps {
        sh './mvnw test'
    }
    post {
        always {
            junit '**/target/surefire-reports/*.xml'
        }
    }
}
```

Test reports are published and available in Jenkins UI.

---

## Resources

- [JUnit 5 Documentation](https://junit.org/junit5/docs/current/user-guide/)
- [Spring Boot Testing](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing)
- [Mockito Documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html)
- [AssertJ Documentation](https://assertj.github.io/doc/)

---

**Last Updated**: 2025-01-16
**Test Coverage**: Run `./mvnw test jacoco:report` to generate coverage report
