-- Initial database schema for OBO Stadium e-commerce application
-- This is a baseline migration - adjust based on your current database schema

-- Brand table
CREATE TABLE IF NOT EXISTS brand (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT,
    thumbnail VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_brand_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Category table
CREATE TABLE IF NOT EXISTS category (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    UNIQUE KEY uk_category_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product table
CREATE TABLE IF NOT EXISTS product (
    id VARCHAR(6) PRIMARY KEY,
    name VARCHAR(300) NOT NULL,
    slug VARCHAR(300) NOT NULL,
    description TEXT,
    brand_id INT,
    price BIGINT NOT NULL,
    total_sold INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_available TINYINT(1) DEFAULT 1,
    product_images JSON,
    onfeet_images JSON,
    FOREIGN KEY (brand_id) REFERENCES brand(id),
    INDEX idx_product_brand (brand_id),
    INDEX idx_product_price (price),
    INDEX idx_product_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product-Category relationship
CREATE TABLE IF NOT EXISTS product_category (
    product_id VARCHAR(6) NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product sizes and inventory
CREATE TABLE IF NOT EXISTS product_size (
    product_id VARCHAR(6) NOT NULL,
    size INT NOT NULL,
    quantity INT DEFAULT 0,
    PRIMARY KEY (product_id, size),
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE,
    INDEX idx_product_size_quantity (quantity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- User table
CREATE TABLE IF NOT EXISTS user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(500),
    avatar VARCHAR(500),
    roles JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    receiver_name VARCHAR(255) NOT NULL,
    receiver_phone VARCHAR(20) NOT NULL,
    receiver_address VARCHAR(500) NOT NULL,
    note TEXT,
    buyer_id BIGINT NOT NULL,
    product_id VARCHAR(6) NOT NULL,
    size INT NOT NULL,
    product_price BIGINT NOT NULL,
    total_price BIGINT NOT NULL,
    status INT NOT NULL,
    promotion JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    modified_at TIMESTAMP NULL,
    modified_by BIGINT,
    FOREIGN KEY (buyer_id) REFERENCES user(id),
    FOREIGN KEY (product_id) REFERENCES product(id),
    FOREIGN KEY (created_by) REFERENCES user(id),
    FOREIGN KEY (modified_by) REFERENCES user(id),
    INDEX idx_orders_buyer (buyer_id),
    INDEX idx_orders_status (status),
    INDEX idx_orders_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Promotion table
CREATE TABLE IF NOT EXISTS promotion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    coupon_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    discount_type INT NOT NULL,
    discount_value BIGINT NOT NULL,
    maximum_discount_value BIGINT,
    is_active TINYINT(1) DEFAULT 0,
    is_public TINYINT(1) DEFAULT 0,
    expired_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_promotion_code (coupon_code),
    INDEX idx_promotion_active (is_active, is_public)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Image table
CREATE TABLE IF NOT EXISTS image (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    size BIGINT,
    type VARCHAR(50),
    link VARCHAR(500) NOT NULL,
    uploaded_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (uploaded_by) REFERENCES user(id),
    INDEX idx_image_uploaded_by (uploaded_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Finance/Revenue tracking
CREATE TABLE IF NOT EXISTS finance (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    amount BIGINT NOT NULL,
    created_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (created_by) REFERENCES user(id),
    INDEX idx_finance_order (order_id),
    INDEX idx_finance_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Blog posts
CREATE TABLE IF NOT EXISTS post (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    slug VARCHAR(500) NOT NULL,
    description TEXT,
    content LONGTEXT,
    thumbnail VARCHAR(500),
    published_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    modified_at TIMESTAMP NULL,
    modified_by BIGINT,
    FOREIGN KEY (created_by) REFERENCES user(id),
    FOREIGN KEY (modified_by) REFERENCES user(id),
    INDEX idx_post_slug (slug),
    INDEX idx_post_published (published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Configuration table
CREATE TABLE IF NOT EXISTS configuration (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    obo_choices JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
