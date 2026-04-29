-- ============================================================
-- EXPLAIN ANALYZE — Index öncesi baseline ölçümleri
-- ============================================================

-- Q1: Belirli bir müşterinin tüm siparişlerini getir
-- (customer_id ile orders tablosunda arama — FK var ama index yok)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.order_id, o.status, o.purchase_timestamp, o.delivered_customer_date
FROM ecommerce.orders o
WHERE o.customer_id = '06b8999e2fba1a1fbc88172c00ba8bc7';

-- Q2: Belirli tarih aralığındaki siparişleri getir
-- (purchase_timestamp üzerinde sequential scan beklenir)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_id, customer_id, status, purchase_timestamp
FROM ecommerce.orders
WHERE purchase_timestamp BETWEEN '2017-11-01' AND '2017-11-30';

-- Q3: En çok satan ürünleri bul (order_items join products)
-- Büyük join, index olmadan yavaş
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.product_id, pc.category_name_english, COUNT(*) AS sales_count,
       SUM(oi.price) AS total_revenue
FROM ecommerce.order_items oi
JOIN ecommerce.products p ON p.product_id = oi.product_id
JOIN ecommerce.product_categories pc ON pc.category_name = p.category_name
GROUP BY p.product_id, pc.category_name_english
ORDER BY sales_count DESC
LIMIT 20;

-- Q4: Teslim edilmemiş siparişleri bul (partial index için iyi aday)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_id, customer_id, status, purchase_timestamp
FROM ecommerce.orders
WHERE status != 'delivered'
ORDER BY purchase_timestamp DESC;

-- Q5: Seller bazında gelir raporu
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT s.seller_id, s.city, s.state,
       COUNT(DISTINCT oi.order_id) AS total_orders,
       SUM(oi.price) AS total_revenue
FROM ecommerce.order_items oi
JOIN ecommerce.sellers s ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.city, s.state
ORDER BY total_revenue DESC
LIMIT 10;
