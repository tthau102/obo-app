diff --git a/src/test/java/com/company/demo/unit/service/ProductServiceTest.java b/src/test/java/com/company/demo/unit/service/ProductServiceTest.java
index 1e67c429344cf1ce3dd59d7e1d59cbc2b13cd1a6..21b7721fa7164037eeee0833eee2db84c911ad71 100644
--- a/src/test/java/com/company/demo/unit/service/ProductServiceTest.java
+++ b/src/test/java/com/company/demo/unit/service/ProductServiceTest.java
@@ -1,85 +1,86 @@
 package com.company.demo.unit.service;
 
 import com.company.demo.entity.Product;
 import com.company.demo.exception.BadRequestException;
 import com.company.demo.exception.NotFoundException;
 import com.company.demo.model.request.CreateProductReq;
 import com.company.demo.repository.OrderRepository;
 import com.company.demo.repository.ProductRepository;
 import com.company.demo.repository.ProductSizeRepository;
+import com.company.demo.service.PromotionService;
 import com.company.demo.service.impl.ProductServiceImpl;
 import org.junit.jupiter.api.BeforeEach;
 import org.junit.jupiter.api.Test;
 import org.junit.jupiter.api.extension.ExtendWith;
 import org.mockito.InjectMocks;
 import org.mockito.Mock;
 import org.mockito.junit.jupiter.MockitoExtension;
 
 import java.util.ArrayList;
 import java.util.Arrays;
 import java.util.Optional;
 
 import static org.junit.jupiter.api.Assertions.*;
 import static org.mockito.ArgumentMatchers.any;
 import static org.mockito.ArgumentMatchers.anyString;
 import static org.mockito.Mockito.*;
 
 @ExtendWith(MockitoExtension.class)
 class ProductServiceTest {
 
     @Mock
     private ProductRepository productRepository;
 
     @Mock
     private ProductSizeRepository productSizeRepository;
 
     @Mock
     private OrderRepository orderRepository;
 
     @Mock
     private PromotionService promotionService;
 
     @InjectMocks
     private ProductServiceImpl productService;
 
     private Product testProduct;
     private CreateProductReq createProductReq;
 
     @BeforeEach
     void setUp() {
         testProduct = new Product();
         testProduct.setId("ABC123");
         testProduct.setName("Nike Air Max");
-        testProduct.setPrice(2000000L);
+        testProduct.setPrice(2_000_000L);
         testProduct.setAvailable(true);
 
         createProductReq = new CreateProductReq();
         createProductReq.setName("Nike Air Max");
-        createProductReq.setPrice(2000000L);
-        createProductReq.setCategoryIds(Arrays.asList(1, 2));
-        createProductReq.setProductImages(Arrays.asList("image1.jpg", "image2.jpg"));
+        createProductReq.setPrice(2_000_000);
+        createProductReq.setCategoryIds(new ArrayList<>(Arrays.asList(1, 2)));
+        createProductReq.setProductImages(new ArrayList<>(Arrays.asList("image1.jpg", "image2.jpg")));
     }
 
     @Test
     void testCreateProduct_Success() {
         // Given
         when(productRepository.save(any(Product.class))).thenReturn(testProduct);
 
         // When
         String productId = productService.createProduct(createProductReq);
 
         // Then
         assertNotNull(productId);
         assertEquals(6, productId.length());
         verify(productRepository, times(1)).save(any(Product.class));
     }
 
     @Test
     void testCreateProduct_EmptyCategories_ThrowsException() {
         // Given
         createProductReq.setCategoryIds(new ArrayList<>());
 
         // When & Then
         BadRequestException exception = assertThrows(
             BadRequestException.class,
             () -> productService.createProduct(createProductReq)