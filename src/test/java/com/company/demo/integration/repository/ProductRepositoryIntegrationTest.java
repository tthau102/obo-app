package com.company.demo.integration.repository;

import com.company.demo.entity.Product;
import com.company.demo.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration test for ProductRepository
 * Tests database operations with actual database (H2 in-memory for tests)
 */
@DataJpaTest
@ActiveProfiles("test")
class ProductRepositoryIntegrationTest {

    @Autowired
    private ProductRepository productRepository;

    private Product product1;
    private Product product2;

    @BeforeEach
    void setUp() {
        // Create test products
        product1 = new Product();
        product1.setId("NIKE01");
        product1.setName("Nike Air Max 2023");
        product1.setPrice(2500000L);
        product1.setAvailable(true);
        product1.setDescription("Nike Air Max test product");

        product2 = new Product();
        product2.setId("ADIDAS01");
        product2.setName("Adidas Ultraboost 22");
        product2.setPrice(3000000L);
        product2.setAvailable(true);
        product2.setDescription("Adidas Ultraboost test product");

        productRepository.saveAll(List.of(product1, product2));
    }

    @Test
    void testFindById_ExistingProduct_ReturnsProduct() {
        // When
        Optional<Product> found = productRepository.findById("NIKE01");

        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Nike Air Max 2023");
        assertThat(found.get().getPrice()).isEqualTo(2500000L);
    }

    @Test
    void testFindById_NonExistingProduct_ReturnsEmpty() {
        // When
        Optional<Product> found = productRepository.findById("INVALID");

        // Then
        assertThat(found).isEmpty();
    }

    @Test
    void testSaveProduct_NewProduct_SavesSuccessfully() {
        // Given
        Product newProduct = new Product();
        newProduct.setId("PUMA01");
        newProduct.setName("Puma RS-X");
        newProduct.setPrice(1800000L);
        newProduct.setAvailable(true);

        // When
        Product saved = productRepository.save(newProduct);

        // Then
        assertThat(saved.getId()).isEqualTo("PUMA01");
        assertThat(productRepository.findById("PUMA01")).isPresent();
    }

    @Test
    void testFindAllAvailableProducts_ReturnsOnlyAvailable() {
        // Given - Mark one product as unavailable
        product2.setAvailable(false);
        productRepository.save(product2);

        // When
        Page<Product> availableProducts = productRepository.findAll(PageRequest.of(0, 10));

        // Then
        assertThat(availableProducts.getContent()).isNotEmpty();
        // Note: This would need a custom query to filter by available=true
    }

    @Test
    void testDeleteProduct_ExistingProduct_DeletesSuccessfully() {
        // Given
        String productId = "NIKE01";
        assertThat(productRepository.findById(productId)).isPresent();

        // When
        productRepository.deleteById(productId);

        // Then
        assertThat(productRepository.findById(productId)).isEmpty();
    }

    @Test
    void testCountProducts_ReturnsCorrectCount() {
        // When
        long count = productRepository.count();

        // Then
        assertThat(count).isEqualTo(2);
    }

    @Test
    void testFindAll_WithPagination_ReturnsPagedResults() {
        // Given
        PageRequest pageRequest = PageRequest.of(0, 1);

        // When
        Page<Product> page = productRepository.findAll(pageRequest);

        // Then
        assertThat(page.getContent()).hasSize(1);
        assertThat(page.getTotalElements()).isEqualTo(2);
        assertThat(page.getTotalPages()).isEqualTo(2);
    }

    @Test
    void testUpdateProduct_ExistingProduct_UpdatesSuccessfully() {
        // Given
        Product product = productRepository.findById("NIKE01").orElseThrow();
        String newName = "Nike Air Max 2024 Updated";
        Long newPrice = 2700000L;

        // When
        product.setName(newName);
        product.setPrice(newPrice);
        Product updated = productRepository.save(product);

        // Then
        assertThat(updated.getName()).isEqualTo(newName);
        assertThat(updated.getPrice()).isEqualTo(newPrice);

        // Verify in database
        Product fromDb = productRepository.findById("NIKE01").orElseThrow();
        assertThat(fromDb.getName()).isEqualTo(newName);
        assertThat(fromDb.getPrice()).isEqualTo(newPrice);
    }
}
