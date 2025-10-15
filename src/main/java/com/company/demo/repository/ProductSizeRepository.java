package com.company.demo.repository;

import com.company.demo.entity.ProductSize;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.LockModeType;
import java.util.List;

@Repository
public interface ProductSizeRepository extends JpaRepository<ProductSize, Long> {
    @Query(nativeQuery = true, value = "SELECT size FROM product_size WHERE product_id = ?1 AND quantity > 0")
    public List<Integer> findAllSizeOfProduct(String id);

    // Use pessimistic write lock to prevent race conditions
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT ps FROM ProductSize ps WHERE ps.product.id = ?1 AND ps.size = ?2 AND ps.quantity > 0")
    public ProductSize checkProductSizeAvailableWithLock(String productId, int size);

    @Query(nativeQuery = true, value = "SELECT * FROM product_size WHERE product_id = ?1 AND size = ?2 AND quantity > 0")
    public ProductSize checkProductSizeAvailable(String productId, int size);

    @Transactional
    @Modifying
    @Query(nativeQuery = true, value = "Delete from product_size where product_id = ?1")
    public void deleteByProductId(String id);

    public List<ProductSize> findByProductId(String id);

    // Use atomic decrement with check to prevent overselling
    @Transactional
    @Modifying
    @Query(nativeQuery = true, value = "UPDATE product_size SET quantity = quantity - 1 WHERE product_id = ?1 AND size = ?2 AND quantity > 0")
    public int minusOneProductBySize(String id, int size);

    @Transactional
    @Modifying
    @Query(nativeQuery = true, value = "Update product_size set quantity = quantity + 1 where product_id = ?1 and size = ?2")
    public void plusOneProductBySize(String id, int size);

    // Check stock with SELECT FOR UPDATE to prevent race conditions
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT ps FROM ProductSize ps WHERE ps.product.id = ?1 AND ps.size = ?2")
    public ProductSize findByProductIdAndSizeForUpdate(String productId, int size);
}
