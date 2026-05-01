-- Materialized Views — Raporlama Sorgularını Hızlandırma
-- Teknikler: CREATE MATERIALIZED VIEW, REFRESH CONCURRENTLY, unique index

SET search_path TO ecommerce;

-- ============================================================
-- 1. Aylık Satış Özeti
--    REFRESH CONCURRENTLY için unique index zorunludur.
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_sales AS
SELECT
    date_trunc('month', o.purchase_timestamp)   AS month,
    COUNT(DISTINCT o.order_id)                  AS order_count,
    COUNT(DISTINCT o.customer_id)               AS unique_customers,
    ROUND(SUM(oi.price), 2)                     AS product_revenue,
    ROUND(SUM(oi.freight_value), 2)             AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2)  AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value), 2)  AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.purchase_timestamp IS NOT NULL
GROUP BY 1
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_mv_monthly_sales_month
    ON mv_monthly_sales (month);


-- ============================================================
-- 2. Kategori Bazlı Gelir Raporu
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_category_revenue AS
SELECT
    COALESCE(pc.category_name_english, p.category_name)    AS category,
    COUNT(DISTINCT oi.order_id)                             AS order_count,
    COUNT(DISTINCT oi.product_id)                           AS unique_products,
    COUNT(DISTINCT oi.seller_id)                            AS unique_sellers,
    ROUND(SUM(oi.price), 2)                                 AS total_revenue,
    ROUND(AVG(oi.price), 2)                                 AS avg_product_price,
    ROUND(
        100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2
    )                                                       AS revenue_share_pct
FROM order_items oi
JOIN products p           ON oi.product_id = p.product_id
LEFT JOIN product_categories pc ON p.category_name = pc.category_name
GROUP BY pc.category_name_english, p.category_name
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_mv_category_revenue_cat
    ON mv_category_revenue (category);


-- ============================================================
-- 3. Satıcı Performans Özeti
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_seller_performance AS
SELECT
    s.seller_id,
    s.state                                         AS seller_state,
    COUNT(DISTINCT oi.order_id)                     AS total_orders,
    COUNT(DISTINCT oi.product_id)                   AS unique_products,
    ROUND(SUM(oi.price), 2)                         AS total_revenue,
    ROUND(AVG(oi.price), 2)                         AS avg_price,
    ROUND(AVG(r.score), 2)                          AS avg_review_score,
    COUNT(r.review_id)                              AS review_count
FROM sellers s
JOIN order_items oi  ON s.seller_id = oi.seller_id
LEFT JOIN order_reviews r ON oi.order_id = r.order_id
GROUP BY s.seller_id, s.state
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_mv_seller_performance_id
    ON mv_seller_performance (seller_id);


-- ============================================================
-- Sonuçları Sorgula
-- ============================================================
SELECT * FROM mv_monthly_sales   ORDER BY month        LIMIT 5;
SELECT * FROM mv_category_revenue ORDER BY total_revenue DESC LIMIT 5;
SELECT * FROM mv_seller_performance ORDER BY total_revenue DESC LIMIT 5;


-- ============================================================
-- Yenileme (production'da scheduled job ile çalıştırılır)
-- CONCURRENTLY → tablo kilitlenmeden yeniler
-- ============================================================
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_sales;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_category_revenue;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_seller_performance;
