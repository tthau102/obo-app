-- Add additional indexes for security and performance

-- Add index for product availability and search
CREATE INDEX IF NOT EXISTS idx_product_available ON product(is_available);
CREATE INDEX IF NOT EXISTS idx_product_name ON product(name);

-- Add composite index for common queries
CREATE INDEX IF NOT EXISTS idx_product_brand_available ON product(brand_id, is_available);

-- Add index for order filtering
CREATE INDEX IF NOT EXISTS idx_orders_buyer_status ON orders(buyer_id, status);

-- Ensure UTF8MB4 collation for proper emoji and international character support
ALTER TABLE product CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE user CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE orders CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
