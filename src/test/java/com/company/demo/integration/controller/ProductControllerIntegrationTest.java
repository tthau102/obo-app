package com.company.demo.integration.controller;

import com.company.demo.entity.Product;
import com.company.demo.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration test for Product-related endpoints
 * Tests the full stack from controller to database
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class ProductControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ProductRepository productRepository;

    private Product testProduct;

    @BeforeEach
    void setUp() {
        // Create test product
        testProduct = new Product();
        testProduct.setId("TEST01");
        testProduct.setName("Nike Air Jordan Test");
        testProduct.setPrice(3000000L);
        testProduct.setAvailable(true);
        testProduct.setDescription("Test product for integration testing");

        productRepository.save(testProduct);
    }

    @Test
    void testGetProductListPage_ReturnsSuccessfully() throws Exception {
        mockMvc.perform(get("/san-pham"))
                .andExpect(status().isOk())
                .andExpect(view().name("shop/list"))
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML));
    }

    @Test
    void testGetProductDetailPage_ValidProduct_ReturnsProduct() throws Exception {
        mockMvc.perform(get("/san-pham/{slug}/{id}", "nike-air-jordan-test", "TEST01"))
                .andExpect(status().isOk())
                .andExpect(view().name("shop/detail"))
                .andExpect(model().attributeExists("product"))
                .andExpect(content().string(containsString("Nike Air Jordan Test")));
    }

    @Test
    void testGetProductDetailPage_InvalidProduct_Returns404() throws Exception {
        mockMvc.perform(get("/san-pham/{slug}/{id}", "invalid", "INVALID99"))
                .andExpect(status().isNotFound());
    }

    @Test
    void testSearchProducts_ValidQuery_ReturnsResults() throws Exception {
        mockMvc.perform(get("/san-pham/search")
                        .param("keyword", "Nike"))
                .andExpect(status().isOk())
                .andExpect(view().name("shop/list"));
    }

    @Test
    void testFilterProductsByCategory_ValidCategory_ReturnsResults() throws Exception {
        mockMvc.perform(get("/san-pham")
                        .param("category", "1"))
                .andExpect(status().isOk())
                .andExpect(view().name("shop/list"));
    }

    @Test
    void testFilterProductsByPriceRange_ValidRange_ReturnsResults() throws Exception {
        mockMvc.perform(get("/san-pham")
                        .param("min", "1000000")
                        .param("max", "5000000"))
                .andExpect(status().isOk())
                .andExpect(view().name("shop/list"));
    }
}
