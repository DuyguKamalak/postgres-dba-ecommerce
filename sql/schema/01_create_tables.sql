-- ============================================================
-- Schema: ecommerce
-- Tables: customers, sellers, products, orders, order_items,
--         order_payments, order_reviews, geolocation
-- ============================================================

CREATE SCHEMA IF NOT EXISTS ecommerce;

-- Customers
CREATE TABLE ecommerce.customers (
    customer_id         CHAR(32)     PRIMARY KEY,
    customer_unique_id  CHAR(32)     NOT NULL,
    zip_code_prefix     VARCHAR(10),
    city                VARCHAR(100),
    state               CHAR(2)
);

-- Sellers
CREATE TABLE ecommerce.sellers (
    seller_id           CHAR(32)     PRIMARY KEY,
    zip_code_prefix     VARCHAR(10),
    city                VARCHAR(100),
    state               CHAR(2)
);

-- Product categories (translation)
CREATE TABLE ecommerce.product_categories (
    category_name           VARCHAR(100) PRIMARY KEY,
    category_name_english   VARCHAR(100)
);

-- Products
CREATE TABLE ecommerce.products (
    product_id                  CHAR(32)     PRIMARY KEY,
    category_name               VARCHAR(100) REFERENCES ecommerce.product_categories(category_name),
    name_length                 INT,
    description_length          INT,
    photos_qty                  INT,
    weight_g                    NUMERIC(10,2),
    length_cm                   NUMERIC(8,2),
    height_cm                   NUMERIC(8,2),
    width_cm                    NUMERIC(8,2)
);

-- Orders
CREATE TABLE ecommerce.orders (
    order_id                    CHAR(32)     PRIMARY KEY,
    customer_id                 CHAR(32)     NOT NULL REFERENCES ecommerce.customers(customer_id),
    status                      VARCHAR(20)  NOT NULL,
    purchase_timestamp          TIMESTAMP,
    approved_at                 TIMESTAMP,
    delivered_carrier_date      TIMESTAMP,
    delivered_customer_date     TIMESTAMP,
    estimated_delivery_date     TIMESTAMP
);

-- Order items
CREATE TABLE ecommerce.order_items (
    order_id                CHAR(32)     NOT NULL REFERENCES ecommerce.orders(order_id),
    order_item_id           INT          NOT NULL,
    product_id              CHAR(32)     NOT NULL REFERENCES ecommerce.products(product_id),
    seller_id               CHAR(32)     NOT NULL REFERENCES ecommerce.sellers(seller_id),
    shipping_limit_date     TIMESTAMP,
    price                   NUMERIC(10,2) NOT NULL,
    freight_value           NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- Order payments
CREATE TABLE ecommerce.order_payments (
    order_id                CHAR(32)     NOT NULL REFERENCES ecommerce.orders(order_id),
    payment_sequential      INT          NOT NULL,
    payment_type            VARCHAR(30),
    payment_installments    INT,
    payment_value           NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- Order reviews
CREATE TABLE ecommerce.order_reviews (
    review_id               CHAR(32)     PRIMARY KEY,
    order_id                CHAR(32)     NOT NULL REFERENCES ecommerce.orders(order_id),
    score                   SMALLINT     CHECK (score BETWEEN 1 AND 5),
    comment_title           TEXT,
    comment_message         TEXT,
    creation_date           TIMESTAMP,
    answer_timestamp        TIMESTAMP
);

-- Geolocation (no FK — zip codes are not unique per row)
CREATE TABLE ecommerce.geolocation (
    zip_code_prefix     VARCHAR(10),
    latitude            NUMERIC(10,6),
    longitude           NUMERIC(10,6),
    city                VARCHAR(100),
    state               CHAR(2)
);
