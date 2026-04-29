-- ============================================================
-- Index Stratejisi
-- ============================================================

-- 1. orders.customer_id — FK lookup (Q1)
CREATE INDEX idx_orders_customer_id
    ON ecommerce.orders(customer_id);

-- 2. orders.purchase_timestamp — tarih aralığı sorguları (Q2)
CREATE INDEX idx_orders_purchase_timestamp
    ON ecommerce.orders(purchase_timestamp);

-- 3. orders.status + purchase_timestamp — partial: sadece teslim edilmemiş (Q4)
--    Tüm siparişlerin %97'si 'delivered', bu partial index çok küçük kalır
CREATE INDEX idx_orders_undelivered
    ON ecommerce.orders(purchase_timestamp DESC)
    WHERE status != 'delivered';

-- 4. order_items.product_id — join performansı (Q3)
CREATE INDEX idx_order_items_product_id
    ON ecommerce.order_items(product_id);

-- 5. order_items.seller_id — seller raporu join (Q5)
CREATE INDEX idx_order_items_seller_id
    ON ecommerce.order_items(seller_id);

-- 6. order_items.order_id — orders->items lookup
CREATE INDEX idx_order_items_order_id
    ON ecommerce.order_items(order_id);

-- 7. order_reviews.order_id — review lookup
CREATE INDEX idx_order_reviews_order_id
    ON ecommerce.order_reviews(order_id);

-- 8. order_payments.order_id — payment lookup
CREATE INDEX idx_order_payments_order_id
    ON ecommerce.order_payments(order_id);

-- 9. products.category_name — join ile kategori filtresi
CREATE INDEX idx_products_category_name
    ON ecommerce.products(category_name);

-- 10. customers.customer_unique_id — unique müşteri aramaları
CREATE INDEX idx_customers_unique_id
    ON ecommerce.customers(customer_unique_id);

-- 11. geolocation.zip_code_prefix — konum sorguları
CREATE INDEX idx_geolocation_zip
    ON ecommerce.geolocation(zip_code_prefix);
