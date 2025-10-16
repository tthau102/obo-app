package com.company.demo.e2e;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * End-to-End tests for the Shop workflow
 * Tests the complete user journey from browsing products to checkout
 *
 * Note: These tests require the full application context and database
 * They are disabled by default and should be run in a test environment
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Disabled("E2E tests should be run separately with proper test data")
class ShopE2ETest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    private String baseUrl;

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port;
    }

    @Test
    void testCompleteShoppingFlow_BrowseToCheckout() {
        // Step 1: Browse product list
        ResponseEntity<String> productListResponse = restTemplate.getForEntity(
                baseUrl + "/san-pham",
                String.class
        );
        assertThat(productListResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(productListResponse.getBody()).contains("Sản phẩm");

        // Step 2: View product detail
        // (Would need actual product ID from test data)
        ResponseEntity<String> productDetailResponse = restTemplate.getForEntity(
                baseUrl + "/san-pham/nike-air-max/TEST01",
                String.class
        );
        // Expect 200 or 404 depending on test data availability

        // Step 3: Add to cart (would require session management)
        // This would typically be done with Selenium or similar tool

        // Step 4: View cart
        ResponseEntity<String> cartResponse = restTemplate.getForEntity(
                baseUrl + "/gio-hang",
                String.class
        );
        assertThat(cartResponse.getStatusCode()).isEqualTo(HttpStatus.OK);

        // Step 5: Proceed to checkout
        // (Requires authentication and cart data)

        // Note: Full E2E testing of authenticated flows requires:
        // - Selenium WebDriver for browser automation
        // - Test data setup and teardown
        // - Session/cookie management for authentication
    }

    @Test
    void testHomePage_LoadsSuccessfully() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl + "/",
                String.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("OBO Stadium");
    }

    @Test
    void testProductListPage_LoadsSuccessfully() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl + "/san-pham",
                String.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void testSearchProducts_ValidKeyword_ReturnsResults() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl + "/san-pham?keyword=Nike",
                String.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void testLoginPage_LoadsSuccessfully() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl + "/dang-nhap",
                String.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("Đăng nhập");
    }

    @Test
    void testRegisterPage_LoadsSuccessfully() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl + "/dang-ky",
                String.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("Đăng ký");
    }

    @Test
    void testInvalidProductId_Returns404() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl + "/san-pham/invalid/INVALID999",
                String.class
        );

        // Then
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void testAdminPanel_WithoutAuth_RedirectsToLogin() {
        // When
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl + "/admin",
                String.class
        );

        // Then
        // Should redirect to login page (302) or return 401/403
        assertThat(response.getStatusCode()).isIn(
                HttpStatus.FOUND,
                HttpStatus.UNAUTHORIZED,
                HttpStatus.FORBIDDEN
        );
    }

    /**
     * Full E2E test example with proper test framework
     * This would typically be in a separate test suite using Selenium
     */
    @Test
    @Disabled("Requires Selenium WebDriver setup")
    void testCompleteUserJourney_WithSelenium() {
        /*
        WebDriver driver = new ChromeDriver();
        try {
            // 1. Navigate to homepage
            driver.get(baseUrl);
            assertThat(driver.getTitle()).contains("OBO Stadium");

            // 2. Search for products
            WebElement searchInput = driver.findElement(By.name("keyword"));
            searchInput.sendKeys("Nike");
            searchInput.submit();

            // 3. Click on first product
            WebElement firstProduct = driver.findElement(By.cssSelector(".product-card"));
            firstProduct.click();

            // 4. Add to cart
            WebElement addToCartBtn = driver.findElement(By.id("add-to-cart"));
            addToCartBtn.click();

            // 5. Go to cart
            driver.findElement(By.id("cart-link")).click();
            assertThat(driver.getCurrentUrl()).contains("/gio-hang");

            // 6. Login
            driver.findElement(By.id("login-link")).click();
            driver.findElement(By.name("email")).sendKeys("test@example.com");
            driver.findElement(By.name("password")).sendKeys("password");
            driver.findElement(By.id("login-submit")).click();

            // 7. Proceed to checkout
            driver.findElement(By.id("checkout-btn")).click();

            // 8. Fill shipping info and complete order
            // ... more steps

        } finally {
            driver.quit();
        }
        */
    }
}
